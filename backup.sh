#!/bin/sh

DOCKERNAME=master
BACKUP_DIR="backup-$(date +%Y%m%d_%H%M)"
# use /tmp by default on host (this is used by tar)
TMPDIR=${TMPDIR:-/tmp}
export TMPDIR

usage() {
	echo "$0 [-h|--help] [-n dockername]"
}

while [ $# -ge 1 ]
do
	case $1 in
	-h)
		usage
		exit 0
	;;
	--help)
		usage
		exit 0
	;;
	-n)
		shift
		DOCKERNAME=$1
		shift
	;;
	*)
		usage
		exit 1
	;;
	esac
done

mkdir -p $TMPDIR

mkdir $BACKUP_DIR
cp boards.yaml $BACKUP_DIR

DOCKERID=$(docker ps |grep "$DOCKERNAME" | cut -d' ' -f1)
if [ -z "$DOCKERID" ];then
	echo "ERROR: unable to find docker named $DOCKERNAME"
	exit 1
fi

docker exec $DOCKERID tar czf /root/devices.tar.gz /etc/lava-server/dispatcher-config/devices/ || exit $?
docker cp $DOCKERID:/root/devices.tar.gz $BACKUP_DIR/ || exit $?

# for an unknown reason pg_dump > file doesnt work
docker exec $DOCKERID sudo -u postgres pg_dump --create --clean lavaserver --file /tmp/db_lavaserver || exit $?
docker exec $DOCKERID gzip /tmp/db_lavaserver || exit $?
docker cp $DOCKERID:/tmp/db_lavaserver.gz $BACKUP_DIR/ || exit $?
docker exec $DOCKERID rm /tmp/db_lavaserver.gz || exit $?

# tar outputs warnings when file changes on disk while creating tar file. So do not "exit on error"
docker exec $DOCKERID tar czf /root/joboutput.tar.gz /var/lib/lava-server/default/media/job-output/ || echo "WARNING: tar operation returned $?"
docker cp $DOCKERID:/root/joboutput.tar.gz $BACKUP_DIR/ || exit $?
docker exec $DOCKERID rm /root/joboutput.tar.gz || exit $?

echo "Backup done in $BACKUP_DIR"
rm -f backup-latest
ln -sf $BACKUP_DIR backup-latest
