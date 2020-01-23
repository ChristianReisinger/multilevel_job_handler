#!/bin/bash

err="Usage: $0 <logfile_prefix> <conf_prefix> <beta> <T> <L> <configs> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <step_firstconf> <confs_per_task> <conf_id_incr>"

if [ $# -ne 14 ]; then
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
step_firstconf=${12}
confs_per_task=${13}
conf_id_incr=${14}

task_firstconf=$((${step_firstconf}+${confs_per_task}*${SLURM_PROCID}))
task_lastconf=$(($task_firstconf+$confs_per_task-1))
tag="${logfile_prefix}_c${configs}_up${updates}_s${seed}"

program="/home/mesonqcd/reisinger/programs/multilevel/bin/multilevel"

for conf in $(seq $task_firstconf $task_lastconf); do
	conf_shifted=$(($conf+$conf_id_incr))
	"$program" -e ${conf_shifted} -b $beta -s $((${seed}+${conf})) -u $updates $T $L $WL_Rs $NAPEs 1,$configs $comp_file $conf_prefix 1 >& ${tag}.${conf_shifted}.log
done
