#!/bin/bash
#
#
# # plot_connectomes.py
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
# * last update: 2024.09.11
#
#
#
# ## Description
#
# This script visualizes the given connectomes.





import matplotlib.pyplot as plt, numpy, os




files = os.listdir('./Connectomes')

for f in files:
    parc = f.split('_')[0]
    lut = numpy.genfromtxt(os.path.join('/data','Templates',f'{parc}_LUT.txt'), dtype=str)
    tmp = numpy.genfromtxt(os.path.join('/data','Connectomes',f))
    plt.imshow(tmp, cmap = 'pink')
    plt.colorbar()
    plt.title(f[:-4])
    plt.savefig(f'{f[:-4]}.png' )
    plt.close()



target='MorelAtlasMNI152'
file=f'annotated/AreaFractionCC_{target}_weights_annotated.tsv'

cc = numpy.genfromtxt(file, dtype = str)



def plot_connectome(seed, target, colors = 'gnuplot', outfile = None, path = None):
    '''
    plot connectivity from <seed> to <target> ROIs
    as heatmap
    '''
    import os, numpy, matplotlib.pyplot as plt
    if not path:
        path = os.getcwd()
    file = os.path.join(path, f'{seed}_{target}_weights_annotated.tsv')
    if not outfile:
        outfile = os.path.join(os.path.dirname(file),f'{seed}_{target}_connectivity.png')
    cc = numpy.genfromtxt(file, dtype = str)
    seed_rois = cc[1:,0]
    target_rois=cc[0,1:]
    data = cc[1:,1:].astype(float)
    plt.figure(figsize=[25,20])
    plt.imshow(data, cmap = 'gnuplot')
    plt.colorbar()
    plt.ylabel('AreaFractionCC', fontsize = 15)
    plt.xlabel(f'{target}', fontsize = 15)
    plt.yticks(numpy.arange(len(seed_rois)), labels=seed_rois)
    plt.xticks(numpy.arange(len(target_rois)), labels=target_rois, rotation=90)
    plt.tight_layout()
    plt.savefig(outfile)
    plt.close()


for target in ('Harvard-AAN','MorelAtlasMNI152', 'BrainstemNavigator'):
    plot_connectome('AreaFractionCC',target)