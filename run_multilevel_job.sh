#!/bin/bash

#SBATCH --extra-node-info=2:20:1

module load comp/gcc/8.2.0

err="Usage: $0 <logfile_prefix> <conf_prefix> <first_conf> <beta> <T> <L> <configs> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <tasks_per_step> <cpus_per_task> <confs_per_task> <conf_id_incr>"

if [ $# -ne 14 ]; then
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
cpus_per_task=${14}
confs_per_task=${15}
conf_id_incr=${16}

export OMP_NUM_THREADS=$cpus_per_task

taskscript="/home/mesonqcd/reisinger/programs/scripts/multilevel/compute_multilevel.sh"
step_firstconf=$((${confs_per_task}*${tasks_per_step}*${SLURM_ARRAY_TASK_ID}+${first_conf}))

srun -n${tasks_per_step} --cpus-per-task=$cpus_per_task "$taskscript" "$logfile_prefix" "$conf_prefix" $beta $T $L $configs "$comp_file" $WL_Rs $NAPEs $updates $seed $step_firstconf $confs_per_task $conf_id_incr
