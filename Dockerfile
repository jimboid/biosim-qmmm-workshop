# Start with BioSim base image.
ARG BASE_IMAGE=hub-5.2.1-2025-01-15
FROM harbor.stfc.ac.uk/biosimulation-cloud/biosim-jupyter-base:$BASE_IMAGE

LABEL maintainer="James Gebbie-Rayet <james.gebbie@stfc.ac.uk>"

# Root to install "rooty" things.
USER root

# Install Wham.
RUN cd /opt
RUN wget http://membrane.urmc.rochester.edu/sites/default/files/wham/wham-release-2.0.10.2.tgz
RUN tar xvf wham-release-2.0.10.2.tgz && \
    rm wham-release-2.0.10.2.tgz && \
    cd wham/wham && \
    make clean && \
    make &&\
    chown -R $NB_USER:$NB_GID /opt/wham

# Switch to jovyan user.
USER $NB_USER
WORKDIR $HOME

# Install nb env deps
RUN pip install jupyterhub-tmpauthenticator

# Install workshop deps
RUN conda install ipywidgets nglview pandas numpy matplotlib -y
RUN conda install -c conda-forge ambertools compilers -y

# Export important paths.
ENV AMBERHOME=/opt/conda
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