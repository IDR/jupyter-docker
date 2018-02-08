FROM jupyter/base-notebook:9089b66a9813
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root
RUN apt-get update -y && \
    apt-get install -y nodejs wget git && \
    apt-get install -y build-essential

RUN install -o jovyan -g users -d /notebooks /opt/omero

# switch user
USER jovyan

# create a python2 environment (for OMERO-PY compatibility)
RUN conda create -n python2 python=2 --quiet --yes

# install notebook dependencies within the python2 environment
RUN conda install --name python2 --quiet --yes \
    bokeh=0.12.11 \
    ipywidgets=7.0.5 \
    joblib=0.11 \
    markdown=2.6.9 \
    matplotlib=2.0.2 \
    pandas=0.21.0 \
    pillow=4.2.1 \
    psutil=5.4.0 \
    pytables=3.4.2 \
    pytest=3.3.0 \
    python-igraph=0.7.1.post6 \
    scikit-image=0.13.0 \
    scikit-learn=0.19.1 \
    scipy=1.0.0 \
    seaborn=0.8.1

# RISE: "Live" Reveal.js Jupyter/IPython Slideshow Extension
# https://github.com/damianavila/RISE
RUN conda install --quiet --yes -c damianavila82 rise

# install zeroc-ice and python-omero
RUN conda install --name python2 --quiet --yes -c bioconda zeroc-ice && \
    conda install --name python2 --quiet --yes -c bioconda python-omero=5.3.3

# install idr-py and notebook dependencies
RUN /opt/conda/envs/python2/bin/pip install \
        graphviz==0.8.2 \
        gseapy==0.9.2 \
        py2cytoscape==0.6.2 \
        pydot==1.2.4 \
        tqdm==4.19.5 \
        idr-py==0.1.2

# Display resource usage in notebooks https://github.com/yuvipanda/nbresuse
RUN pip install https://github.com/IDR/nbresuse/archive/0.1.0-idr.zip && \
    jupyter serverextension enable --py nbresuse && \
    jupyter nbextension install --py --user nbresuse && \
    jupyter nbextension enable --py --user nbresuse

RUN mkdir -p /home/jovyan/.local/share/jupyter/kernels/python2 && \
    sed 's/Python 2/OMERO Python 2/' \
        /opt/conda/envs/python2/share/jupyter/kernels/python2/kernel.json > \
        /home/jovyan/.local/share/jupyter/kernels/python2/kernel.json

# Install git and pull the notebooks from the training repository
RUN conda install --name python2 --quiet --yes -c anaconda git=2.15.0

# install ipywidgets
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c conda-forge ipywidgets

# switch user and working directory to /notebooks folder
USER jovyan
WORKDIR /notebooks
RUN git clone -b 0.6.0 https://github.com/IDR/idr-notebooks /notebooks

# Downgrade version of jupyterhub
RUN pip install jupyterhub==0.7.2

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
