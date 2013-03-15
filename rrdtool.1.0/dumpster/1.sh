#!/bin/bash

#./expect_scp.sh  ./tools/tcp.sh  172.16.1.1  QPVajE8a1z
./expect_set.sh  172.16.1.1  root   QPVajE8a1z
./expect_set.sh  172.16.1.1  root   QPVajE8a1z  snmprestart 
echo  "$0====>"`date +%T`
