#!/bin/bash
#
#

for eth in `cat /proc/net/dev  |grep -v sit0 |grep -v lo  |grep -v Inter |grep -v face | awk -F: '{print $1}'`
do
    RXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXpre=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    sleep 1
    RXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $2}')
    TXnext=$(cat /proc/net/dev | grep $eth | tr : " " | awk '{print $10}')
    RX=$((${RXnext}-${RXpre}))
    TX=$((${TXnext}-${TXpre}))
    echo "${eth} in:${RX} B/s out:${TX} B/s"
done
