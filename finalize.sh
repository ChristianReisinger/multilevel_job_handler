#i!/bin/bash

combine_scr="/home/mesonqcd/reisinger/programs/scripts/multilevel/combine_data.sh"

sort_by_param_cols() {
	content="$(cat)"
	col_num=$(($(echo "$content" | head -1 | awk '{print NF}')-2)) # last 2 columns contain data (mu sigma)
	sort_cmnd=( "sort" "-n" )
	for col in $(seq 1 $col_num); do
		sort_cmnd+=( "-k${col},${col}" )
	done
	echo "$content" | "${sort_cmnd[@]}"
}

###############################################################################

exit_with_error() {
	rm -f "log"
	rm -rf "cmb"
	rm -f *".dat"
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
echo "Gathering job IDs ..."

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
echo "" >> log

echo "Gathering log files ..."
log_header() {
	echo -e "\n--------------------------------------- $1 ---------------------------------------\n"
}
for f in *.log; do
	log_header "$f" >> log
	cat "$f" >> log
done

log_lines=$(wc -l *".log" | head -1 | awk '{print $1}')
log_file_num=$(ls *".log" | wc -l)
total_log_lines=$(wc -l "log" | awk '{print $1}')
header_lines=$(log_header "dummy" | wc -l)

##### check that all lines were successfully copied #####
[[ $((1 + log_file_num * (header_lines + log_lines))) -eq $total_log_lines ]] || exit_with_error "failed to create log"

###############################################################################

mkdir cmb
datafiles="$(find * -type f -regextype posix-extended -regex '.*[.][0-9]+')"
obs_names="$(echo "$datafiles" | sed -r 's/[.][0-9]+$//g' | sort | uniq)"
while read -r obs; do
	echo "Gathering '$obs' data ..."
	[[ -f "${obs}.dat" ]] && exit_with_error "data file '${obs}.dat' already exists"
	"$combine_scr" "$obs" | sort_by_param_cols > "cmb/${obs}.dat"
done <<< "$obs_names"
mv "cmb/"* .

##### check that nothing went wrong by matching first/last lines of input/output #####
echo "Checking gathered data ..."
while read -r obs; do
	first_file="$(find * -type f -name "${obs}.*" | sort -V | head -1)"
	first_mu_sigma_in="$(cat "$first_file" | sort_by_param_cols | head -1 | awk '{print $(NF-1),$NF}')"
	last_file="$(find * -type f -name "${obs}.*" | sort -V | tail -1)"
	last_mu_sigma_in="$(cat "$last_file" | sort_by_param_cols | tail -1 | awk '{print $(NF-1),$NF}')"

	first_mu_sigma_out="$(head -1 "${obs}.dat" | awk '{print $(NF-1),$NF}')"
	last_mu_sigma_out="$(tail -1 "${obs}.dat" | awk '{print $(NF-1),$NF}')"

	( [[ "$first_mu_sigma_out" != "" ]] \
	&& [[ "$last_mu_sigma_out" != "" ]] \
	&& [[ "$first_mu_sigma_out" == "$first_mu_sigma_in" ]] \
	&& [[ "$last_mu_sigma_out" == "$last_mu_sigma_in" ]] ) \
	|| exit_with_error "failed to combine data files"
done <<< "$obs_names"

##### everything successful, clean up files #####
echo "All ok, cleaning files ..."
find * -type f -regextype posix-extended -regex '.*[.][0-9]+' -exec rm {} +
rm "slurm"*
rm *".log"
rm -r "cmb"
rm job_info
