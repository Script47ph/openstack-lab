#!/bin/sh

alias ab='ansible-playbook deploy -t'

ab prechecks && \
ab baremetal && \
ab mariadb && \
ab rabbitmq && \
ab haproxy && \
ab pacemaker && \
ab keystone && \
ab glance && \
ab cinder && \
ab nova && \
ab neutron && \
ab horizon && \
ab heat && \
echo "Deploy has been finished."
