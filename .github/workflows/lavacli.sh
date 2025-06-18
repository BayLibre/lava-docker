#!/bin/sh

. output/.env

# verify all devices and jobs are ok
if [ "$1" = "health" ];then
	FTMP='/tmp/jobs'
	lavacli --uri http://$USER:$TOKEN@127.0.0.1:$WEBIF_PORT/RPC2 jobs show $2 > $FTMP
	cat $FTMP
	lavacli --uri http://$USER:$TOKEN@127.0.0.1:$WEBIF_PORT/RPC2 jobs logs $2
	grep 'state.*Finished' $FTMP || exit 1
	grep 'Health.*Complete' $FTMP || exit 1
	lavacli --uri http://$USER:$TOKEN@127.0.0.1:$WEBIF_PORT/RPC2 devices show qemu-01 > $FTMP
	cat $FTMP
	grep 'health.*Good' $FTMP || exit 1
	exit 0
fi

lavacli --uri http://$USER:$TOKEN@127.0.0.1:$WEBIF_PORT/RPC2 $*
exit $?
