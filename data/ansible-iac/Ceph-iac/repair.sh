for i in {1..4};
do
	ssh -lroot 14.14.238.1${i} rm -rf /etc/ceph/;
	ssh -lroot 14.14.238.2${i} rm -rf /etc/ceph/;
done
