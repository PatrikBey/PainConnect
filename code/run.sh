#!/bin/bash
#
#
# # get_tracts.sh
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
# This script extractes ROI based tractograms from the template normative connectome (1) 
# using ROI volume masks. If one ROI mask is provided all tracks intersecting the given 
# ROI are extracted. If multiple ROI masks are provided all tracks intersecting with all ROI masks
# are returned.
#
# * steps within this script:
# * 1. subsetting existing Tractogram (from DWITractogram.sh)
#
# REQUIREMENTS: 
# 1. ROI2ROI docker container [or quivalent]

# 3. ROI nifti volume mask(s)



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

# ---- loading I/O & logging functionality ---- #
source ${SRCDIR}/utils.sh
source ${SRCDIR}/functions.sh

# ---- parse input variables ---- #

if [[ ! -d "/data" ]]; then
    log_msg "ERROR:    no <</data>> directory mounted into container."
    show_usage
else
    Path="/data"
fi

if [[ -z ${seed} ]]; then
    log_msg "ERROR:    no <<seed>> variable defined."
    show_usage
fi


if [[ -z ${target} ]]; then
    log_msg "ERROR:    no <<target>> variable defined."
    show_usage
fi

if [[ -z ${Template} ]]; then
    log_msg "UPDATE:    no <<Template>> defined. Using default tractogram '/data/Templates/dTOR_full_tractogram.tck'"
    Template="${TEMPLATEDIR}/dTOR_full_tractogram.tck"
fi

if [ -d "${Path}/${seed}" ]; then
    log_msg "UPDATE:    running full roi2roi connectivity for seed ROI set."
    roi_mode="full"
elif [ -f "${Path}/${seed}" ]; then
    log_msg "UPDATE:    running single seed ROI connectivity."
    roi_mode="single"
else
    log_msg "ERROR:    can't find corresponding ROI seed file/directory."
    show_usage
fi



#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

# ---- intialize logging ---- #
log_msg "START:    Processing of $( basename ${seed} ) and ${target}" | lolcat

# ---- initialize workspace ---- #
get_temp_dir ${Path}


if [ ${roi_mode} = "full" ]; then

    if [ ! -f "${Path}/${rois_seed}/LUT.txt" ]; then
        log_msg "UPDATE:    compute look-up table for ${rois_seed}"
        get_lookup_table /data/${rois_seed}
    fi

    rois_seed_list="${Path}/${rois_seed}/roi_masks/*.nii.gz"

else 

    rois_seed_list="${seed}"

fi


# ---- prepare target metadata ---- #
if [ ! -f "${Path}/${target}/LUT.txt" ]; then
    log_msg "UPDATE:    compute look-up table for ${target}"
    get_lookup_table "${Path}/${target}"
fi


# ---- create binary mask of all target ROIs ---- #

log_msg "UPDATE:    create target ROIs binary mask for tract reduction."
get_binary_volume ${rois_target}

# ---- reduce normative tractogram ---- #

log_msg "UPDATE:    extracting target ROI tract subset."
get_tract_subset ${TempDir}/${rois_target}_ribbon_bin.nii.gz

rois_target_list="${Path}/${rois_target}/roi_masks/*.nii.gz"






log_msg "FINISHED:    Processing of $( basename ${seed} ) and ${target}" | lolcat
