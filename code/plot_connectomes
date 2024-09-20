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