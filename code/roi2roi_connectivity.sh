#!/bin/bash
#
#
# # roi2roi_connectivity.sh
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
# * last update: 2024.10.10
#
#
#
# ## Description
#
# This script computes ROI wise dyadic connectivity strength based on the
# normative tractogram "dTOR" (Elias et al., Sci. Data, (2024)).
#
# Two processing modes exist:
#
# 1. Single Parcellation
#   If only a single set of ROIs is provided conenctivity is computed between each set of ROIs
#   of a single parcellation volume.
#   This approach is only valid if there are no overlaps between ROIs.
# 
# 2. Two parcellations
#   If two sets of ROIs are provided for each set of combination the connection strength
#   is computed iteratively.
#
#
# STEPS:
#
# 1. Create Reduced tractogram based on overlap with
#    target ROIs.
# 2. Loop over seed ROIs and target ROIs to create individual connectomes
#
#
#
# REQUIREMENTS: 
# 1. LeAPP structural processing container 
#    (or similar container for FSL & MRTRix based processing)
# 2. At least one set of binary ROI volume masks in MNI152 space.
#
#
# USAGE:
# 1. docker container call with mounted STUDYFOLDER
# example:
# docker run -it \
#    -v /STUDYFOLDER:/data \
#    leapp:processing bash
#
#
#
#
#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################

log_msg() {
    # print out text for logging
    # ${1}: string to print
    _message=$( echo ${1} | cut -d':' -f2 )
    echo -e "$(date) $(basename  -- "$0") : ${_message}"
}

get_temp_dir(){
# create temporary directory
    randID=$RANDOM
    export TempDir="${1}/temp-${randID}"
    mkdir ${TempDir}
}


progress_bar() {
    # print a progress bar during loops
    # ${1} current iteration of loop
    # ${2} total length of loop
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}


show_usage() {
	cat <<EOF

STRUCTURAL CONNECTIVITY FOR FUNCTIONAL NETWORKS OF PAIN

* author:       Patrik Bey
* last update:  2024/10/10

--- documentation ---

--- usage ---

docker run ...

--- variables ---

<<rois_seed>>   name of set of ROIs to use as initial ROIs for connectivity
                {required} | [represents rows in conenctivity matrix]

<<rois_target>> name of set of ROIs to use as secondary ROIs 
                for connectivity
                {optional} | [represents columns in connectivity matrix]

<<cleanup>>     boolean whether to remove temporary files
                {optional} | [default: True >> removing temp-directory]
--- input ---

expected input file structure:

/STUDYFOLDER
    |_rois_seed
        |_roi_masks
    |_rois_target
        |_roi_masks
    |_Templates
        |_dTOR_full_tractogram.nii.gz
        |_Empty.nii.gz


EOF
	# exit 1
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
    # ${1}: output filename
    weight_files="${TempDir}/*.tsv"
    paste ${weight_files} > ${TempDir}/weights.tsv
    python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < ${TempDir}/weights.tsv > ${1}
}

combine_weights() {
    # create concatenated connectivity matrix for all ROIs
    #
    # ${1}: output filename
    weight_files="${TempDir}/*.tsv"
    paste ${weight_files} > ${TempDir}/weights.tsv
    python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < ${TempDir}/weights.tsv > ${1}
}
    files="${1}/roi_masks/*.nii.gz"
    touch "${1}/LUT.txt"
    roi=1
    for f in ${files}; do
        roi_label=$( basename ${f%.nii.gz})
        echo "${roi}    ${roi_label}" >> ${1}/LUT.txt
        roi=$((roi + 1))
    done



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

if [ -z ${rois_seed} ]; then
    log_msg "ERROR:    no initial set of ROIs <<rois_seed>> defined."
    show_usage
fi

if [ -z ${rois_target} ]; then
    log_msg "UPDATE:    using full set of ROIs for connectivity."
    roi_mode="full"
else
    log_msg "UPDATE:    computing ROI2ROI connectivity for seed and target list."
    roi_mode="single"
fi

if [ -z ${cleanup} ]; then
    log_msg "UPDATE:    no <<cleanup>> variable defined, using default True."
    cleanup="true"
fi
#############################################
#                                           #
#          PERFORM COMPUTATIONS             #
#                                           #
#############################################

# ---- initialize workspace
get_temp_dir ${Path}

if [ ! -f "${Path}/${rois_seed}/LUT.txt" ]; then
    log_msg "UPDATE:    compute look-up table for ${rois_seed}"
    get_lookup_table /data/${rois_seed}
fi

# ---- compute individual ROI 2 ROI connectivity ---- #
if [ ${roi_mode,,} = "single" ]; then
    # ---- create target ROI list meta data
    if [ ! -f "${Path}/${rois_target}/LUT.txt" ]; then
        log_msg "UPDATE:    compute look-up table for ${rois_target}"
        get_lookup_table /data/${rois_target}
    fi

    # ---- create binary mask of all target ROIs ---- #

    log_msg "UPDATE:    create target ROIs binary mask for tract reduction."
    get_binary_volume ${rois_target}

    # ---- reduced normative tractogram ---- #

    log_msg "UPDATE:    extracting target ROI tract subset."
    get_tract_subset ${TempDir}/${rois_target}_ribbon_bin.nii.gz


    # ---- compute individual connectomes for ROIs ---- #

    # ---- prepare looping variables
    rois_seed_list="${Path}/${rois_seed}/roi_masks/*.nii.gz"
    rois_target_list="${Path}/${rois_target}/roi_masks/*.nii.gz"

    # --- loop over all ROI 2 ROI pairings
    for seed in ${rois_seed_list}; do
        log_msg "UPDATE:    extract connectivity for seed ROI $( basename ${seed%.nii.gz})"
        touch ${TempDir}/$( basename ${seed%.nii.gz})_weights.tsv
        for target in ${rois_target_list}; do
            get_assignments "${seed}" "${target}" "${TempDir}/${rois_target}.tck"
            get_strength ${TempDir}/weights/$( basename ${target%.nii.gz}_weights.tsv)
            echo ${strength} >> ${TempDir}/$( basename ${seed%.nii.gz})_weights.tsv
        done
    done

    # ---- combine weights of all ROI 2 ROI pairings
    combine_weights ${Path}/Connectomes/${rois_seed}_${rois_target}_weights.tsv
fi



#######    DEVELOPMENT ADD ROI COLUMN / ROWNAMES
# combine_weights() {
#     # create concatenated connectivity matrix for all ROIs
#     #
#     # ${1}: output filename
#     weight_files="${TempDir}/*.tsv"
#     paste ${rois_target}/LUT.txt ${weight_files} > ${TempDir}/weights.tsv
#     python -c "import sys; print('\n'.join(' '.join(c) for c in zip(*(l.split() for l in sys.stdin.readlines() if l.strip()))))" < ${TempDir}/weights.tsv > ${TempDir}/weights2.tsv
#     paste ${rois_seed}/LUT.txt ${TempDir}/weights2.tsv > ${Path}/Connectomes/${rois_seed}_${rois_target}_weights.tsv
# }


# elif [ ${roi_mode,,} = "full" ]; then
#     log_msg "LASDLALSDAOFAMSDLAMSDK"
# else
#     log_msg "ERROR:    <<roi_mode>> not understood."
#     show_usage

# ---- clean up of interim results in temporary directory
if [ ${cleanup,,} = "true" ];
    rm -r ${TempDir}
fi

