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
    log_msg "ERROR | no <</data>> directory mounted into container."
    show_usage
else
    Path="/data"
fi

if [[ -z ${seed} ]]; then
    log_msg "ERROR | no <<seed>> variable defined."
    show_usage
fi


if [[ -z ${target} ]]; then
    log_msg "ERROR | no <<target>> variable defined."
    show_usage
fi

if [[ -z ${template} ]]; then
    template="${TEMPLATEDIR}/dTOR_full_tractogram.tck"
elif [[ ! -f ${template} ]]; then
    log_msg "ERROR | <<template>> tractogram not found."
    show_usage
fi

if [ -d "${Path}/${seed}" ]; then
    roi_mode="full"
    if [ -z "${preproc}" ]; then
        preproc="true"
    fi
elif [ -f "${Path}/${seed}" ]; then
    roi_mode="single"
    if [[ ! ${preproc,,} = "true" ]] && [[ ! -f "${Path}/${target}/LUT.txt" ]] || [[ ! -f "${Path}/${target}/${target}.tck" ]] || [[ ! -f "${Path}/${target}/${target}_full_mask.nii.gz" ]]; then
        log_msg "ERROR | no preprocessing results found."
        show_usage
    fi
else
    log_msg "ERROR | can't find corresponding ROI seed file/directory."
    show_usage
fi

if [[ -z ${CLUSTER} ]]; then
    CLUSTER="FALSE"
fi

if [[ ! ${cleanup,,} = "false" ]] ; then
    cleanup="true"
fi

#############################################
#                                           #
#               PREPROCESSING               #
#                                           #
#############################################



if [[ ${preproc,,} = "true" ]] || [[ ${preproc,,} = "only" ]] ; then
    log_msg "START | Preprocessing of ${seed} and ${target}"

    # ---- initialize workspace ---- #
    get_temp_dir ${Path}

    # ---- extract look-up tables for both ROI lists ---- #
    if [ ! -f "${Path}/${seed}/LUT.txt" ]; then
        log_msg "UPDATE | compute look-up table for ${seed}"
        get_lookup_table /data/${seed}
    fi

    if [ ! -f "${Path}/${target}/LUT.txt" ]; then
        log_msg "UPDATE | compute look-up table for ${target}"
        get_lookup_table /data/${target}
    fi


    # ---- create binary mask of all target ROIs ---- #
    if [ ! -f "${Path}/${target}/${target}_full_mask.nii.gz" ]; then
        log_msg "UPDATE | create target ROIs binary mask for tract reduction."
        get_binary_volume ${target}
        cp ${TempDir}/${target}_ribbon_bin.nii.gz ${Path}/${target}/${target}_full_mask.nii.gz
    fi

    # ---- reduced normative tractogram ---- #
    if [ ! -f "${Path}/${target}/${target}.tck" ]; then
        log_msg "UPDATE | extracting target ROI tract subset."
        get_tract_subset ${Path}/${target}/${target}_full_mask.nii.gz ${template}
    fi
    # ---- removing temporary directory and files ---- #
    rm -r ${TempDir}

    log_msg "FINISHED | Preprocessing of ${seed} and ${target}"
    if [ ${preproc,,} = "only" ]; then
        exit 0
    fi
fi


#############################################
#                                           #
#               CONNECTIVITY                #
#                                           #
#############################################


# ---- start connectivity computation ---- #
log_msg "START | Computing connetivity for $( basename ${seed%.nii.gz} ) and ${target}" 


# ---- prepare variables ---- #
tck="${Path}/${target}/${target}.tck"

target_list="${Path}/${target}/roi_masks/*.nii.gz"
target_roi_count=$(echo "${target_list}" | grep -o ... | wc -l)

if [[ ${roi_mode} = "full" ]]; then
    seed_list="${Path}/${seed}/roi_masks/*.nii.gz"
    seed_roi_name=${seed}
else 
    seed_list="${Path}/${seed}"
    seed_roi_name=$( basename $( dirname $( dirname ${seed})))
fi


# ---- initialize workspace ---- #
get_temp_dir ${Path}
log_msg "UPDATE | Creating temporary directory ${TempDir}"

# --- loop over all ROI 2 ROI pairings


for roi_seed in ${seed_list}; do
    if [ ! -d "${Path}/${seed_roi_name}/weights" ]; then
        mkdir -p "${Path}/${seed_roi_name}/weights_${target}"
    fi
    log_msg "UPDATE | extract connectivity for seed ROI $( basename ${roi_seed%.nii.gz})"
    touch ${TempDir}/$( basename ${seed%.nii.gz})_weights.tsv
    count=0
    for roi_target in ${target_list}; do
        get_assignments "${roi_seed}" "${roi_target}" "${tck}"
        get_strength ${TempDir}/weights/$( basename ${roi_target%.nii.gz}_weights.tsv)
        echo ${strength} >> ${TempDir}/$( basename ${roi_seed%.nii.gz})_weights.tsv
        progress_bar ${count} ${target_roi_count}
        count=$((count+1))
    done
    cp ${TempDir}/$( basename ${roi_seed%.nii.gz})_weights.tsv \
        ${Path}/${seed_roi_name}/weights_${target}/$( basename ${roi_seed%.nii.gz})_${target}_weights.tsv
done

if [[ ${roi_mode} = "full" ]]; then
    log_msg "UPDATE | combining ROI weights."
    # ---- combine weights of all ROI 2 ROI pairings
    combine_weights ${Path}/${seed}/weights_${target} ${Path}/Connectomes/${seed}_${target}_weights.tsv
fi


# ---- clean up of temporary files ---- #
if [[ ${cleanup,,} = "true" ]] ; then
    log_msg "UPDATE | Performing clean-up of temporary directory"
    rm -r ${TempDir}
fi

log_msg "FINISHED | Computing connetivity for $( basename ${seed%.nii.gz} ) and ${target}"
