#!/bin/bash
#
#
# # convert_tractogram.sh
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
# * last update: 2024.09.07
#
#
#
# ## Description
#
# This script converts the existing .trk file of the normative tractogram (1) to MRTrix3 .tck file format
# using the trampolino containerized framework (2)
#
# * steps within this script:
# * 1. pull docker container
# * 2. run conversion call
# * 3. renaming .tck file
#
# REQUIREMENTS: 
# 1. Template connectome .trk file
# 2. Docker container software
# 3. At least 30GB of RAM
#
# REFERENCES
# 1. Lozano, Andres; Elias, Gavin; Germann, Jürgen; Joel, Suresh; Li, Ningfei; Horn, Andreas; et al. (2024). 
#    A large normative connectome for exploring the tractographic correlates of focal brain interventions. 
#    figshare. Collection. https://doi.org/10.6084/m9.figshare.c.6844890.v1
#
# 2. Matteo Mancini, https://trampolino.readthedocs.io/en/latest/authors.html#development-lead

#############################################
#                                           #
#        GET DOCKER CONTAINER               #
#                                           #
#############################################


docker pull ingmatman/trampolino



#############################################
#                                           #
#        RUN DOCKER CONTAINER               #
#                                           #
#############################################



Path='/mnt/h/Research/DeepStroke/Templates'
Filename='dTOR_full_tractogram.trk'

# start interactive shell inside the container
# for easier debugging and ressource monitoring

docker run -it -v ${Path}:/data \
    -e trk=${Filename} \
    ingmatman/trampolino \
    bash

# Validate correct volume mounting
if [[ ! -f /data/${trk} ]]; then
    echo "ERROR:    Corresponding <<.trk>> file not found."
fi

# run conversion call
trampolino convert -t ${trk} trk2tck

# rename output file
mv /data/trampolino/track.tck /data/${Filename%.trk}.tck

