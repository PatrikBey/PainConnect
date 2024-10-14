#!/bin/bash
#
#
# # create_fraction_conn.sh
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
# * last update: 2024.10.09
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


show_usage() {
	cat <<EOF

STRUCTURAL CONNECTIVITY OF FUNCTIONAL PAIN NETWORKS

* author:       Patrik Bey
* last update:  2024/10.09

--- documentation ---
This script performs extraction of functional ROI based white
matter conenctivity with existing Atlas parcellations in MNI152 space.
The normative white matter tractogram is taken from (Elias et al., Sci. Dat., (2024)).


--- requirements ---
This script requires both FSL and MRtrix3 functionality. Recommended usage
is via docker containers as defined in Bey et al., HBM, (2024).

--- input data structure ---

/"STUDYFOLDER"
    /Templates
        - dTOR_full_tractogram.tck
        - ${"ATLASNAME"}_parcellation.nii.gz [optional]
    /AreaFractionCCMasks
        - "ROI_1_mask".nii.gz
        - ...
    /"ATLASNAME"
        -roi_masks [optional]

--- usage ---
docker run \
    -v /STUDYFOLDER:/data \
    -e atlas="ATLASNAME" \
    -r roi_mode="single" \               [optional]
    -e outdir="/data/OUTPUTFOLDERNAME" \ [optional]
    -e tck="TRACTOGRAMNAME" \            [optional]
    leapp:processing \
    create_fraction_conn.sh


--- variables ---

<<atlas>>       name of atlas to use to extract connectivity 
                based on AreaFractionCC subset.
<<roi_mode>>    approach to extract connectivity:
                single: each ROI mask is computed individually, allowing
                        for overlap in ROIs
                full: conenctivity is computed based on parcellation image,
                        requires distinct ROIs.
<<outdir>>      output directory name to be used.
<<tck>>         tractogram filename if not using default:
                dTOIR_full_tractogram.tck from Elias et al. (2024)
EOF
	# exit 1
}

get_tract_subset() {
    # extract subset of tracts using ROI mask
    # from default normative tractogram
    # $1 = ROI mask
    # $2 = base tractogram [optional]
    if [ -z ${2} ]; then
        tck="${Path}/Templates/dTOR_full_tractogram.tck"
    else
        tck=${2}
    fi
    roi=$(basename ${1%.nii.gz})
    tckedit -force -quiet \
        ${tck} \
        "${Path}/AreaFractionCCTracts/${roi}_tracts.tck" \
        -include ${1}
}

#############################################
#                                           #
#              CHECK INPUT                  #
#                                           #
#############################################

if [ -z ${Path} ]; then
    if [ ! -d /data ]; then
        log_msg "ERROR:    no <</data>> directory provided."
        show_usage
    fi
    Path='/data'
fi

if [ ! -d "${Path}/AreaFractionCCMasks" ]; then
    log_msg "ERROR:    no AreaFractionCCMasks directory found in ${Path}."
    show_usage
fi

if [ -z ${atlas} ]; then
    log_msg "ERROR:    no <<atlas>> variable defined."
    show_usage
else
    if [ ! -d ${Path}/${atlas} ]; then
        log_msg "ERROR:    no ${atlas} directory found."
        show_usage
    fi
    if [ ! -f "${Path}/Templates/${atlas}_parcellation.nii.gz" ]; then
        log_msg "UPDATE:    no ${atlas} parcellation found. Using roi masks to create it."
        if [ ! -d "${Path}/${atlas}/roi_masks" ]; then
            log_msg "ERROR:    no roi_masks directory given for ${atlas}."
            show_usage
        fi
    fi
fi

if [ -z ${roi_mode} ]; then
    roi_mode="full"
fi
if [ ${roi_mode,,}=="full" ]; then
    log_msg "UPDATE:    computing connectivity using full parcellation volume."
else
    log_msg "UPDATE:    computing connectivity using individual ROI masks."
fi

#############################################
#                                           #
#              CHECK TRACTS                 #
#                                           #
#############################################

