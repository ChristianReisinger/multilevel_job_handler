#!/bin/bash

err="Usage: $0 <logfile_prefix> <conf_prefix> <beta> <T> <L> <configs> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <task_firstconf>"

if [ $# -ne 12 ]; then
	echo $err
	exit
fi

logfile_prefix="${1}"
conf_prefix="${2}"
beta="${3}"
T="${4}"
L="${5}"
configs=${6}
comp_file="${7}"
WL_Rs=${8}
NAPEs=${9}
updates=${10}
seed=${11}
task_firstconf=${12}

conf=$((${task_firstconf}+${SLURM_PROCID}))
tag="${logfile_prefix}_c${configs}_up${updates}_s${seed}"

program="/home/mesonqcd/reisinger/programs/multilevel/bin/multilevel"
"$program" -e $conf -b $beta -s $((${seed}+${conf})) -u $updates $T $L $WL_Rs $NAPEs 1,$configs $comp_file $conf_prefix 1 >& ${tag}.${conf}.log
