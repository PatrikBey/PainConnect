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

docker run ...

--- variables ---

<<seed>>   name of set of ROIs to use as initial ROIs for connectivity
                {required} | [represents rows in conenctivity matrix]

<<target>> name of set of ROIs to use as secondary ROIs 
                for connectivity
                {optional} | [represents columns in connectivity matrix]

<<cleanup>>     boolean whether to remove temporary files
                {optional} | [default: True >> removing temp-directory]


--- input ---

expected input file structure:

/STUDYFOLDER
    |_rois_seed
        |_roi_masks
    |_rois_target
        |_roi_masks

EOF
	# exit 1
}


# 2. log_msg
log_msg() {
    # print out text for logging
    _message=$( echo ${1} | cut -d':' -f2 )
    echo -e "$(date) $(basename  -- "$0") : ${_message}"
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

