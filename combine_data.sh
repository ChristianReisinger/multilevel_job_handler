#!/bin/bash

if [ $# -ne 1 ]; then
	echo "Usage: $0 <filestem>"
	echo -e "\tConcat output files '<filestem>.<config>' written by multilevel with"
	echo -e "\t<line_prefix> = <WL_t> for all existing <config> and print formatted"
	echo -e "\tresult readable by jackknife_npt_WL"
	exit
fi

filestem="$1"

for f in "${filestem}".*; do
	sed -r "s/^([0-9]+ [0-9]+ )/${f##*.} \10 /" "$f"
done
