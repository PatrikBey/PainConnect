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
# 1. LeAPP structural processing container
# 2. Template connectome .tck file
# 3. ROI nifti volume mask(s)

#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################


show_usage() {
	cat <<EOF

***     ROI BASED TRACTOGRAM CREATION     ***

    Wrapper script for use with docker container call
    such as LeAPP processing container (1.)


# USAGE

docker run \
    -v /STUDYFOLDER:/data \
    -e Mask="ROI-MASK-1-FILENAME"
    -e Template="TEMPLATE-TRACTOGRAM-FILENAME" \
    get_tracts.sh

#-- input variables --#
    -e Mask [required]      string; comma seperated if multiple nifti volumes provided
    -e Template [optional]  string; filename of template .tck file. if not provided default
                            dTOR_full_tractogram.tck will be used (2.)



# References
(1.) Bey et al., (2024), https://doi.org/10.1002/hbm.26701
(2.) Elias et al., (2024), https://doi.org/10.6084/m9.figshare.c.6844890.v1

EOF
	exit 1
}




contains() {
    if [[ ${1} == *","* ]]; then
        echo true
    fi
}

get_count() {
    # extract tract count from given .tck file
    tck_info=$( tckinfo ${1})
    info_split=(${tck_info//" "/ })
    echo ${info_split[18]}
}



#############################################
#                                           #
#            CHECK INPUT                    #
#                                           #
#############################################

#-------loading I/O & logging functionality-------#
source ${HCPPIPEDIR}/global/scripts/log.shlib  # Logging related functions

if [[ ! -d "/data" ]]; then
    log_Msg "ERROR:    no <</data>> directory mounted into container."
    show_usage
fi

if [[ -z ${Mask} ]]; then
    log_Msg "ERROR:    no <<Mask>> variable defined."
    show_usage
fi

if [[ -z ${OutDir} ]]; then
    log_Msg "UPDATE:    no output directory <<OutDir>> defined. USing default '/data/tracts'."
    OutDir="/data/tracts"
fi

if [[ -z ${Template} ]]; then
    log_Msg "UPDATE:    no <<Template>> defined. Using default tractogram '/data/Templates/dTOR_full_tractogram.tck'"
    Template="/data/Templates/dTOR_full_tractogram.tck"
fi

# ---- check if mutliple ROI masks provided ---- #
MultiMask=$( contains ${mask} )




########### DEVELOPMENT ############
Template="/data/Templates/testing.tck"
MNI="/data/Templates/MNI152_T1_1mm.nii.gz"
Mask="/data/AreaFractionCCMasks/left-neg04-GS-Area-5M-SPL-54.nii.gz"
ROI1="/data/AreaFractionCCMasks/left-neg04-GS-Area-5M-SPL-54.nii.gz"
# ROI2="/data/AreaFractionCCMasks/left-neg04-IC-Area-5L-SPL-53.nii.gz"
ROI2="/data/AreaFractionCCMasks/left-pos04-IC-Area-Id2-Insula-72.nii.gz"
# ROI2="/data/AreaFractionCCMasks/left-neg04-IC-Area-5M-SPL-54.nii.gz"
# ---- check if output directory exists ---- #

if [[ ! -d ${OutDir} ]]; then
    mkdir -p ${OutDir}
    mkdir -p ${OutDir}/exclusion
fi

# ---- split single vs multi ROI processing ---- #
if [[ ${MultiMask} ]]; then
    log_Msg "UPDATE:    running multiple ROI extraction."
    OutFile="${OutDir}/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz}).tck"
else
    log_Msg "UPDATE:    running single ROI tract extractions"
    OutFile="${OutDir}/$( basename ${Mask%.nii.gz}).tck"
fi



tckedit -force -quiet \
    ${Template} \
    ${OutFile} \
    -include ${Mask}


# ---- MULTI ROI TRACTOGRAPHY ---- #

OutFile="${OutDir}/$( basename ${ROI1%.nii.gz}).tck"
tckedit -force \
    ${Template} \
    ${OutFile} \
    -include ${ROI1}

OutFile="${OutDir}/$( basename ${ROI2%.nii.gz}).tck"
tckedit -force \
    ${Template} \
    ${OutFile} \
    -include ${ROI2}

tckedit "${OutDir}/$( basename ${ROI1%.nii.gz}).tck" \
    "${OutDir}/$( basename ${ROI2%.nii.gz}).tck" \
    "${OutDir}/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz}).tck"

tckedit "${OutDir}/$( basename ${ROI1%.nii.gz}).tck" \
    "${OutDir}/$( basename ${ROI2%.nii.gz}).tck" \
    "${OutDir}/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz})_include_ends.tck" \
    -include ${ROI1} \
    -include ${ROI2} \
    -ends_only

tckedit -force \
    ${Template} \
    "${OutDir}/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz})_include_ends.tck" \
    -include ${ROI1} \
    -include ${ROI2} \
    -ends_only

tckedit -force \
    ${Template} \
    "${OutDir}/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz})_include_order.tck" \
    -include_ordered ${ROI1} \
    -include_ordered ${ROI2}



# ---- create exclusion mask ---- #
# fslmaths ${ROI1} \
#     -add ${ROI2} \
#     /data/tracts/exclusion/tmp.nii.gz

# fslmaths /data/Templates/Binary.nii.gz \
#     -sub /data/tracts/exclusion/tmp.nii.gz \
#     /data/tracts/exclusion/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz}).nii.gz

# fslmaths /data/Templates/MNI152_T1_1mm.nii.gz \
#     -sub ${ROI1} \
#     /data/tracts/exclusion/$( basename ${ROI1})


# tckedit -force \
#     ${Template} \
#     ${OutFile} \
#     -include ${ROI1} \
#     -include ${ROI2} \
#     -exclude /data/tracts/exclusion/$( basename ${ROI1%.nii.gz})-$( basename ${ROI2%.nii.gz}).nii.gz



fslmaths $MNI \
-bin \
/data/Templates/Binary.nii.gz


-mul ${ROI1%.nii.gz}_reoriented.nii.gz \
/data/test2.nii.gz