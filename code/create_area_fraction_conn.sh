#!/bin/bash
#
#
# # create_area_fraction_conn.sh
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
# * last update: 2024.09.09
#
#
#
# ## Description
#
# This script creates a single atlas image volume combining
# all ROIs from "AreaFractionCCMasks" for use as parcellation image in
# connectome creation
#
# STEPS:
# 1. create LUT for ROI parcellation values
#
# REQUIREMENTS: 
# 1. LeAPP structural processing container
# 2. ROI nifti volume masks

#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################

Path=/data/AreaFractionCCMasks
Files="${Path}/*.nii.gz"

# ---- create empty base image ---- #
fslmaths "${Path}/left-neg04-GS-Area-5M-SPL-54.nii.gz" \
    -sub "${Path}/left-neg04-GS-Area-5M-SPL-54.nii.gz" \
    "/data/Templates/Empty.nii.gz"

# ---- copy base image ---- #
cp /data/Templates/Empty.nii.gz \
    /data/Templates/Area-Fractions-CC_parcellation.nii.gz

# ---- initialize Look-Up Table ---- #
touch /data/AreaFractionCCMasks/LUT.txt

roi=1
for f in ${Files}; do
    echo "${roi}    $(basename ${f%.nii.gz})" >> /data/AreaFractionCCMasks/LUT.txt
    fslmaths ${f} -mul $roi /data/tmp/tmp.nii.gz
    fslmaths /data/Templates/Area-Fractions-CC_parcellation.nii.gz \
    -add /data/tmp/tmp.nii.gz \
    /data/Templates/Area-Fractions-CC_parcellation.nii.gz
    roi=$((roi + 1))
    echo "UPDATE:    adding ROI-${roi} $(basename ${f%.nii.gz})"
done


fslmaths /data/Templates/Area-Fractions-CC_parcellation.nii.gz \
    -mul /data/tmp/remove_voxels.nii.gz \
    /data/Templates/Area-Fractions-CC_parcellation.nii.gz
# fslmaths /data/Templates/Area-Fractions-CC_parcellation.nii.gz \
#     -sub /data/Templates/Area-Fractions-CC_parcellation_bin.nii.gz \
#     -binv \
#     /data/tmp/remove_voxels.nii.gz





tck2connectome -force -zero_diagonal \
        "/data/Templates/dTOR_full_tractogram.tck" \
        /data/Templates/Area-Fractions-CC_parcellation.nii.gz \
        "/data/Connectomes/AreaFractionsCC_weights.tsv"

tck2connectome -force -zero_diagonal -scale_length -stat_edge mean \
        "/data/Templates/dTOR_full_tractogram.tck" \
        /data/Templates/Area-Fractions-CC_parcellation.nii.gz \
        "/data/Connectomes/AreaFractionsCC_lengths.tsv"
