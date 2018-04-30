FROM jupyter/base-notebook:1dc1481636a2
# jupyter/base-notebook updated 2018-04-27
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

# create a python2 environment (for OMERO-PY compatibility)
RUN mkdir .setup
ADD environment-python2.yml .setup/
RUN conda env create -n python2 -f .setup/environment-python2.yml && \
    # Jupyterlab component for ipywidgets (must match jupyterlab version) \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^0.35

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
