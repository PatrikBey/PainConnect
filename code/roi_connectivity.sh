#!/bin/bash
#
#
# # roi_connectivity.sh
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
# This script extract the single connectivity profile of a given ROI
# as seed to all target ROIs. It represents the modular approach to rio2roi_Connectivity.sh
# to enable cluster based parallelization.

#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################

log_msg() {
    # print out text for logging
    # ${1}: string to print
    _message=$( echo ${1} | cut -d':' -f2 )
    echo -e "$(date) $(basename  -- "$0") : ${_message}"
}





if [ ${Step,,} = "preproc" ]; then
    log_msg "START:    run preprocessing for connectivity extraction for ${rois_seed} and ${rois_target}."



if [ ${Step,,} = "roi.conn" ]; then



if [ ${Step,,} = "roi2roi.conn" ]; then


