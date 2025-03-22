#!/bin/sh

lavacli --uri http://admin:tokenforci@127.0.0.1:10080/RPC2 $*
exit $?
