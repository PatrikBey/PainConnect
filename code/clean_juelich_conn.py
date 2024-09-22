#!/bin/python
#
#
# # clean_juelich_conn.py
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
# * last update: 2024.09.22
#
#
#
# ## Description
#
# This script cleans the previously created connectomes
# for the Juelich atlas. This is necessary due to false labeling
# within the used parcellation volume during connectome creation
# within "create_fraction_juelich_conn.sh".
#
# The ROIs in the parcellation volumes were:
# 1. falsely starting at 2, creating an empty ROI-1 entry in teh connectome
#    which was always empty
# 2. create false ROIs with IDs 281+ even though only 280 ROIs
#    exist in the atlas. This was due to midline overlaps of the
#    used single ROI masks. These overlaps have been removed
#    and therefore the corresponding columns / rows need to be
#    removed from the connectomes as well.

#############################################
#                                           #
#              LOAD LIBRARIES               #
#                                           #
#############################################

import nibabel, numpy, os, matplotlib.pyplot as plt, glob
from progress.bar import Bar


Path = '/data'

ConnectomeFiles = glob.glob(os.path.join(Path, 'Connectomes_old', 'Juelich_*_weights.tsv'))

with Bar(f'UPDATE:    cleaning connectomes', max = len(ConnectomeFiles)) as bar:
    for f in ConnectomeFiles:
        roi = os.path.basename(f).split('_')[1]
        cc = numpy.genfromtxt(f)
        tmp = numpy.delete(cc, numpy.arange(281,414), axis = 0)
        tmp = numpy.delete(tmp, numpy.arange(281,414), axis = 1)
        tmp = numpy.delete(tmp,0,axis = 0)
        tmp = numpy.delete(tmp,0,axis = 1)
        numpy.savetxt(os.path.join(Path,'Connectomes', f'{roi}_Juelich_weights.tsv'), tmp, delimiter = '\t')
        bar.next()

