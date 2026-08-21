# recon-any gear Dockerfile
FROM hajerkr/fs8.1.0-recon-any-base:latest

ENV FLYWHEEL=/flywheel/v0
WORKDIR ${FLYWHEEL}

RUN mkdir -p ${FLYWHEEL}/input ${FLYWHEEL}/output ${FLYWHEEL}/work

# License is gear-specific
COPY license.txt ${FREESURFER_HOME}/.license
COPY requirements.txt .
# Python deps for the gear only (small compared to FS)

RUN dnf -y install python3-pip && \
    dnf clean all && \
    python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        -r requirements.txt \
        flywheel-gear-toolkit \
        flywheel-sdk \
        jsonschema \
        importlib-metadata \
        pandas && \
    dnf remove -y python3-pip && \
    dnf clean all

# Code + manifest
COPY run.py start.sh manifest.json ${FLYWHEEL}/
COPY app/    ${FLYWHEEL}/app/
COPY shared/ ${FLYWHEEL}/shared/
COPY utils/  ${FLYWHEEL}/utils/

RUN chmod +x \
    ${FLYWHEEL}/run.py \
    ${FLYWHEEL}/start.sh \
    ${FLYWHEEL}/app/main.sh

ENTRYPOINT ["/flywheel/v0/start.sh"]