#!/bin/bash

submit_scr="/home/mesonqcd/reisinger/programs/scripts/multilevel/submit_multilevel.sh"

read -p "NOTE: UNTESTED. Continue (y)? " ans
[[ "$ans" == "y" ]] || exit 1

#######################################################################################################

confs_per_task=$(grep -E 'confs_per_step' job_info | grep -oE '[0-9]+')
first_out_id=$(grep -E 'first_out_id' job_info | grep -oE '[0-9]+')

( [[ "$confs_per_task" =~ ^[0-9]+$ ]] && [[ "$first_out_id" =~ ^[0-9]+$ ]] ) || {
	echo "Error: invalid or missing job_info file"
	exit 1
}

cmnd_args=()
while read -r line; do
	[[ "$line" == "##########" ]] && break
	cmnd_args+=( "$line" )
done < job_info

failed_steps=""
for f in slurm*; do

	[[ -s "$f" ]] || continue

	jobid=$(echo "$f" | grep -oE 'slurm-[0-9]+_' | grep -oE '[0-9]+')
	step=$(echo "$f" | grep -oE '_[0-9]+.out' | grep -oE '[0-9]+')

	if ! [[ "$jobid" =~ ^[0-9]+$ ]] || ! [[ "$step" =~ ^[0-9]+$ ]]; then
		continue
	fi

	sacct -j "${jobid}_${step}" | grep -q 'FAILED' || continue

	echo "Step $step failed, cleaning files ..."

	first_conf=$((${first_out_id}+${confs_per_task}*${step}))
	last_conf=$((${first_out_id}+${confs_per_task}*(${step}+1)-1))

	read -p "WARNING: deleting data and logs for configs ${first_conf} - ${last_conf}, continue (y)?" ans
	[[ "$ans" == "y" ]] || continue

	rm "$f"
	for c in $(seq $first_conf $last_conf); do
		rm -f *.$c *.${c}.log
	done

	[[ "${#failed_steps}" -eq 0 ]] || failed_steps="${failed_steps},"
	failed_steps="${failed_steps}$step"

done

submit=true

failed_num=$(echo "$failed_steps" | tr ',' '\n' | wc -l)
failed_num_uniq=$(echo "$failed_steps" | tr ',' '\n' | sort | uniq | wc -l)
if [[ $failed_num -ne $failed_num_uniq ]]; then
	submit=false
	echo "Duplicate failed step(s) found ... manually resubmit:"
fi

read -p "Resubmitting job... submit (y) with failed nodes excluded (x): "
if [[ "$ans" == "x" ]]; then
	excl="$(sacct -j "${jobid}_${step}" -no "nodelist%150" | head -1 | awk '{print $1}')"
	sed -i -r 's/^#?exclude=.*/exclude="-x '${excl}'"/' "$submit_scr"
elif [[ "$ans" == "y" ]]; then
	sed -i -r 's/^exclude=/#exclude=/' "$submit_scr"
else
	submit=false
	echo "Skipping submit .. manually run:"
fi

echo "$submit_scr" "${cmnd_args[@]}" $failed_steps
$submit && "$submit_scr" "${cmnd_args[@]}" $failed_steps

