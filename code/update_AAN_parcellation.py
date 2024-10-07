#!/bin/python
#
#
# # update_AAN_parcellation.py
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
# This script extracts the mapping for each
# Area Fraction CC (AFC) ROI to the Juelich atlas ROIs.
# A mapping is defined as an overlay of the 
# AFC mask with defined Juelich ROIs
#
# STEPS:
# 1. create LUT for ROI parcellation values
#
# REQUIREMENTS: 
# 1. python, nibabel, numpy

#############################################
#                                           #
#              LOAD LIBRARIES               #
#                                           #
#############################################

import nibabel, numpy, os, matplotlib.pyplot as plt, argparse, json
from progress.bar import Bar



#############################################
#                                           #
#                FUNCTIONS                  #
#                                           #
#############################################


def log_msg( _string):
    '''
    logging function printing date, scriptname & input string to stdout
    '''
    import datetime, os, sys
    print(datetime.date.today().strftime("%a %B %d %H:%M:%S %Z %Y") + " " + str(os.path.basename(sys.argv[0])) + ": " + str(_string))

def check_dim(arr1, arr2):
    '''
    compare matrix dimensions for given arrays
    '''
    if arr1.shape != arr2.shape:
        log_msg("ERROR:    dimension mismatch")

def get_roi_names(roi_list, lut):
    '''
    extract ROI names from atlas look up table
    for each ROI
    '''
    names = dict()
    for r in roi_list:
        names[r] = str(lut[numpy.where(lut[:,0]==r)[0],1][0])
    return(names)

# ---- input parsing ---- #

parser = argparse.ArgumentParser()
parser.add_argument("--path", help="Define input path.", default = '/data')
parser.add_argument("--atlas", help="Define atlas name.", default = 'AAN')
args = parser.parse_args()


# ---- define variables ---- #

Path = args.path
Atlas = os.path.join(Path,'Templates',f'{args.atlas}_parcellation.nii.gz')
AtlasImg = nibabel.load(Atlas).get_fdata()

rois_init = numpy.unique(AtlasImg)
AtlasNew = numpy.where(AtlasImg > 281,0,AtlasImg)
