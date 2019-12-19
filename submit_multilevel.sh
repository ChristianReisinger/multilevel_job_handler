#!/bin/bash

################ Hardware info ###############

NODE_CPUS=40
NODE_MEM=192000

##############################################


if [ $# -lt 14 ]; then
	echo "Usage: $0 <logfile_prefix> <conf_prefix> <first_conf> <beta> <T> <L> <configs>"
	echo -e "\t<mem> <time> <comp_file> <WL_Rs> <NAPEs> <updates> <seed>"
	echo -e "\t[<nodes_per_step> [<partition> [<array>]]]"
	echo ""
	echo -e "\tSubmit multilevel jobs. Automatically request as many job steps"
	echo -e "\tas needed for the given <mem>, with <nodes_per_step> (default=2)"
	echo -e "\tnodes requested for each step. CPUs are distributed evenly between tasks."
	echo ""
	echo -e "\t<mem>: memory [MB] needed by each single multilevel task"
	echo -e "\t<configs>: comma separated list of the number of configs at levels 0,1,..."
	echo -e "\t<updates>: comma separated list of the number of updates at levels 0,1,..."
	exit
fi

logfile_prefix="${1}"
conf_prefix="${2}"
first_conf="${3}"
beta="${4}"
T=${5}
L=${6}
configs=${7}
mem=${8}
jobtime=${9}
comp_file="${10}"
WL_Rs=${11}
NAPEs=${12}
updates=${13}
seed=${14}
nodes_per_step=${15:-2}
partition=${16:-"general1"}

top_level_confs=${configs%%,*}
level_confs=${configs#*,}

max_tasks_per_node=$((${NODE_MEM}/${mem}))
tasks_per_node=$((${max_tasks_per_node=}<${NODE_CPUS}?${max_tasks_per_node=}:${NODE_CPUS}))
nodes=$(((${top_level_confs}+${tasks_per_node}-1)/${tasks_per_node})) #ceil(top_level_confs/tasks_per_node)
steps=$(((${nodes}+1)/${nodes_per_step})) #ceil(nodes/nodes_per_step)

tasks_per_step=$((${nodes_per_step}*${tasks_per_node}))

array=${17:-"0-$(($steps-1))"}

cpus_per_task=$((${NODE_CPUS}/${tasks_per_node}))

export OMP_NUM_THREADS=$cpus_per_task

echo "Requesting $steps jobsteps ..."

jobscript="/home/mesonqcd/reisinger/programs/scripts/multilevel/run_multilevel_job.sh"
#exclude="-x node45-021,node50-[021,024],node49-[032-033]"
sbatch --partition=$partition -J"${logfile_prefix}_c${configs}_up${updates}_s${seed}.$first_conf" --nodes=$nodes_per_step --ntasks-per-node=$tasks_per_node --mem-per-cpu=$mem --cpus-per-task=$cpus_per_task --time=$jobtime --array=$array "$jobscript" "$logfile_prefix" "$conf_prefix" $first_conf $beta $T $L $level_confs $comp_file $WL_Rs $NAPEs $updates $seed $tasks_per_step
