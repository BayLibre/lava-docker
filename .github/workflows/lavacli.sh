#!/bin/sh

. output/.env

lavacli --uri http://$USER:$TOKEN@127.0.0.1:10080/RPC2 $*
exit $?
