#!/bin/bash
#
#
# # create_fraction_juellich_conn.sh
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
# * last update: 2024.09.20
#
#
#
# ## Description
#
# This script creates the parcellation volumes to compute 
# connectivity of the Area_Fraction_CC (AFC) masks with the residual Jülich brain atlas.
#
#
# STEPS:
# 1. check if Jülich volume exists, if not, combine all ROI masks.
# 2. create ROI connectome for all ROIs
#
# REQUIREMENTS: 
# 1. LeAPP structural processing container 
#    (or similar container for FSL & MRTRix based processing)
# 2. ROI nifti volume masks
#
#
# USAGE:
# 1. docker container call with mounted STUDYFOLDER
# example:
# docker run -it \
#    -v /STUDYFOLDER:/data \
#    leapp:processing bash
#
# --- expected input directory
#
# ./STUDYTFOLDER
#   -./Templats
#        -./Empty.nii.gz         | empty nifti volume with same MNI152 space orientation
#    -./cytoatlas-Juelich        | directory containg atlas files
#    -./AreaFractionCCMasks      | directory containing Area-Fraction-CC mask volumes
#    -./AreaFractionCCTract      | directory containing Area-Fraction-CC tract volumes 
#                                  [ if not present will be created during loop ]



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



# ---- Create Jüllich Atlas ---- #

if [ ! -f "${Path}/Templates/Juelich_parcellation.nii.gz" ]; then
    log_msg "UPDATE:    creating Jülich parcellation volume."
    Files="${Path}/cytoatlas-Juelich/regions_bin_clean/*.nii.gz"
        # ---- copy base image ---- #
    cp ${Path}/Templates/Empty.nii.gz \
        ${Path}/Templates/Juelich_parcellation.nii.gz
    for f in ${Files}; do
        fslmaths ${Path}/Templates/Juelich_parcellation.nii.gz \
        -add ${f} \
        ${Path}/Templates/Juelich_parcellation.nii.gz
    done

    # ---- snippets for overlap validation ---- #
    # fslmaths ${Path}/Templates/Juelich_parcellation.nii.gz \
    # -bin \
    # ${Path}/Templates/Juelich_parcellation_bin.nii.gz

    # fslmaths ${Path}/Templates/Juelich_parcellation.nii.gz \
    # -sub ${Path}/Templates/Juelich_parcellation_bin.nii.gz \
    # ${Path}/Templates/Juelich_remove_voxels.nii.gz

    # fslmaths ${Path}/Templates/Juelich_remove_voxels.nii.gz \
    # -binv \
    # ${Path}/Templates/Juelich_remove_voxels.nii.gz
    
    touch ${Path}/cytoAtlas-Juelich/LUT.txt

    if [ ! -d ${Path}/tmp ]; then
        mkdir -p ${Path}/tmp
    fi
    roi=1
    for f in ${Files}; do
        echo "${roi}    $(basename ${f%.nii.gz})" >> ${Path}/cytoAtlas-Juelich/LUT.txt
        fslmaths ${f} -mul $roi ${Path}/tmp/tmp.nii.gz
        fslmaths ${Path}/Templates/Juelich_parcellation.nii.gz \
        -add ${Path}/tmp/tmp.nii.gz \
        ${Path}/Templates/Juelich_parcellation.nii.gz
        echo "UPDATE:    adding ROI-${roi} $(basename ${f%.nii.gz})"
        roi=$((roi + 1))
    done
else
    log_msg "UPDATE:    using ${Path}/Templates/Juelich_parcellation.nii.gz"
fi




# ---- create corresponding Fraction-Juelich map ---- #

Files="${Path}/AreaFractionCCMasks/*.nii.gz"

if [ ! -d "${Path}/AreaFractionCCTracts" ]; then
    mkdir -p "${Path}/AreaFractionCCTracts"
    for f in ${Files}; do
        roi=$( basename ${f%.nii.gz})
        log_msg "UPDATE:    creating connectome for ${roi}"
        # ---- create tractogram subset ---- #
        tckedit -force -quiet -nthreads 20 \
            "${Path}/Templates/dTOR_full_tractogram.tck" \
            "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
            -include ${f}
    done
fi


for f in ${Files}; do
    roi=$( basename ${f%.nii.gz})

    log_msg "UPDATE:    creating connectome for ${roi}"
    # ---- create subset connectome ---- #
    tck2connectome -force -zero_diagonal -quiet \
        "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
        "${Path}/Templates/Juelich_parcellation.nii.gz" \
        "${Path}/Connectomes/Juelich_${roi}_weights.tsv"

done
