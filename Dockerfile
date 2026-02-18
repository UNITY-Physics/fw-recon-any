FROM python:3.10-slim AS freesurfer-builder

ENV FREESURFER_HOME=/usr/local/freesurfer \
    DEBIAN_FRONTEND=noninteractive \
    FLYWHEEL=/flywheel/v0

WORKDIR ${FLYWHEEL}
RUN mkdir -p ${FLYWHEEL}/input

# Install build dependencies
RUN apt-get update && apt-get install -y \
    wget \
    git \
    ca-certificates \
    tcsh \
    bc \
    tar \
    libgomp1 \
    libglu1-mesa \
    libxrender1 \
    libxcursor1 \
    libxft2 \
    libxinerama1 \
    libfreetype6 \
    libxi6 \
    libxrandr2 \
    libquadmath0 \
    libxmu6 \
    libxt6 \
    && rm -rf /var/lib/apt/lists/*

# Download and install FreeSurfer

#https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/dev/freesurfer-linux-ubuntu22_x86_64-7-dev.tar.gz
# Replace the wget/dpkg section with:

RUN wget -O /tmp/recon-any.tar.gz https://ftp.nmr.mgh.harvard.edu/pub/dist/lcnpublic/dist/recon-any_models/recon-any.tar.gz && \
mkdir -p /usr/local/freesurfer/models && \
tar -xzf /tmp/recon-any.tar.gz -C /usr/local/freesurfer/models && \
rm /tmp/recon-any.tar.gz

RUN wget -O /tmp/freesurfer.tar.gz \
https://surfer.nmr.mgh.harvard.edu/ftp/dist/freesurfer/dev/freesurfer-linux-ubuntu22_x86_64-7-dev.tar.gz && \
mkdir -p /usr/local && \
tar -xzf /tmp/freesurfer.tar.gz -C /usr/local && \
rm /tmp/freesurfer.tar.gz




RUN echo "=== Checking FreeSurfer installation ===" && \
ls -la ${FREESURFER_HOME}/ && \
echo "=== Checking for models directory ===" && \
ls -la ${FREESURFER_HOME}/models/ || echo "No models directory found" && \
echo "=== Checking for python/scripts ===" && \
ls -la ${FREESURFER_HOME}/python/scripts/ || echo "No python/scripts directory found"

# Copy license and verify installation
COPY license.txt ${FREESURFER_HOME}/.license
#RUN test -d ${FREESURFER_HOME}/bin || (echo "FreeSurfer installation failed!" && exit 1)

# ===== Final Stage =====
FROM --platform=linux/amd64 python:3.10-slim

ENV FLYWHEEL=/flywheel/v0 \
    FREESURFER_HOME=/usr/local/freesurfer \
    FS_LICENSE=/usr/local/freesurfer/.license \
    PATH="/usr/local/freesurfer/bin:/usr/local/freesurfer/fsfast/bin:/usr/local/freesurfer/tktools:/usr/local/freesurfer/mni/bin:/usr/local/bin:/usr/bin:/bin"

WORKDIR ${FLYWHEEL}

# Copy FreeSurfer from builder stage
COPY --from=freesurfer-builder /usr/local/freesurfer /usr/local/freesurfer

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tcsh \
        perl \
        build-essential \
        jq \
        libsqlite3-dev \
        bc \
        libgomp1 \
        libxmu6 \
        libxt6 \
        libxext6 \
        libglu1-mesa && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt ${FLYWHEEL}/
RUN pip3 install --no-cache-dir -r requirements.txt

RUN pip3 install flywheel-gear-toolkit && \
    pip3 install flywheel-sdk && \
    pip3 install jsonschema && \
    pip3 install pandas  && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

# Copy application files
COPY shared/ ${FLYWHEEL}/utils/
COPY ./ ${FLYWHEEL}/

#COPY recon-any.sh to ${FLYWHEEL}/app/recon-any.sh
COPY ./app/recon-any.sh ${FLYWHEEL}/app/recon-any.sh
COPY ./app/recon-any.sh ${FREESURFER_HOME}/bin/recon-any.sh
#COPY data files
COPY data/ ${FLYWHEEL}/data/

# Set executable permissions
RUN chmod +rx \
        ${FLYWHEEL}/run.py \
        ${FLYWHEEL}/start.sh \
        ${FLYWHEEL}/app/main.sh \
        ${FLYWHEEL}/app/recon-any.sh

# Verify FreeSurfer installation
#RUN test -f ${FREESURFER_HOME}/bin/recon-any || (echo "recon-any not found!" && exit 1)