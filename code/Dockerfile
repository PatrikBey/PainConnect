FROM ubuntu:22.04
LABEL name="ROI2ROI-Connect"
LABEL maintainer="Patrik Bey <patrik.bey@bih-charite.de>"
LABEL version="0.1"


ARG DEBIAN_FRONTEND=noninteractive

ENV LANG="C.UTF-8" \
    LC_ALL="C.UTF-8" \
    OS=Linux

# Install OS packages using apt-get
RUN apt-get -qq update && \
apt-get install -yq --no-install-recommends \
bc \
bzip2 \
ca-certificates \
curl \
libgomp1 \
perl-modules \
tar \
tcsh \
wget \
libxmu6 \
git \
libeigen3-dev \
libfftw3-dev \
libgl1-mesa-dev \
libpng-dev \
libtiff5-dev \
zlib1g-dev \
libxext6 \
libxpm-dev \
libxt6 \
libfreetype6 \
libglib2.0 \
gcc \
g++ \
libglu1 \
unzip && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN wget -q https://repo.continuum.io/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh && \
    bash Miniconda2-4.7.12.1-Linux-x86_64.sh -b -p /usr/local/miniconda && \
    rm Miniconda2-4.7.12.1-Linux-x86_64.sh

ENV PATH="/usr/local/miniconda/bin:$PATH"

RUN conda config --add channels conda-forge && \
    conda install -y mkl=2019.3 mkl-service=2.0.2 numpy=1.16.4 nibabel=2.4.1 pandas=0.24.2 && sync && \
    conda clean -tipsy && sync 



RUN echo "START:    installing MRtrix3"
# # install mrtrix3 for tractography

RUN git clone -b "master" --depth 1 https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3
RUN cd /opt/mrtrix3/ && \
    ./configure -nogui && \
    ./build -persistent -nopaginate

#save env path mrtrix3
ENV MRTRIXDIR=/opt/mrtrix3
# add mrtrix to PATH variable
ENV PATH="/opt/mrtrix3/bin:$PATH"


RUN echo "START:    installing FSL"
RUN wget -q http://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py -O /usr/local/fslinstaller.py 
RUN chmod 775 /usr/local/fslinstaller.py && \
    python2 /usr/local/fslinstaller.py -d /opt/fsl -V 6.0.6 && \
    rm -f /usr/local/fslinstaller.py

ENV FSLDIR=/opt/fsl
ENV FSL_DIR="${FSLDIR}" \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PATH=${FSLDIR}/bin:$PATH \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=${FSLDIR} \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    FSLOUTPUTTYPE=NIFTI_GZ


RUN apt-get update
RUN apt-get install figlet

RUN pip install lolcat

ENV TEMPLATEDIR="/templates"
COPY Templates "/templates"

RUN mkdir "/src"
COPY code "/src"
ENV SRCDIR="/src"
WORKDIR "/src"

# ---- call run script ---- #
CMD ["bash", "/src/run.sh"]