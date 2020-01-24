#!/bin/bash

################ Hardware info ###############

NODE_CPUS=40
NODE_MEM=192000

##############################################

function print_help {
	echo "Usage: $0 <logfile_prefix> <conf_file> <beta> <T> <L> <configs>"
	echo -e "\t<mem> <time> <comp_file> <WL_Rs> <NAPEs> <updates> <seed> <confs_per_task>"
	echo -e "\t[<conf_id_incr> [<nodes_per_step> [<partition> [<array>]]]]"
	echo ""
	echo -e "\tSubmit multilevel jobs. Automatically request as many job steps"
	echo -e "\tas needed for the given <mem>, with <nodes_per_step> (default=2)"
	echo -e "\tnodes requested for each step. CPUs are distributed evenly between tasks."
	echo ""
	echo -e "\t<mem>: memory [MB] needed by each single multilevel task"
	echo -e "\t<configs>: comma separated list of the number of configs at levels 0,1,..."
	echo -e "\t<updates>: comma separated list of the number of updates at levels 0,1,..."
	echo -e "\t<conf_id_incr>: increment filename extensions by <conf_id_incr>"
	echo ""
	echo -e "\tNOTE multiple seeds are used: <seed> is incremented by the config number"
	exit
}

for arg in "$@"; do
	if [ $arg == '-h' ] || [ $arg == '--help' ]; then
		print_help
	fi
done

if [ $# -lt 14 ]; then
	print_help
fi

logfile_prefix="${1}"
conf_file="${2}"
beta="${3}"
T=${4}
L=${5}
configs=${6}
mem=${7}
jobtime=${8}
comp_file="${9}"
WL_Rs=${10}
NAPEs=${11}
updates=${12}
seed=${13}
confs_per_task=${14}
conf_id_incr=${15:-0}
nodes_per_step=${16:-2}
partition=${17:-"general1"}

top_level_confs=${configs%%,*}
level_confs=${configs#*,}

task_num=$(((${top_level_confs}+${confs_per_task}-1)/${confs_per_task})) #ceil(top_level_confs/confs_per_task)

max_tasks_per_node=$((${NODE_MEM}/${mem}))
tasks_per_node=$((${max_tasks_per_node}<${NODE_CPUS}?${max_tasks_per_node}:${NODE_CPUS}))
nodes=$(((${task_num}+${tasks_per_node}-1)/${tasks_per_node})) #ceil(task_num/tasks_per_node)
steps=$(((${nodes}+${nodes_per_step}-1)/${nodes_per_step})) #ceil(nodes/nodes_per_step)

tasks_per_step=$((${nodes_per_step}*${tasks_per_node}))

array=${18:-"0-$(($steps-1))"}

cpus_per_task=$((${NODE_CPUS}/${tasks_per_node}))
mem_per_cpu=$(($mem/$cpus_per_task))

echo "Submitting job ..."
echo -e "\t--partition=$partition"
echo -e "\t--nodes=$nodes_per_step"
echo -e "\t--ntasks-per-node=$tasks_per_node"
echo -e "\t--mem-per-cpu=$mem_per_cpu"
echo -e "\t--time=$jobtime"
echo -e "\t--steps=$steps"
echo -e "\tCPUs per task:\t$cpus_per_task"

jobscript="/home/mesonqcd/reisinger/programs/scripts/multilevel/run_multilevel_job.sh"

exclude="-x node45-001"
sbatch $exclude --partition=$partition -J"${logfile_prefix}_T${T}L${L}_b${beta}_N${NAPEs}_c${configs}_up${updates}_s${seed}" --nodes=$nodes_per_step --ntasks-per-node=$tasks_per_node --mem-per-cpu=$mem_per_cpu --time=$jobtime --array=$array "$jobscript" "$logfile_prefix" "$conf_file" $beta $T $L $level_confs $comp_file $WL_Rs $NAPEs $updates $seed $tasks_per_step $cpus_per_task $confs_per_task $conf_id_incr
