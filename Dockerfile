FROM rockylinux:9

ENV FREESURFER_HOME=/usr/local/freesurfer \
    FREESURFER_HOME_FSPYTHON=/usr/local/freesurfer \
    FREESURFER=/usr/local/freesurfer \
    FS_LICENSE=/usr/local/freesurfer/.license \
    FLYWHEEL=/flywheel/v0 \
    DEBIAN_FRONTEND=noninteractive \
    FSFAST_HOME=/usr/local/freesurfer/fsfast \
    MNI_DIR=/usr/local/freesurfer/mni \
    MINC_BIN_DIR=/usr/local/freesurfer/mni/bin \
    MINC_LIB_DIR=/usr/local/freesurfer/mni/lib \
    MNI_DATAPATH=/usr/local/freesurfer/mni/data \
    MNI_PERL5LIB=/usr/local/freesurfer/mni/share/perl5 \
    PERL5LIB=/usr/local/freesurfer/mni/share/perl5 \
    FS_OVERRIDE=0 \
    FSF_OUTPUT_FORMAT=nii.gz \
    PATH=/usr/local/freesurfer/bin:/usr/local/freesurfer/fsfast/bin:/usr/local/freesurfer/tktools:/usr/local/freesurfer/mni/bin:/usr/local/bin:/usr/bin:/bin

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR ${FLYWHEEL}

# Install OS packages
RUN dnf -y update && \
    dnf -y install \
        python3 \
        python3-pip \
        python3-devel \
        tcsh \
        bc \
        perl \
        which \
        hostname \
        tar \
        gzip \
        bzip2 \
        xz \
        unzip \
        zip \
        wget \
        ca-certificates \
        git \
        jq \
        procps-ng \
        findutils \
        glibc-langpack-en \
        libX11 \
        libXext \
        libXmu \
        libXt \
        mesa-libGLU \
        libgomp \
        libquadmath && \
    dnf clean all

# Create Flywheel directories
RUN mkdir -p ${FLYWHEEL}/input ${FLYWHEEL}/output ${FLYWHEEL}/work

# Install FreeSurfer 8.1.0 Rocky9 build
RUN wget -O /tmp/freesurfer.tar.gz \
    https://surfer.nmr.mgh.harvard.edu/ftp/dist/freesurfer/8.1.0/freesurfer-linux-rocky9_x86_64-8.1.0.tar.gz && \
    mkdir -p /usr/local && \
    tar -xzf /tmp/freesurfer.tar.gz -C /usr/local && \
    rm -f /tmp/freesurfer.tar.gz

# Install CUDA-enabled PyTorch into fspython (replaces CPU-only torch bundled with FreeSurfer)
RUN ${FREESURFER_HOME}/bin/fspython -m pip install --no-cache-dir \
    torch torchvision \
    --index-url https://download.pytorch.org/whl/cu121

# Install recon-any models
RUN wget -O /tmp/recon-any.tar.gz \
    https://ftp.nmr.mgh.harvard.edu/pub/dist/lcnpublic/dist/recon-any_models/recon-any.tar.gz && \
    mkdir -p ${FREESURFER_HOME}/models && \
    tar -xzf /tmp/recon-any.tar.gz -C ${FREESURFER_HOME}/models && \
    rm -f /tmp/recon-any.tar.gz

# Optional: verify expected recon-any files exist
RUN test -x ${FREESURFER_HOME}/bin/run_recon-any && \
    test -f ${FREESURFER_HOME}/models/recon-any/full.pth && \
    test -f ${FREESURFER_HOME}/models/recon-any/hemi.pth && \
    test -f ${FREESURFER_HOME}/models/recon-any/hemi_with_cerebellum_and_brainstem.pth

# Install MATLAB runtime dependencies if needed later
# Uncomment if your workflow requires MCR-dependent FreeSurfer tools
# RUN ${FREESURFER_HOME}/bin/fs_install_mcr R2019b

# Copy FreeSurfer license
COPY license.txt ${FREESURFER_HOME}/.license

# Install Python packages
COPY requirements.txt ${FLYWHEEL}/requirements.txt
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        -r ${FLYWHEEL}/requirements.txt \
        flywheel-gear-toolkit \
        flywheel-sdk \
        jsonschema \
        pandas

# Copy only needed application files
COPY run.py ${FLYWHEEL}/run.py
COPY start.sh ${FLYWHEEL}/start.sh
COPY app/ ${FLYWHEEL}/app/
COPY shared/ ${FLYWHEEL}/shared/
COPY utils/ ${FLYWHEEL}/utils/
COPY manifest.json ${FLYWHEEL}/manifest.json

# Permissions
RUN chmod +x \
    ${FLYWHEEL}/run.py \
    ${FLYWHEEL}/start.sh \
    ${FLYWHEEL}/app/main.sh

# Default command
ENTRYPOINT ["/flywheel/v0/start.sh"]