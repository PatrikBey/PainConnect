#!/bin/bash
#
#
# # create_fraction_juellich_maps.sh
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
# To this end the AFC is integrated into the existing Jülich atlas, replacing 
# overlapping ROIs of the latter. The resulting parcellation volume is then used
# to compute connectivty of the reduced streamlines passing through the corresponding
# AFC ROI.
#
#
# STEPS:
# 1. check if Jülich volume exists, if not, combine all ROI masks.
# 2.1 create ROI tract subset
# 2.2 create ROI connectome
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



# ---- Create Jüllich Atlas ---- #

if [ ! -f "${Path}/Templates/Juelich_parcellation.nii.gz" ]; then
    log_msg "UPDATE:    creating Jülich parcellation volume."
    Files="${Path}/cytoatlas-Juelich/regions_bin_clean/*.nii.gz"
        # ---- copy base image ---- #
    cp /data/Templates/Empty.nii.gz \
        /data/Templates/Juelich_parcellation.nii.gz
    for f in ${Files}; do
        fslmaths /data/Templates/Juelich_parcellation.nii.gz \
        -add ${f} \
        /data/Templates/Juelich_parcellation.nii.gz
    done

    fslmaths /data/Templates/Juelich_parcellation.nii.gz \
    -bin \
    /data/Templates/Juelich_parcellation_bin.nii.gz

    fslmaths /data/Templates/Juelich_parcellation.nii.gz \
    -sub /data/Templates/Juelich_parcellation_bin.nii.gz \
    /data/Templates/Juelich_remove_voxels.nii.gz

    fslmaths /data/Templates/Juelich_remove_voxels.nii.gz \
    -binv \
    /data/Templates/Juelich_remove_voxels.nii.gz
    
    touch /data/cytoAtlas-Juelich/LUT.txt

    roi=1
    for f in ${Files}; do
        echo "${roi}    $(basename ${f%.nii.gz})" >> /data/cytoAtlas-Juelich/LUT.txt
        fslmaths ${f} -mul $roi /data/tmp/tmp.nii.gz
        fslmaths /data/Templates/Juelich_parcellation.nii.gz \
        -add /data/tmp/tmp.nii.gz \
        /data/Templates/Juelich_parcellation.nii.gz
        echo "UPDATE:    adding ROI-${roi} $(basename ${f%.nii.gz})"
        roi=$((roi + 1))
    done
else
    log_msg "UPDATE:    using /data/Templates/Juelich_parcellation.nii.gz"
fi




# ---- create corresponding Fraction-Juelich map ---- #

if [ ! -d "${Path}/AreaFractionCCTracts" ]; then
    mkdir -p "${Path}/AreaFractionCCTracts"
fi



Files="${Path}/AreaFractionCCMasks/*.nii.gz"


for f in ${Files}; do
    roi=$( basename ${f%.nii.gz})

    log_msg "UPDATE:    creating connectome for ${roi}"
    # ---- create tractogram subset ---- #
    tckedit -force -quiet -nthreads 20 \
        "${Path}/Templates/dTOR_full_tractogram.tck" \
        "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
        -include ${f}

    # ---- create subset connectome ---- #
    tck2connectome -force -zero_diagonal -quiet \
        "${Path}/AreaFractionCCTracts/${roi}_tract.tck" \
        "${Path}/Templates/Juelich_parcellation.nii.gz" \
        "${Path}/Connectomes/Juelich_${roi}_weights.tsv"

done
