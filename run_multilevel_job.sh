#!/bin/bash

#SBATCH --extra-node-info=2:20:1

module load comp/gcc/8.2.0

err="Usage: $0 <logfile_prefix> <conf_file> <beta> <T> <L> <configs> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <tasks_per_step> <cpus_per_task> <confs_per_task> <conf_id_incr>"

if [ $# -ne 15 ]; then
	echo $err
	exit
fi

logfile_prefix="${1}"
conf_file="${2}"
beta="${3}"
T=${4}
L=${5}
configs=${6}
comp_file="${7}"
WL_Rs=${8}
NAPEs=${9}
updates=${10}
seed=${11}
tasks_per_step=${12}
cpus_per_task=${13}
confs_per_task=${14}
conf_id_incr=${15}

export OMP_NUM_THREADS=$cpus_per_task

taskscript="/home/mesonqcd/reisinger/programs/scripts/multilevel/compute_multilevel.sh"
step_firstconf=$((${confs_per_task}*${tasks_per_step}*${SLURM_ARRAY_TASK_ID}+1))

srun -n${tasks_per_step} --cpus-per-task=$cpus_per_task "$taskscript" "$logfile_prefix" "$conf_file" $beta $T $L $configs "$comp_file" $WL_Rs $NAPEs $updates $seed $step_firstconf $confs_per_task $conf_id_incr
