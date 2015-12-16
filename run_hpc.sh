#!/bin/bash
#
# This script runs a FUDGE experiment on an HPC system. Before running, you
# or your HPC admin/support should edit the file referenced by the SITE_CONFIG
# setting below.
#
# Do not edit this script.
#
# How to use:
#
#   ./run_hpc.sh experiment_config_file
#      OR
#   ./run_hpc.sh
#      (looks for hpc_experiment_conf in $PWD)
#
# Here is a general overview of this script:
#
#   1. Submit the begin (pre-downscaling) job in a hold state and collect 
#      the job ID.
#
#   2. Submit the downscaling jobs with the begin job as a dependency; 
#      collect the job IDs of the downscaling jobs.
#
#   3. Submit the combine (post-downscaling) job with the downscaling 
#      jobs as a dependency.
#
#   4. Release the begin job.
#

# Set the parent folder of this script as FUDGE_ROOT
FUDGE_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

SITE_CONFIG="${FUDGE_ROOT}/hpc_site_conf"
source ${SITE_CONFIG}

# ${SCHEDULER_MODULE} should be set in ${SITE_CONFIG}
source "${FUDGE_ROOT}/hpc_modules/${SCHEDULER_MODULE}"

# Experiment config
EXPERIMENT_CONFIG="hpc_experiment_conf"
if [ $# -eq 1 ] && [ -a $1 ] && [ "$1"=="$0" ]; then
	EXPERIMENT_CONFIG="$1"
elif [ $# -eq 0 ] && [ -a ${PWD}/${EXPERIMENT_CONFIG} ]; then 
	EXPERIMENT_CONFIG="${PWD}/${EXPERIMENT_CONFIG}"
else
	echo -e "Invalid or no hpc experiment config specified." 1>&2
	echo -e "Valid file not specified on command line and ${EXPERIMENT_CONFIG} not found in ${PWD}."
	exit 1
fi
source ${EXPERIMENT_CONFIG}

# Make sure the experiment config was good
WALLTIME_REGEX='[0-9]+\:[0-5][0-9]\:[0-5][0-9]'
declare -a ERROR

[ -z "${FUDGE_WORK_DIR}" ] || [ ! -d "${FUDGE_WORK_DIR}" ] && 
	ERROR[${#ERROR[@]}]="FUDGE_WORK_DIR not set or is not a directory."

[ -z "${QUEUE_BEGIN}" ] || [ -z "${QUEUE_DS}" ] || [ -z "${QUEUE_COMBINE}" ] &&
	ERROR[${#ERROR[@]}]="At least one queue name is not set." 

[[ ! ${WALLTIME_BEGIN} =~ ${WALLTIME_REGEX} ]] || [[ ! ${WALLTIME_DS} =~ ${WALLTIME_REGEX} ]] || [[ ! ${WALLTIME_COMBINE} =~ ${WALLTIME_REGEX} ]] && 
	ERROR[${#ERROR[@]}]="At least one walltime setting is invalid."

[ ${#ERROR[@]} -gt 0 ] && {
	echo "Errors:" 1>&2
	for e in "${ERROR[@]}"; do
		echo "   ${e}" 1>&2
	done
	exit 1
}
unset ERROR
# End validating experiment config


JOB_LIST="fudge_jobs.list"
BEGIN_SCRIPT="fudge_begin.pbs"
DS_INPUTS="ds_inputs.txt"
COMBINE_SCRIPT="fudge_combine.pbs"
# Delete any of these files if it already exists
[ -a ${JOB_LIST} ] && rm -f ${JOB_LIST}
[ -a ${BEGIN_SCRIPT} ] && rm -f ${BEGIN_SCRIPT}
[ -a ${DS_INPUTS} ] && rm -f ${DS_INPUTS}
[ -a ${COMBINE_SCRIPT} ] && rm -f ${COMBINE_SCRIPT}


#
# Create and submit the begin script
#

# Export variables for use in the f_echo_job_directives function
export _job_name="fudge_begin"
export _queue_name="${QUEUE_BEGIN}"
export _depend_list=""
export _walltime="${WALLTIME_BEGIN}"
export _nodes="1"
export _cores_per_node="1"
export _email_notify="${EMAIL_NOTIFY_BEGIN}"

# Write the begin script
f_echo_script_header > ${BEGIN_SCRIPT}
f_echo_job_directives >> ${BEGIN_SCRIPT}
f_echo_set_fudge_environment >> ${BEGIN_SCRIPT}
cat <<-EOF_BEGIN >> ${BEGIN_SCRIPT}
echo TEST: Begin Script
sleep 10s
Rscript get_vectors.R > ${DS_INPUTS}
EOF_BEGIN

# Submit the begin script and get the job ID
BEGIN_JOB_ID=$(f_job_submit_hold ${BEGIN_SCRIPT})


#
# Create and submit downscaling jobs.
# The downscaling jobs will only start after the begin script ends successfully.
#
DS_JOB_COUNT=0
Rscript get_vectors.R | while read rcmd_args; do
	DS_JOB_COUNT=$(( ${DS_JOB_COUNT} + 1 ))
	DS_JOB_SUFFIX=$(printf "%04d" ${DS_JOB_COUNT})
	DS_JOB_NAME="fudge_ds_${DS_JOB_SUFFIX}"
	DS_JOB_SCRIPT="${DS_JOB_NAME}.pbs"

	# Task to be run (i.e. the downscaling)
	RCMD="R CMD BATCH \"--args=${rcmd_args}\" Rjobs.R"
	# ? Should this be MAIN_Runcode.R instead of Rjobs.R ?

	# Export variables for use in the f_echo_job_directives function
	export _job_name="${DS_JOB_NAME}"
	export _queue_name="${QUEUE_DS}"
	export _depend_list="${BEGIN_JOB_ID}"
	export _walltime="${WALLTIME_DS}"
	export _nodes="1"
	export _cores_per_node="1"
	export _email_notify="${EMAIL_NOTIFY_DS}"

	# Write submission script for this job
	f_echo_script_header > ${DS_JOB_SCRIPT}
	f_echo_job_directives >> ${DS_JOB_SCRIPT}
	f_echo_set_fudge_environment >> ${DS_JOB_SCRIPT}
	cat <<-EOF_DS >> ${DS_JOB_SCRIPT}
	#${RCMD}
	echo TEST: ${RCMD}
	echo Job ID: \${PBS_JOBID}
	echo Output of begin job:
	cat ${DS_INPUTS}
	EOF_DS

	# Submit the job and collect the job_id
	# Job won't run until the begin job is released and finishes
	JOB_ID=$(f_job_submit ${DS_JOB_SCRIPT})
	# Add the job_id to the file ${JOB_LIST}
	echo ${JOB_ID} >> ${JOB_LIST}
done


#
# Create and submit the combine script.
# It won't actually run until all downscaling jobs have finished successfully.
#

# List all the downscaling job IDs separated by colons on a single line
JOB_LIST_STRING=$(cat ${JOB_LIST} | tr '\n' ':' | sed 's/:$//')

# Export variables for use in the f_echo_job_directives function
export _job_name="fudge_combine"
export _queue_name="${QUEUE_COMBINE}"
export _depend_list="${JOB_LIST_STRING}"
export _walltime="${WALLTIME_COMBINE}"
export _nodes="1"
export _cores_per_node="1"
export _email_notify="${EMAIL_NOTIFY_COMBINE}"

# Write the combine script
f_echo_script_header > ${COMBINE_SCRIPT}
f_echo_job_directives >> ${COMBINE_SCRIPT}
f_echo_set_fudge_environment >> ${COMBINE_SCRIPT}
cat <<-EOF_COMBINE >> ${COMBINE_SCRIPT}
echo TEST: Combine Script
for i in {1..$(cat ${JOB_LIST} | wc -l)}; do
	SUFFIX=\$(printf "%04d" \${i})
	echo fudge_ds_\${SUFFIX}
	cat fudge_ds_\${SUFFIX}.o*
	echo ""
done
EOF_COMBINE

f_job_submit ${COMBINE_SCRIPT}


#
# Release the begin job
#
f_job_release ${BEGIN_JOB_ID}
