#!/usr/bin/python

# Copyright (c) 2015 Hewlett-Packard Development Company, L.P.
# Copyright (c) 2013, Benno Joy <benno@ansible.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
# Source https://github.com/vooon/ansible/blob/os_image_add_tags/lib/ansible/modules/cloud/openstack/os_image.py

from __future__ import absolute_import, division, print_function
__metaclass__ = type


# TODO(mordred): we need to support "location"(v1) and "locations"(v2)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
---
module: os_image
short_description: Add/Delete images from OpenStack Cloud
extends_documentation_fragment: openstack
version_added: "2.0"
author: "Monty Taylor (@emonty)"
description:
   - Add or Remove images from the OpenStack Image Repository
options:
   name:
     description:
        - The name of the image when uploading - or the name/ID of the image if deleting
     required: true
   id:
     version_added: "2.4"
     description:
        - The ID of the image when uploading an image
   checksum:
     version_added: "2.5"
     description:
        - The checksum of the image
   disk_format:
     description:
        - The format of the disk that is getting uploaded
     default: qcow2
   container_format:
     description:
        - The format of the container
     default: bare
   owner:
     description:
        - The owner of the image
   min_disk:
     description:
        - The minimum disk space (in GB) required to boot this image
   min_ram:
     description:
        - The minimum ram (in MB) required to boot this image
   is_public:
     description:
        - Whether the image can be accessed publicly. Note that publicizing an image requires admin role by default.
     type: bool
     default: 'yes'
   protected:
     version_added: "2.9"
     description:
        - Prevent image from being deleted
     type: bool
     default: 'no'
   filename:
     description:
        - The path to the file which has to be uploaded
   ramdisk:
     description:
        - The name of an existing ramdisk image that will be associated with this image
   kernel:
     description:
        - The name of an existing kernel image that will be associated with this image
   properties:
     description:
        - Additional properties to be associated with this image
     default: {}
   tags:
     version_added: "2.10"
     description:
       - Tags to be associated with this image
   state:
     description:
       - Should the resource be present or absent.
     choices: [present, absent]
     default: present
   availability_zone:
     description:
       - Ignored. Present for backwards compatibility
   volume:
     version_added: "2.10"
     description:
       - ID of a volume to create an image from.
       - The volume must be in AVAILABLE state.
requirements: ["openstacksdk"]
'''

EXAMPLES = '''
# Upload an image from a local file named cirros-0.3.0-x86_64-disk.img
- os_image:
    auth:
      auth_url: https://identity.example.com
      username: admin
      password: passme
      project_name: admin
      os_user_domain_name: Default
      os_project_domain_name: Default
    name: cirros
    container_format: bare
    disk_format: qcow2
    state: present
    filename: cirros-0.3.0-x86_64-disk.img
    kernel: cirros-vmlinuz
    ramdisk: cirros-initrd
    properties:
      cpu_arch: x86_64
      distro: ubuntu

# Create image from volume attached to an instance
- name: create volume snapshot
  os_volume_snapshot:
    auth:
      "{{ auth }}"
    display_name: myvol_snapshot
    volume: myvol
    force: yes
  register: myvol_snapshot

- name: create volume from snapshot
  os_volume:
    auth:
      "{{ auth }}"
    size: "{{ myvol_snapshot.snapshot.size }}"
    snapshot_id: "{{ myvol_snapshot.snapshot.id }}"
    display_name: myvol_snapshot_volume
    wait: yes
  register: myvol_snapshot_volume

- name: create image from volume snapshot
  os_image:
    auth:
      "{{ auth }}"
    volume: "{{ myvol_snapshot_volume.volume.id }}"
    name: myvol_image
'''

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.openstack import openstack_full_argument_spec, openstack_module_kwargs, openstack_cloud_from_module


def main():

    argument_spec = openstack_full_argument_spec(
        name=dict(required=True),
        id=dict(default=None),
        checksum=dict(default=None),
        disk_format=dict(default='qcow2', choices=['ami', 'ari', 'aki', 'vhd', 'vmdk', 'raw', 'qcow2', 'vdi', 'iso', 'vhdx', 'ploop']),
        container_format=dict(default='bare', choices=['ami', 'aki', 'ari', 'bare', 'ovf', 'ova', 'docker']),
        owner=dict(default=None),
        min_disk=dict(type='int', default=0),
        min_ram=dict(type='int', default=0),
        is_public=dict(type='bool', default=False),
        protected=dict(type='bool', default=False),
        filename=dict(default=None),
        ramdisk=dict(default=None),
        kernel=dict(default=None),
        properties=dict(type='dict', default={}),
        volume=dict(default=None),
        tags=dict(type='list', default=None),
        state=dict(default='present', choices=['absent', 'present']),
    )

    module_kwargs = openstack_module_kwargs(
        mutually_exclusive=[['filename', 'volume']],
    )
    module = AnsibleModule(argument_spec, **module_kwargs)

    sdk, cloud = openstack_cloud_from_module(module)
    try:

        changed = False
        if module.params['id']:
            image = cloud.get_image(name_or_id=module.params['id'])
        elif module.params['checksum']:
            image = cloud.get_image(name_or_id=module.params['name'], filters={'checksum': module.params['checksum']})
        else:
            image = cloud.get_image(name_or_id=module.params['name'])

        if module.params['state'] == 'present':
            if not image:
                kwargs = {}
                if module.params['id'] is not None:
                    kwargs['id'] = module.params['id']
                image = cloud.create_image(
                    name=module.params['name'],
                    filename=module.params['filename'],
                    disk_format=module.params['disk_format'],
                    container_format=module.params['container_format'],
                    wait=module.params['wait'],
                    timeout=module.params['timeout'],
                    is_public=module.params['is_public'],
                    protected=module.params['protected'],
                    min_disk=module.params['min_disk'],
                    min_ram=module.params['min_ram'],
                    volume=module.params['volume'],
                    **kwargs
                )
                changed = True
                if not module.params['wait']:
                    module.exit_json(changed=changed, image=image, id=image.id)

            cloud.update_image_properties(
                image=image,
                kernel=module.params['kernel'],
                ramdisk=module.params['ramdisk'],
                protected=module.params['protected'],
                **module.params['properties'])
            if module.params['tags'] is not None:
                # NOTE: In theory all what you need - pass `tags` to function above.
                #       Unfortunately i always got 400 Bad Request with SDK 0.33.0.
                #       cloud.image.add/remove_tags works, but raise AttributeError
                #       *after* the successful call is done.
                existing_tags = set(image.tags)
                required_tags = set(module.params['tags'])
                for tag in existing_tags.difference(required_tags):
                    changed = True
                    try:
                        cloud.image.remove_tag(image.id, tag)
                    except AttributeError:
                        pass

                for tag in required_tags.difference(existing_tags):
                    changed = True
                    try:
                        cloud.image.add_tag(image.id, tag)
                    except AttributeError:
                        pass
            image = cloud.get_image(name_or_id=image.id)
            module.exit_json(changed=changed, image=image, id=image.id)

        elif module.params['state'] == 'absent':
            if not image:
                changed = False
            else:
                cloud.delete_image(
                    name_or_id=module.params['name'],
                    wait=module.params['wait'],
                    timeout=module.params['timeout'])
                changed = True
            module.exit_json(changed=changed)

    except sdk.exceptions.OpenStackCloudException as e:
        module.fail_json(msg=str(e), extra_data=e.extra_data)


if __name__ == "__main__":
    main()