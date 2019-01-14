FROM jupyter/base-notebook:87210526f381
# jupyter/base-notebook updated 2010-01-08
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root
RUN apt-get update -y && \
    apt-get install -y \
        build-essential \
        curl \
        git

USER jovyan
# Default workdir: /home/jovyan

# Autoupdate notebooks https://github.com/data-8/nbgitpuller
# nbval for testing reproducibility
RUN pip install git+https://github.com/data-8/gitautosync && \
    jupyter serverextension enable --py nbgitpuller && \
    conda install -y -q nbval

# create a python2 environment (for OMERO-PY compatibility)
RUN mkdir .setup
ADD environment-python2.yml .setup/
RUN conda env create -n python2 -f .setup/environment-python2.yml && \
    # Jupyterlab component for ipywidgets (must match jupyterlab version) \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.38

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
