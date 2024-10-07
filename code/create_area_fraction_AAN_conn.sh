#!/bin/bash
#
#
# # create_fraction_AAN_conn.sh
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
# * last update: 2024.10.07
#
#
#
# ## Description
#
# This script creates the parcellation volumes to compute 
# connectivity of the Area_Fraction_CC (AFC) masks with the AAN subcortical atlas.
#
#
# STEPS:
# 1. check if AAN volume exists, if not, combine all ROI masks.
# 2. create ROI connectome for all ROIs
#
# REQUIREMENTS: 
# 1. LeAPP structural processing container 
#    (or similar container for FSL & MRTRix based processing)
# 2. ROI nifti volume masks

#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################

log_msg() {
    # print out text for logging
    _message=$( echo ${1} | cut -d':' -f2 )
    echo -e "$(date) $(basename  -- "$0") : ${_message}"
}


#############################################
#                                           #
#              CHECK INPUT                  #
#                                           #
#############################################

if [ -z ${Path} ]; then
    if [ ! -d /data ]; then
        log_msg "ERROR:    no <</data>> directory provided."
    fi
    Path='/data'
fi

Atlas="Harvard-AAN"

# ---- Create Jüllich Atlas ---- #

if [ ! -f "${Path}/Templates/${Atlas}_parcellation.nii.gz" ]; then
    log_msg "UPDATE:    creating ${Atlas} parcellation volume."
    Files="${Path}/${Atlas}/roi_masks/*.nii.gz"
        # ---- copy base image ---- #
    cp /data/Templates/Empty.nii.gz \
        /data/Templates/${Atlas}_parcellation.nii.gz
    # DEV: Visual Control for overlapping ROIs
    # for f in ${Files}; do
    #     fslmaths ${Path}/Templates/${Atlas}_parcellation.nii.gz \
    #     -add ${f} \
    #     ${Path}/Templates/${Atlas}_parcellation.nii.gz
    # done
    # fslmaths /data/Templates/Juelich_parcellation.nii.gz \
    # -bin \
    # /data/Templates/Juelich_parcellation_bin.nii.gz

    # fslmaths /data/Templates/Juelich_parcellation.nii.gz \
    # -sub /data/Templates/Juelich_parcellation_bin.nii.gz \
    # /data/Templates/Juelich_remove_voxels.nii.gz

    # fslmaths /data/Templates/Juelich_remove_voxels.nii.gz \
    # -binv \
    # /data/Templates/Juelich_remove_voxels.nii.gz
    ### DEV: End
    
    touch ${Path}/${Atlas}/LUT.txt

    roi=1
    for f in ${Files}; do
        echo "${roi}    $(basename ${f%.nii.gz})" >> ${Path}/${Atlas}/LUT.txt
        fslmaths ${f} -mul $roi /data/tmp/tmp.nii.gz
        fslmaths ${Path}/Templates/${Atlas}_parcellation.nii.gz \
        -add /data/tmp/tmp.nii.gz \
        /data/Templates/${Atlas}_parcellation.nii.gz
        echo "UPDATE:    adding ROI-${roi} $(basename ${f%.nii.gz})"
        roi=$((roi + 1))
    done
else
    log_msg "UPDATE:    using /data/Templates/${Atlas}_parcellation.nii.gz"
fi




# ---- create corresponding Fraction-Juelich map ---- #

if [ ! -d "${Path}/AreaFractionCCTracts" ]; then
    mkdir -p "${Path}/AreaFractionCCTracts"
fi



Files="${Path}/AreaFractionCCMasks/*.nii.gz"


for f in ${Files}; do
    roi=$( basename ${f%.nii.gz})

    log_msg "UPDATE:    creating connectome for ${roi}"

    # ---- create subset connectome ---- #
    tck2connectome -force -zero_diagonal -quiet \
        "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
        "${Path}/Templates/${Atlas}_parcellation.nii.gz" \
        "${Path}/Connectomes/${Atlas}_${roi}_weights.tsv"

done

tck2connectome -force -zero_diagonal \
    "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
    "${Path}/Templates/${Atlas}_parcellation.nii.gz" \
    "${Path}/Connectomes/${Atlas}_${roi}_weights.tsv"