#!/bin/bash
var1=$1
var2=$2
var3=$3

if [ $# -eq 3 ]; then
    echo "3 values!"
elif [ $# -eq 2 ]; then
    echo "2 values!"
elif [ $# -eq 1 ]; then
    echo "1 values!"
else
    echo "values are not in handle"
fi

if [ $? -eq 0 ]; then
    exit 0
else
    exit 1
fi