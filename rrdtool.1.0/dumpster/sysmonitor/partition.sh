#!/bin/bash
#
#

df -P | grep -v Filesystem |grep -v Capacity  | awk '{print $6,"=",$5}'
