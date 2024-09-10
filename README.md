# PAINCONNECT
This repo contains the code for ROI based connectomics as performed in (1).


## AUTHOR
This project was developed and implemented by:
<a href="https://github.com/PatrikBey" target="_blank">Patrik Bey</a>

## DOCUMENTATION

### Requirements
The scripts require a containerized MRTrix3 version. Here we used the LeAPP processing container (2).

### module 1: Data preparation

#### 1. tractogram preparation
Transforming the provided <i>.trk</i> tractogram file to MRTrix3 compatible <i>.tck</i> file format. 
requirements:
1. python libraries:
    nibabel
    DiPY

```python

python /code/convert_tractogram.py
```

#### 2. Seed / Target ROI tract extraction
Extracting all tracts starting in <i>seed</i> ROI and ending in <i>target</i> ROI.




## REFERENCES
1. Reimann et al. (in prep.)

2. Bey, P., Dhindsa, K., Kashyap, A., Schirner, M., Feldheim, J., Bönstrup, M., Schulz, R., Cheng, B., Thomalla, G., Gerloff, C., & Ritter, P. (2024). A lesion-aware automated processing framework for clinical stroke magnetic resonance imaging. Human Brain Mapping, 45(9), e26701. https://doi.org/10.1002/hbm.26701

