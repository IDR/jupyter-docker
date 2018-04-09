FROM jupyter/base-notebook:8a1b90cbcba5
# jupyter/base-notebook updated 2018-04-09
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root
RUN apt-get update -y && \
    apt-get install -y \
        build-essential \
        curl \
        git

USER jovyan
# Default workdir: /home/jovyan

# Display resource usage in notebooks https://github.com/yuvipanda/nbresuse
# TODO: Consider removing, doesn't work with JupyterLab
RUN pip install https://github.com/IDR/nbresuse/archive/0.1.0-idr.zip && \
    jupyter serverextension enable --py nbresuse && \
    jupyter nbextension install --py --user nbresuse && \
    jupyter nbextension enable --py --user nbresuse

# Autoupdate notebooks https://github.com/data-8/nbgitpuller
RUN pip install git+https://github.com/data-8/gitautosync && \
    jupyter serverextension enable --py nbgitpuller

# JupyterHub JupyterLab integration
RUN jupyter labextension install @jupyterlab/hub-extension

# create a python2 environment (for OMERO-PY compatibility)
RUN mkdir .setup
ADD environment-python2.yml .setup/
RUN conda env create -n python2 -f .setup/environment-python2.yml

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