# ---- check if tract subsets for AreaFractionCC ROIs has been 
# ---- previously created 

# if [ ! -d "${Path}/AreaFractionCCTracts" ]; then
#     log_msg "UPDATE:    START extracting ROI based tract subsets."
#     mkdir -p "${Path}/AreaFractionCCTracts"
#     Masks=${Path}/AreaFractionCCMasks/*nii.gz
#     for m in ${Masks}; do
#         roi=$( basename ${m%.nii.gz})
#         log_msg "UPDATE:    extracting tract subset for ${roi}"
#         get_tract_subset ${m}
#     done
#     log_msg "UPDATE:    FINIHSED extracting ROI based tract subsets/"
# else
#     log_msg "UPDATE:    AreaFraction tract subsets found."
# fi

# if [ ${roi_mode,,}="full" ]; then
# # ---- check if atlas parcellation exists
#     if [ ! -f "${Path}/Templates/${atlas}_parcellation.nii.gz" ]; then
#         log_msg "UPDATE:    creating ${atlas} parcellation image from masks."
#     fi
#     masks="${Path}/${atlas}/roi_masks/*.nii.gz"
#     # --- initialize look-up table
#     touch ${Path}/${atlas}/LUT.txt
#     # --- create temporary directory
#     if [ ! -d ${Path}/tmp ]; then
#         mkdir -p ${Path}/tmp
#     fi
#     cp "${Path}/Templates/Empty.nii.gz" "${Path}/tmp/${atlas}_parcellation.nii.gz"
#     # --- check for overlaps
#     for m in ${masks}; do
#         fslmaths ${Path}/tmp/${atlas}_bin_check.nii.gz \
#             -add ${m} \
#             ${Path}/tmp/${atlas}_bin_check.nii.gz
#     done
#     overlap=$( fslstats ${Path}/tmp/${atlas}_bin_check.nii.gz -R )
#     log_msg "WARNING:    the"
#     # --- combine all ROI masks
#     roi=1
#     for m in ${masks}; do
#         roi_label=$( basename ${m%.nii.gz})
#         echo "${roi}    ${roi_label}" >> ${Path}/${atlas}/LUT.txt
#         fslmaths ${m} -mul $roi ${Path}/tmp/tmp.nii.gz
#         fslmaths ${Path}/tmp/${atlas}_parcellation.nii.gz \
#             -add ${Path}/tmp/tmp.nii.gz \
#             ${Path}/tmp/${atlas}_parcellation.nii.gz 
#         log_msg "UPDATE:    added ROI-${roi} ${roi_label}."
#         roi=$((roi + 1))
#     done

    




get_tract_subset() {
    # extract subset of tracts using ROI mask
    # from default normative tractogram
    # $1 = ROI mask
    # $2 = base tractogram [optional]
    if [ -z ${2} ]; then
        tck="${Path}/Templates/dTOR_full_tractogram.tck"
    else
        tck=${2}
    fi
    roi=$(basename ${1%_ribbon_bin.nii.gz})
    tckedit -force -quiet \
        ${tck} \
        "${TempDir}/${roi}.tck" \
        -include ${1}
}


##########
# DEV

# --- create mask based parcellation


fslmaths ${Path}/BrainstemNavigator/roi_masks/CLi_RLi.nii.gz \
-mul 2 \
${Path}/new_roi.nii.gz

fslmaths ${m} \
    -add ${Path}/new_roi.nii.gz \
    ${Path}/test_parc.nii.gz

tck2connectome -force -zero_diagonal \
    "${Path}/Templates/dTOR_full_tractogram.tck" \
    ${Path}/test_parc.nii.gz \
    ${Path}/CLi_RLi_weights.tsv \
    -out_assignment ${Path}/assignments_CLi_RLi.csv


connectome2tck "${Path}/Templates/dTOR_full_tractogram.tck" ${Path}/assignments_CLi_RLi.csv ${Path}/tracks_1_2.tck -nodes 1,2 -exclusive -files single

# Validate via larger ROIs