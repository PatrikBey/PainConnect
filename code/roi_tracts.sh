#!/bin/bash
#
#
# # roi_tracts.sh
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
# This script extractes ROI based tractograms from the template normative connectome (1) using two ROI volume masks.
#
# * steps within this script:
# * 1. subsetting existing Tractogram (from DWITractogram.sh)
#
# REQUIREMENTS: 
# 1. LeAPP structural processing container
# 2. Template connectome .tck file
# 3. ROI nifti volume masks

#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################



# parsing arguments
Path=`getopt1 "--path" $@`  # "$1" directory path containing all subjects
Subject=`getopt1 "--subject" $@`  # "$2" subject ID (e.g. 0001)
Session=`getopt1 "--session" $@`  # "$3" session ID (e.g. 01)
ParcName=`getopt1 "--parcname" $@`  # "$4" name of parcellation to be used in tractography default is HCP DK atlas
ROIS=`getopt1 "--rois" $@` # "$5" ROIs used for subsetting tractogram.
Streams=`getopt1 "--streams" $@` # "$6" number of streams to create during tractography

if [[ -z ${ParcName} ]]; then
    # check if parcellation name defined, else use default HCP-MMP1 (Glasser et al. 2016)
    log_Msg "UPDATE:    Using >>HCP-MMP1<< brain parcellation as default to create connectomes."
    ParcName="HCPMMP1"
fi

#######################
# perform computations
#######################

log_Msg "START: Performing ROI based connectome creationg for ${Subject}"


# ---- specificy ROI mask ---- #

# ---- check if ROIs is a given file ---- #

if [[ "${ROIS,,}" = "lesion" ]]; then
    log_Msg "UPDATE:    using lesion mask as ROI seed for connectome extraction."
    ROIImage="${Path}/${Subject}/${Session}/lesion/T1w_acpc_dc_restore_mask.nii.gz"
    if [[ ! -f "${ROIImage}" ]]; then
        log_Msg "ERROR:    can't find lesion mask in /lesion/directory. Please run structural processing first."
    fi
elif [[ -f "${Path}/${Subject}/${Session}/parcellation/${Subject}_ROI-${ROIS}-mask.nii.gz" ]]; then
    log_Msg "UPDATE:    using ${Subject}_ROI-${ROIS}-mask.nii.gz as ROI seed."
    ROIImage="${Path}/${Subject}/${Session}/parcellation/${Subject}_ROI-${ROIS}-mask.nii.gz"
elif [[ $ROIS == *,* ]]; then
    python ${LEAPP_DWIDIR}/Scripts/GetROIMask.py \
        --rois="${ROIS}" \
        --parcellation="${Path}/${Subject}/${Session}/parcellation/${Subject}_${ParcName}_resample.nii.gz" \
        --lut="${LEAPP_TEMPLATES}/${ParcName}_LUT_mrtrix.txt"
    ROIImage="${Path}/${Subject}/${Session}/parcellation/${Subject}_ROI-${ROIS}-mask.nii.gz"

else
    log_Msg "ERROR:    Can not find ROIs to use for tractogram extraction."
    show_usage
    exit 1
fi


##################### 
# TO DO: add tractography subsetting
# 

log_Msg "START:    Extracting tractogram subset."
tckedit -force -quiet \
    ${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_${Streams}*.tck  \
    ${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_${ROIS}.tck \
    -include ${ROIImage}

log_Msg "FINISHED:    Extracting tractogram subset."


log_Msg "START:    Computing tractogram subset based connectome."

tck2connectome -force -quiet \
        "${Path}/${Subject}/${Session}/dwi_preprocessed/${Subject}_${ROIS}.tck" \
        "${Path}/${Subject}/${Session}/parcellation/${Subject}_${ParcName}_resample.nii.gz" \
        "${Path}/${Subject}/${Session}/connectome/${Subject}_${ROIS}_connectome.tsv"

log_Msg "FINISHED:    Computing tractogram subset based connectome."

log_Msg "FINISHED: Performing ROI based connectome creationg for ${Subject}"

