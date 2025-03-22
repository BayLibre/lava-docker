#!/bin/sh

. output/.env

lavacli --uri http://$USER:$TOKEN@127.0.0.1:$WEBIF_PORT/RPC2 $*
exit $?
