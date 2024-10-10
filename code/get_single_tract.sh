

AFC="left-neg04-GS-Area-5M-SPL-54"
Harvard="AAN_PPN_MNI152_1mm_v1p0_20150630"








####### CREATE SELECTIVE SINGLE TRACT VOLUMES

fslmaths /data/Harvard-AAN/roi_masks/${Harvard}.nii.gz \
    -mul 2 \
    /data/temp-12401/${Harvard}_parc.nii.gz

fslmaths /data/temp-12401/${Harvard}_parc.nii.gz \
    -add /data/AreaFractionCC/roi_masks/${AFC}.nii.gz \
    /data/temp-12401/${Harvard}_parc.nii.gz

tck2connectome -force -zero_diagonal \
    "/data/temp-12401/Harvard-AAN.tck" \
    "/data/temp-12401/${Harvard}_parc.nii.gz" \
    "/data/temp-12401/${Harvard}_weights.tsv" \
    -out_assignment "/data/temp-12401/ass_${Harvard}.csv"


connectome2tck -force \
    "/data/temp-12401/Harvard-AAN.tck" \
    "/data/temp-12401/ass_${Harvard}.csv" \
    "/data/temp-12401/${Harvard}.tck" \
    -nodes 1,2 -exclusive -files single

