#!/bin/bash
FIRST=1
LAST=1
DEP_OFFSET=
PROJ=

for i in {$FIRST..$LAST}; do
	$task add proj:$PROJ dep:$(($DEP_OFFSET+$i)) Chapter $i; done
