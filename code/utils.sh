#!/bin/bash
#
#
# # utils.sh
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
# * last update: 2024.09.06
#
#
#
# ## Description
#
# This script contains utility functions.
#
#
# FUNCTIONS: 
# 1. show_usage     :   help function to display usage of analysis framework
# 2. log_msg        :   printing logging statements to std_out
# 3. check_variable :   check if defined variable is present in environment

#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################


# 1. show_usage

show_usage() {
  figlet "ROI2ROI" | lolcat 
	cat <<EOF

* author:       Patrik Bey
* last update:  2024/10/14

STRUCTURAL CONNECTIVITY FOR FUNCTIONAL NETWORKS OF PAIN


--- documentation ---

--- usage ---

docker run \
    -v /PATH/TO/STUDYFOLDER:/data \
    -e seed="SeedROIs" \
    -e target="TargetROIs" \
    roi2roi

--- variables ---

<<seed>>   name of set of ROIs to use as initial ROIs for connectivity
                {required} | [represents rows in conenctivity matrix]

<<target>> name of set of ROIs to use as secondary ROIs 
                for connectivity
                {optional} | [represents columns in connectivity matrix]

<<template>>    template tractogram in same space as <seed> and <target>.
                {optional} | [default: dTOR_full_tractogram.tck (Elias et al. (2024))]

<<preproc>>     boolean whether to perform preprocessing as required for
                single seed ROI connectivity computations. Has to be set to "only" once before
                running single ROI connectivity computations
                {optional} | [default: True]

<<cleanup>>     boolean whether to remove temporary files
                {optional} | [default: True >> removing temp-directory]

<<CLUSTER>>     boolean whether container is run on HPC cluster to adjust logging functions.
                {optional} | [default: False >> ussing color coded logging]

--- input ---

expected input file structure:

/STUDYFOLDER
    |_rois_seed
        |_roi_masks
    |_rois_target
        |_roi_masks

EOF
	exit 1
}


# 2. log_msg
log_msg() {
    # print out text for logging
    _type=$( echo ${1} | cut -d'|' -f1 )
    _message=${1}
    if [[ ${CLUSTER,,} = "true" ]]; then
        echo -e "\n$(date) $(basename  -- "$0") | ${_message}"
    else
        if [[ ${_type,,} = "start " ]] || [[ ${_type,,} = "finished " ]] || [[ ${_type,,} = "error " ]]; then
            echo -e "\n$(date) $(basename  -- "$0") | ${_message}" | lolcat
        else
            echo -e "\n$(date) $(basename  -- "$0") | ${_message}"
        fi
    fi
}

# 3. check_variable

check_variable() {
    # check if given variable exists in environment
    # else return error code 1
    if [ -z "${1}" ]; then
        log_msg "ERROR:    variable ${1} not found in environment."
        exit 1
    fi
}

get_temp_dir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}

progress_bar() {
    # print a progress bar during loops
    # ${1} current iteration of loop
    # ${2} total length of loop
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

