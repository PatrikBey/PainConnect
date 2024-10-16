
#### PRCESSING PLAN

# (1) Zeile Area-Fraction / Spalte alle Area-Fractions
# (2) Zeile Area-Fraction / Spalte Jülich-Atlas ROIs {100x280:500h}
# (3) Zeile Area-Fraction / Spalte Morel-Atlas ROIs
# (4) Zeile Area-Fraction / Spalte AAN ROIs           [done]
# (5) Zeile Area-Fraction / Spalte BN ROIs
# (6) Zeile BrainstemNavigator / Spalte Morel-Atlas



# Priorities:
# (3): Done
# (5): Done
# (1)
# (6)
# (2)
# (4): Done


; docker run \
;     -v ${PWD}:/code \
;     -v /mnt/h/Research/PainConn/Data:/data \
;     -e rois_seed="AreaFractionCC" \
;     -e rois_target="Harvard-AAN" \
;     leapp:proc.dev \
;     bash /code/roi2roi_connectivity.sh




# (2)
### -e rois_target="cytoatlas-Juelich" \ ###
#
#     WARNING: The requested image's platform (linux/amd64) does not match the detected host platform (linux/arm64/v8) and no specific platform was requested
# Fri Oct 11 10:55:53 UTC 2024 roi2roi_connectivity.sh :  computing ROI2ROI connectivity for seed and target list.
# Fri Oct 11 10:55:53 UTC 2024 roi2roi_connectivity.sh :  no <<cleanup>> variable defined, using default True.
# Fri Oct 11 10:55:53 UTC 2024 roi2roi_connectivity.sh :  compute look-up table for cytoatlas-Juelich
# Fri Oct 11 10:55:57 UTC 2024 roi2roi_connectivity.sh :  create target ROIs binary mask for tract reduction.
# Fri Oct 11 10:58:55 UTC 2024 roi2roi_connectivity.sh :  extracting target ROI tract subset.
# tckedit: /opt/matlabmcr-2016b/v91/bin/glnxa64/libtiff.so.5: no version information available (required by /opt/mrtrix3/bin/../lib/libmrtrix.so)
# Fri Oct 11 11:01:56 UTC 2024 roi2roi_connectivity.sh :  extract connectivity for seed ROI left-neg04-GS-Area-5M-SPL-54
# Fri Oct 11 15:52:05 UTC 2024 roi2roi_connectivity.sh :  extract connectivity for seed ROI left-neg04-GS-Area-6d2-PreCG-24
# Fri Oct 11 20:45:29 UTC 2024 roi2roi_connectivity.sh :  extract connectivity for seed ROI left-neg04-GS-Area-OP1-POperc-59
# Sat Oct 12 01:37:48 UTC 2024 roi2roi_connectivity.sh :  extract connectivity for seed ROI left-neg04-GS-Area-OP4-POperc-62
# Sat Oct 12 06:28:45 UTC 2024 roi2roi_connectivity.sh :  extract connectivity for seed ROI left-neg04-GS-Area-PF-IPL-39






################
# DEVELOPMENT
################

docker run \
    -v /mnt/h/Research/PainConn/Data:/data \
    -e seed="seed/roi_masks/left-neg04-GS-Area-5M-SPL-54.nii.gz" \
    -e target="target" \
    roi2roi


seed="seed/roi_masks/left-neg04-GS-Area-5M-SPL-54.nii.gz"

# seed="seed/roi_masks/left-neg04-GS-Area-5M-SPL-54.nii.gz"
 # seed="seed"
 # target="target"



# ---- preparing singularity image from docker for cluster usage ---- #

# docker save --output roi2roi.tar roi2roi
# singularity build roi2roi.sif docker-archive://roi2roi.tar

# sftp beyp_c@hpc-transfer-1.cubi.bihealth.org
# cd /data/cephfs-1/home/users/beyp_c/work/projects/PainConnect
# put roi2roi.sif


################
# CLUSTER USAGE
################

ssh -A -t -l beyp_c hpc-login-1.cubi.bihealth.org
srun --partition medium --pty bash -i

Path=${HOME}/work/projects/PainConnect


Date=$(date '+%Y-%m-%d')
LogDir=${Path}/Log-${Date}
mkdir -p ${LogDir}


# ---- full brain ROI based connectivity extraction ---- #

Seed="BrainstemNavigator"
Target="MorelAtlasMNI152"

sbatch --ntasks=20 --mem-per-cpu=4G --job-name=BN-Mor --partition=medium \
    -o "${LogDir}/out_${Seed}-${Target}.txt" -e "${LogDir}/err_${Seed}-${Target}.txt" \
    container/cluster_wrapper.sh \
        -d "${Path}/data" \
        -s "${Seed}" \
        -t "${Target}"



# ---- parallel single ROI based connectivity extraction ---- #


Target="cytoatlas-Juelich"
Seed="AreaFractionCC"
cd $Path/data
SeedROIS="${Seed}/roi_masks/*.nii.gz"


for sroi in ${SeedROIS}; do
    sbatch --ntasks=10 --mem-per-cpu=4G --job-name=single --partition=medium \
        -o "${LogDir}/out_$( basename ${sroi%.nii.gz})-${Target}.txt" -e "${LogDir}/err_$( basename ${sroi%.nii.gz})-${Target}.txt" \
        Code/cluster_wrapper.sh \
            -d "${Path}/data" \
            -s "${sroi}" \
            -t "${Target}"
done

