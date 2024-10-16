#!/bin/bash
#
#
# # cluster_wrapper.sh
#
#
# * Brain Simulation Section
# * Charité Berlin Universitätsmedizin
# * Berlin Institute of Health
#
# ## Author(s)
# * Bey, Patrik, Charité Universitätsmedizin Berlin, Berlin Institute of Health
# 
#
# * last update: 2024.10.14
#
#
#
# ## Description
#
# This script is a wrapper for singularity calls
# within the BIH4Research cluster slurm environment
#
#

#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################


show_usage() {
	cat <<EOF

***************************************************************
***     SINGULARITY LESION2TVB PROCESSING PIPELINE CALL     ***

Usage:  RunSingularity.sh \ 
    -d << /Path/To/StudyDirectory [string] >> [required] \ 
    -s << ROI seed [string] >> [required] \ 
    -t << ROI target list [strings] >> [required] \ 
    -p << preprocessing [string] >> [optional] \ 
    -c << clean-up [string] >> [optional] \ 

***************************************************************

EOF
	exit 1
}

log_msg() {
    # print out text for logging
    _message=${1}
    echo -e "\n$(date) $(basename  -- "$0") | ${_message}"

}

#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################


# PARSING INPUT ARGUMENTS
while getopts d:s:t:p:c: flag
do
    case "${flag}" in
        d) Path=${OPTARG};; # directory to be mounted into container as StudyFolder
        s) Seed=${OPTARG};; # seed ROI(s) 
        t) Target=${OPTARG};; # target ROIs
        p) Preproc=${OPTARG};; # preprocessing mode
        c) CleanUp=${OPTARG};; # clean-up of temporary directories
    esac
done


if [ $# -eq 0 ]; then
    log_msg "ERROR:    No arguments provided"
    show_usage
fi

if [[ -z ${CONTAINERDIR} ]]; then
    export CONTAINERDIR="/data/cephfs-1/home/users/beyp_c/work/projects/PainConnect/container"
fi

if [[ -z ${Path} ]]; then
    log_msg "ERROR:    No <<Path>> variable defined."
    show_usage
fi
if [[ -z ${Seed} ]]; then
    log_msg "ERROR:    No <<Seed>> variable defined."
    show_usage
fi
if [[ -z ${Target} ]]; then
    log_msg "ERROR:    No <<Target>> variable defined."
    show_usage
fi

#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

singularity run \
    --bind ${Path}:/data \
    --env seed="${Seed}" \
    --env target="${Target}" \
    --env preproc=${Preproc} \
    --env cleanup=${Streams} \
    --env CLUSTER=TRUE \
    ${CONTAINERDIR}/roi2roi.sif