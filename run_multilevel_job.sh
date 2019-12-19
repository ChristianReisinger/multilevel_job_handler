#!/bin/bash

#SBATCH --extra-node-info=2:20:1

module load comp/gcc/8.2.0

err="Usage: $0 <logfile_prefix> <conf_prefix> <first_conf> <beta> <T> <L> <configs> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <tasks_per_step>"

if [ $# -ne 13 ]; then
	echo $err
	exit
fi

logfile_prefix="${1}"
conf_prefix="${2}"
first_conf="${3}"
beta="${4}"
T=${5}
L=${6}
configs=${7}
comp_file="${8}"
WL_Rs=${9}
NAPEs=${10}
updates=${11}
seed=${12}
tasks_per_step=${13}

taskscript="/home/mesonqcd/reisinger/programs/scripts/multilevel/compute_multilevel.sh"
step_firstconf=$((${tasks_per_step}*${SLURM_ARRAY_TASK_ID}+${first_conf}))

srun -n${tasks_per_step} "$taskscript" "$logfile_prefix" "$conf_prefix" $beta $T $L $configs "$comp_file" $WL_Rs $NAPEs $updates $seed $step_firstconf
