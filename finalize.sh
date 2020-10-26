#!/bin/bash

combine_scr="/home/mesonqcd/reisinger/programs/scripts/multilevel/combine_data.sh"

read -p "NOTE: UNTESTED. Continue (y)? " ans
[[ "$ans" == "y" ]] || exit 1

###############################################################################

for arg in "$@"; do
	[[ "$arg" =~ ^-h(elp)?$ ]] && {
		echo "Usage: $0 <sort_column> ..."
		exit
	}
done

for arg in "$@"; do
	[[ "$arg" =~ ^[1-9][0-9]+$ ]] || {
		echo "Error: invalid sort column"
		exit 1
	}
done
sort_cols=( "$@" )
sort_cmnd=( "sort" "-n" )
for col in "${sort_cols[@]}"; do
	sort_cmnd+=( "-k${col},${col}" )
done

###############################################################################

exit_with_error() {
	rm -f "log"
	rm -rf "cmb"
	rm *".dat"
	echo "Error: $1"
	exit 1	
}

##### do not exit_with_error here ! first make sure no files are deleted by accident ! #####

( ls *".log" "slurm"* >& /dev/null && [[ "$(find * -type f -regextype posix-extended -regex ".*[.][0-9]+")" != "" ]] ) || {
	echo "Error: current directory does not look like a multilevel output directory .."
	exit 1
}

[[ -f log ]] && {
	echo "Error: log already exists"
	exit 1
}

ls *".dat" >& /dev/null && {
	echo "Error: found '.dat' files .. there should be none"
	exit 1
}

[[ -d "cmb" ]] && {
	echo "Error: temporary dir 'cmb' already exists"
	exit 1
}

###############################################################################

##### write job ids to log #####
echo -en "JOBIDS:\t" > log
for f in slurm*; do
	id=$(echo "$f" | sed -r 's/slurm-([0-9]+).*/\1/')
	ids="$id
"
done
ids="$(echo "$ids" | sed -r '/^$/d' | sort | uniq)"
first=true
while read -r id; do 
	$first || echo -n ", "
	echo -n $id >> log
	first=false
done <<< "$ids"

##### combine log files #####
for f in *.log; do
	echo -e "\n--------------------------------------- $f ---------------------------------------\n" >> log
done

log_lines$(wc -l *".log" | head -1 | awk '{print $1}')
total_log_lines$(wc -l "log" | awk '{print $1}')

##### check that all lines were successfully copied #####
[[ $(1+3*$log_lines) -eq $total_log_lines ]] || exit_with_error "failed to create log"

###############################################################################

mkdir cmb
datafiles="$(find * -type f -regextype posix-extended -regex '.*[.][0-9]+')"
obs_names="$(echo "$datafiles" | sed -r 's/[.][0-9]+$//g' | sort | uniq)"
while read -r obs; do
	[[ -f "${obs}.dat" ]] && exit_with_error "data file '${obs}.dat' already exists"
	"$combine_scr" "$obs" | "${sort_cmnd[@]}" > "cmb/${obs}.dat"
done <<< "$obs_names"
mv "cmb/"* .

##### check that nothing went wrong by matching first/last lines of input/output #####
while read -r obs; do
	first_file="$(find * -type f -name "${obs}.*" | sort -V | head -1)"
	first_mu_sigma_in="$("${sort_cmnd[@]}" "$first_file" | head -1 | awk '{print $(NF-1),$NF}')"
	last_file="$(find * -type f -name "${obs}.*" | sort -V | tail -1)"
	last_mu_sigma_in="$("${sort_cmnd[@]}" "$last_file" | tail -1 | awk '{print $(NF-1),$NF}')"

	first_mu_sigma_out="$(head -1 "${obs}.dat" | awk '{print $(NF-1),$NF}')"
	last_mu_sigma_out="$(tail -1 "${obs}.dat" | awk '{print $(NF-1),$NF}')"

	( [[ "$first_mu_sigma_out" == "$first_mu_sigma_in" ]] && [[ "$last_mu_sigma_out" == "$last_mu_sigma_in" ]] ) || exit_with_error "failed to combine data files"

done <<< "$obs_names"

##### everything successful, clean up files #####
find * -type f -regextype posix-extended -regex '.*[.][0-9]+' -exec rm {} +
rm "slurm"*
rm *".log"
rm -r "cmb"
