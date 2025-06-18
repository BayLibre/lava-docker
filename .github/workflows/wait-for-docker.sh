#!/bin/sh

DOCKERNAME=master
if [ ! -z "$1" ];then
	DOCKERNAME=$1
	echo "DEBUG: master name is $DOCKERNAME"
fi

if [ -e output/.env ]; then
  . output/.env
fi

cd output/local

TIMEOUT=0

need_wait() {
	echo "========================================================"
	lavacli --uri http://admin:tokenforci@127.0.0.1:$WEBIF_PORT/RPC2 devices list > devices.list
	if [ $? -ne 0 ];then
		echo "DEBUG: lavacli devices list not0"
		return 1
	fi
	grep -q qemu devices.list
	if [ $? -ne 0 ];then
		echo "DEBUG: no qemu yet"
		cat devices.list
		return 1
	fi
	grep -i unknow devices.list
	if [ $? -eq 0 ];then
		echo "DEBUG: there is still devices without passed HC"
		return 1
	fi
	# now wait for a job
	lavacli --uri http://admin:tokenforci@127.0.0.1:$WEBIF_PORT/RPC2 jobs list > joblist
	cat joblist
	grep -q Running joblist
	if [ $? -ne 0 ];then
		return 0
		lavacli --uri http://admin:tokenforci@127.0.0.1:$WEBIF_PORT/RPC2 jobs logs --no-follow 1
	fi
	echo "DEBUG: Still running jobs"
	return 1
}

while [ $TIMEOUT -le 1200 ]
do
	need_wait
	RET=$?
	docker compose logs --tail=60
	docker ps > /tmp/alldocker
	grep -q $DOCKERNAME /tmp/alldocker
	if [ $? -ne 0 ];then
		echo "=========================================="
		echo "=========================================="
		echo "=========================================="
		echo "ERROR: master $DOCKERNAME died"
		docker ps
		docker compose logs
		exit 1
	fi
	if [ $RET -eq 0 ];then
		exit 0
	fi
	sleep 10
	TIMEOUT=$((TIMEOUT+10))
	echo "WAIT FOR DOCKER TIMEOUT=$TIMEOUT"
done
exit 1
