# Start with BioSim base image.
ARG BASE_IMAGE=latest
FROM ghcr.io/jimboid/biosim-jupyterhub-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"
LABEL org.opencontainers.image.source=https://github.com/jimboid/biosim-qmmm-workshop
LABEL org.opencontainers.image.description="A container environment for the ccpbiosim workshop on QM/MM."
LABEL org.opencontainers.image.licenses=MIT

ARG AMBER_DL_PATH=null
ARG AMBER_VERSION=25
ENV AMBER_VERSION=${AMBER_VERSION}

# Install workshop deps
RUN conda install ipywidgets nglview pandas numpy scipy matplotlib compilers -y
#RUN conda install conda-forge::ambertools -y

# Root to install "rooty" things.
USER root

# Install Wham.
RUN cd /opt && \
    mkdir wham && \
    wget http://membrane.urmc.rochester.edu/sites/default/files/wham/wham-release-2.0.11.tgz && \
    tar xvf wham-release-2.0.11.tgz -C wham --strip-components=1 && \
    rm wham-release-2.0.11.tgz && \
    cd wham/wham && \
    make clean && \
    make &&\
    chown -R $NB_USER:$NB_GID /opt/wham

# Download, unzip and cd into the specified AMBER source.
WORKDIR /tmp
RUN wget $AMBER_DL_PATH/AmberTools${AMBER_VERSION}.tar.bz2 && \
    chown ${SYSTEM_UID}:${SYSTEM_GID} AmberTools${AMBER_VERSION}.tar.bz2 && \
    mkdir /tmp/amber${AMBER_VERSION}_src && \
    tar xvjf AmberTools${AMBER_VERSION}.tar.bz2 -C /tmp/amber${AMBER_VERSION}_src --strip-components 1 && \
    rm AmberTools${AMBER_VERSION}.tar.bz2
WORKDIR /tmp/amber${AMBER_VERSION}_src

# Update AMBER source.
RUN ./update_amber --update

# Make a build dir in /tmp.
RUN mkdir /tmp/build
WORKDIR /tmp/build

# Build AMBER without mpi and without cuda.
RUN cmake /tmp/amber${AMBER_VERSION}_src -DCMAKE_INSTALL_PREFIX=/opt/amber${AMBER_VERSION} -DBUILD_PYTHON=TRUE -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE -DDOWNLOAD_MINICONDA=FALSE -DCOMPILER=MANUAL -DBUILD_GUI=FALSE -DCOMPILER=GNU -DOPENMP=TRUE -DCUDA=FALSE -DMPI=FALSE -DUSE_FFT=True -DBUILD_DEPRECATED=False -DBUILD_INDEV=False -DBUILD_PERL=True -DOPTIMIZE=True
RUN make -j8
RUN make install

# Cleanup.
RUN rm -r /tmp/amber${AMBER_VERSION}_src 

# Switch to jovyan user.
USER $NB_USER
WORKDIR $HOME

# Export important paths.
ENV AMBERHOME=/opt/amber${AMBER_VERSION}
ENV PATH="$PATH:/opt/amber${AMBER_VERSION}/bin"
ENV WHAM_HOME=/opt/wham

# Add all of the workshop files to the home directory
RUN git clone https://github.com/CCPBioSim/qmmm-workshop.git
RUN mv qmmm-workshop/* . && \
    rm -r AUTHORS LICENSE _config.yml qmmm-workshop

# Copy lab workspace
COPY --chown=1000:100 default-37a8.jupyterlab-workspace /home/jovyan/.jupyter/lab/workspaces/default-37a8.jupyterlab-workspace

# UNCOMMENT THIS LINE FOR REMOTE DEPLOYMENT
COPY jupyter_notebook_config.py /etc/jupyter/

# Always finish with non-root user as a precaution.
USER $NB_USER
