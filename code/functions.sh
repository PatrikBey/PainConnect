#!/bin/bash
#
#
# # functions.sh
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
# This script contains processing functions for use within
# the ROI2ROI connectivity container.
#
#
# FUNCTIONS: 
# 1. get_roi_volume

#############################################
#                                           #
#            HELPER FUNCTIONS               #
#                                           #
#############################################



get_roi_volume() {
    # create parcellation image for given seed:target ROI combination
    # 
    # ${1}: filename of seed ROI
    # ${2}: filename of target ROI
    fslmaths ${2} \
        -mul 2 \
        ${TempDir}/tmp-parc.nii.gz
    fslmaths ${TempDir}/tmp-parc.nii.gz \
        -add ${1} \
        ${TempDir}/tmp-parc.nii.gz 2>/dev/null
}

get_tract_subset() {
    # extract subset of tracts using ROI mask
    # from default normative tractogram
    # $1 = ROI target full mask
    # $2 = base tractogram [optional]
    roi=$(basename ${1%_full_mask.nii.gz})
    wd=$( dirname ${1} )
    tckedit -force -quiet \
        ${2} \
        "${wd}/${roi}.tck" \
        -include ${1}
}

get_lookup_table() {
    # create look-up table for given set of ROIs
    # as integrated in connectivity matrix
    #
    # ${1}: path to ROI file set directory
    files="${1}/roi_masks/*.nii.gz"
    touch "${1}/LUT.txt"
    roi=1
    for f in ${files}; do
        roi_label=$( basename ${f%.nii.gz})
        echo "${roi}    ${roi_label}" >> ${1}/LUT.txt
        roi=$((roi + 1))
    done
}



get_binary_volume() {
    # create a binary volume combining all ROIs
    # for reduction of normative tractogram to 
    # reduce computational cost
    #
    # ${1}: Target ROIs
    # ---- create initial empty volume
    cp ${TEMPLATEDIR}/Empty.nii.gz \
    ${TempDir}/${1}_ribbon.nii.gz
    # ---- concatenate ROI masks
    files="${Path}/${1}/roi_masks/*.nii.gz"
    for f in $files; do
        fslmaths ${TempDir}/${1}_ribbon.nii.gz \
            -add ${f} \
            ${TempDir}/${1}_ribbon.nii.gz 2>/dev/null
    done
    # ---- binarize volume
    fslmaths ${TempDir}/${1}_ribbon.nii.gz \
        -bin \
        ${TempDir}/${1}_ribbon_bin.nii.gz
}

get_assignments() {
    # extract tract assignments for given ROI2ROI combination
    #
    # ${1}: seed ROI
    # ${2}: target ROI
    # ${3}: tractogram file to use in computation
    # ---- initialize directory
    if [ ! -d "${TempDir}/assignments" ]; then
        mkdir -p "${TempDir}/assignments"
    fi
    if [ ! -d "${TempDir}/weights" ]; then
        mkdir -p "${TempDir}/weights"
    fi
    # ---- get individual parcellation volume
    get_roi_volume ${1} ${2}
    # ---- compute connectome
    target_roi=$( basename ${2%.nii.gz})
    tck2connectome -force -zero_diagonal -quiet \
        "${3}" \
        "${TempDir}/tmp-parc.nii.gz" \
        "${TempDir}/weights/${target_roi}_weights.tsv" \
        -out_assignment "${TempDir}/assignments/${target_roi}.csv" 2>/dev/null
}

get_strength(){
    # extract connection strength for given ROI2ROI pairs
    #
    # ${1}: weight text files created by <get_assignments>
    read -a arr < ${1}
    export strength=$( echo ${arr[1]})
}


combine_weights() {
    # create concatenated connectivity matrix for all ROIs
    #
    # ${1}: input directory
    # ${2}: output filename
    weight_files="${1}/*.tsv"
    paste ${weight_files} > ${TempDir}/weights.tsv
    python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < ${TempDir}/weights.tsv > ${2}
}