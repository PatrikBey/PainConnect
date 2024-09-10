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
  figlet "DeepStroke - GCN" | lolcat 
	cat <<EOF

* author:       Patrik Bey
* last update:  2024/08/23

--- documentation ---
This container performs model training and prediction for a given
disconnectome data set with the purpose of prediction long term recovery.

Input:
* Data set of connectivity matrices following BIDS 
  standard for computational modelling (Schirner & Ritter, 2023) with <<filename>> variable
  for disconnectome file to read
* participant.tsv file containing recovery group 
  (class label) for each participant

Output:
* F1-score for prediction performance for each cross-validation run [F1.tsv]
* Loss value across epochs for training and testing [training_loss.tsv, test_loss.tsv]
* Final prediction labels for each participant [predictions.tsv]

--- container usage ---
docker run \
    -v /PATH/TO/DATA:/data \
    -e predict=True \
    -e filename=<<filename>> \
    -e initialize=True \
    gsp:latest


--- variables ---

predict [optional]      :   run training and prediction of GCN model 
                            after running intialization step
filename [optional]     :   disconnectome filename string e.g. 'avg-disconnectome' to read
                            all subject files {sub-ID}_avg_disconnectome.tsv          
initialize [optional]   :   initialize model training, includes completeness check,
                            dataset creation, label formatting
param                   :   json style ditionary of model parameters 
                            to replace default values.   
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