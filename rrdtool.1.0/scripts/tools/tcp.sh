#!/bin/bash
netstat -an|grep tcp|awk '{a[$6]++} END {for (i in a) print i,":"a[i]}'|sed 's/ //g'
