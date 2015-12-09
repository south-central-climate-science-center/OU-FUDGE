#!/bin/bash

# Job control commands
SUBMIT_CMD="qsub"
HOLD_CMD="qhold"
RELEASE_CMD="qrls"

QUEUE_BEGIN="express"
QUEUE_DS="batch"
QUEUE_COMBINE="express"

WALLTIME_BEGIN="0:05:00"
WALLTIME_DS="1:00:00"
WALLTIME_COMBINE="0:05:00"

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
cat <<-EOF_BEGIN > ${BEGIN_SCRIPT}
#!/bin/bash
#PBS -N fudge_begin
#PBS -q ${QUEUE_BEGIN}
#PBS -l nodes=1:ppn=1
#PBS -l walltime=${WALLTIME_BEGIN}
#PBS -m abe -M dunc.wilson9@gmail.com
#   send me email when job aborts, begins and exits
#PBS -j oe
#    join the output in error file into one file
cd \${PBS_O_WORKDIR}
#    change to current working directory
module load R/3.2.1
module load netcdf/4.3.3.1
module load udunits/2.2.20
echo TEST: Begin Script
Rscript /home/dwilson/FUDGE/firstRv2.R > ${DS_INPUTS}
EOF_BEGIN
# Submit the begin script and get the job ID
BEGIN_JOB_ID=$(${SUBMIT_CMD} ${BEGIN_SCRIPT})


#
# Create and submit downscaling jobs.
# The downscaling jobs will only start after the begin script ends successfully.
#
DS_JOB_COUNT=0
Rscript /home/dwilson/FUDGE/firstRv2.R  | while read rcmd_args; do
	DS_JOB_COUNT=$(( ${DS_JOB_COUNT} + 1 ))
	DS_JOB_SUFFIX=$(printf "%04d" ${DS_JOB_COUNT})
	DS_JOB_SCRIPT="fudge_ds_${DS_JOB_SUFFIX}.pbs"
	RCMD="R CMD BATCH \"--args ${rcmd_args}\" /home/dwilson/FUDGE/MAIN.Runcode.HPC.R fudge_ds_${DS_JOB_SUFFIX}.Rout"

	# Write submission script for this job
	cat <<-EOF_DS > ${DS_JOB_SCRIPT}
	#!/bin/bash  
	#PBS -N fudge_ds_${DS_JOB_SUFFIX}
	#PBS -q ${QUEUE_DS}
	#PBS -W depend=afterok:${BEGIN_JOB_ID}
	#PBS -l nodes=1:ppn=1  
	#PBS -l walltime=${WALLTIME_DS}
	#   #PBS -m abe -M monkey@example.com
	#   send me email when job aborts, begins and exits
	#PBS -j oe
	#    join the output in error file into one file
	cd \${PBS_O_WORKDIR}
	#    change to current working directory
	module load R/3.2.1
	module load netcdf/4.3.3.1
	module load udunits/2.2.20
	${RCMD}
	echo TEST: ${RCMD}
	echo Job ID: \${PBS_JOBID}
	echo Output of begin job:
	cat ${DS_INPUTS}
	EOF_DS

	# Submit the job and collect the job_id
	JOB_ID=$(${SUBMIT_CMD} ${DS_JOB_SCRIPT})
	# Hold the job so that it doesn't run yet.
	# Don't want to release the jobs until the entire job list is built.
	${HOLD_CMD} ${JOB_ID}
	# Add the job_id to the file ${JOB_LIST}
	echo ${JOB_ID} >> ${JOB_LIST}
done

# Release all the jobs listed in the file ${JOB_LIST} (i.e. let them run)
while read jid; do
	${RELEASE_CMD} ${jid}
done < ${JOB_LIST}


#
# Create and submit the combine script.
# It won't actually run until all downscaling jobs have finished successfully.
#

# List all the downscaling job IDs separated by colons on a single line
JOB_LIST_STRING=$(cat ${JOB_LIST} | tr '\n' ':' | sed 's/:$//')
cat <<-EOF_COMBINE > ${COMBINE_SCRIPT}
#!/bin/bash
#PBS -N fudge_combine
#PBS -q ${QUEUE_COMBINE}
#PBS -W depend=afterok:${JOB_LIST_STRING}
#PBS -l nodes=1:ppn=1
#PBS -l walltime=${WALLTIME_COMBINE}
#   #PBS -m abe -M monkey@example.com
#   send me email when job aborts, begins and exits
#PBS -j oe
#    join the output in error file into one file
cd \${PBS_O_WORKDIR}
#    change to current working directory
module load R/3.2.1
module load netcdf/4.3.3.1
module load udunits/2.2.20
echo TEST: Combine Script
for i in {1..$(cat ${JOB_LIST} | wc -l)}; do
	SUFFIX=\$(printf "%04d" \${i})
	echo fudge_ds_\${SUFFIX}
	cat fudge_ds_\${SUFFIX}.o*
	echo ""
done
EOF_COMBINE

${SUBMIT_CMD} ${COMBINE_SCRIPT}

