FROM jupyter/base-notebook
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

# switch to root suer
USER root
RUN apt-get update -y && \
    apt-get install -y nodejs

RUN install -o jovyan -g users -d /notebooks /opt/omero

# switch user
USER jovyan

# create a python2 environment (for OMERO-PY compatibility)
RUN conda create -n python2 python=2 --quiet --yes

# install notebook dependencies within the python2 environment
RUN conda install --name python2 --quiet --yes \
    bokeh \
    ipywidgets \
    joblib \
    markdown \
    matplotlib \
    pandas \
    pillow \
    psutil \
    pytables \
    pytest \
    python-igraph \
    scikit-image \
    scikit-learn \
    scipy \
    seaborn

# RISE: "Live" Reveal.js Jupyter/IPython Slideshow Extension
# https://github.com/damianavila/RISE
RUN conda install --quiet --yes -c damianavila82 rise

# install zeroc-ice and python-omero
RUN conda install --name python2 --quiet --yes -c bioconda zeroc-ice && \
    conda install --name python2 --quiet --yes -c bioconda python-omero=5.3.3

# install idr-py and notebook dependencies
RUN /opt/conda/envs/python2/bin/pip install \
        graphviz \
        gseapy \
        py2cytoscape \
        pydot \
        tqdm \
        idr-py==0.1.1

RUN mkdir -p /home/jovyan/.local/share/jupyter/kernels/python2 && \
    sed 's/Python 2/OMERO Python 2/' \
        /opt/conda/envs/python2/share/jupyter/kernels/python2/kernel.json > \
        /home/jovyan/.local/share/jupyter/kernels/python2/kernel.json

# Install git and pull the notebooks from the training repository
RUN conda install --name python2 --quiet --yes -c anaconda git

# Switch to root user for installing Cell Profiler dependencies
USER root

# Install CellProfiler dependencies
RUN   apt-get -y update &&                                          \
      apt-get -y install                                            \
        build-essential    \
        cython             \
        git                \
        libmysqlclient-dev \
        libhdf5-dev        \
        libxml2-dev        \
        libxslt1-dev       \
        openjdk-8-jdk      \
        python-dev         \
        python-pip         \
        python-h5py        \
        python-matplotlib  \
        python-mysqldb     \
        python-scipy       \
        python-numpy       \
        python-wxgtk3.0    \
        python-zmq

WORKDIR /usr/local/src

# Install CellProfiler
RUN /opt/conda/envs/python2/bin/git clone https://github.com/CellProfiler/CellProfiler.git

WORKDIR /usr/local/src/CellProfiler

ARG version=3.0.0

RUN /opt/conda/envs/python2/bin/git checkout tags/v$version

RUN /opt/conda/envs/python2/bin/pip install --editable .

# R Installation (Staying as root user)
RUN apt-get update -y && \
    apt-get install -y nodejs wget git

## Install R tools
RUN /opt/conda/envs/python2/bin/conda config --add channels bioconda && \
    /opt/conda/envs/python2/bin/conda install --quiet --yes \
    'r-mclust' \
    'r-ggdendro' \
    'r-igraph' \
    'r-pheatmap'

# Dependencies necessary for install.R
RUN echo "deb-src http://deb.debian.org/debian testing main" >> /etc/apt/sources.list
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list
RUN apt-get update && \
    apt-get -y install libssl-dev libxml2-dev libcurl4-openssl-dev

#########################################################################################
## Necessary for running maven
## copied from https://hub.docker.com/r/cardcorp/r-java/~/dockerfile/
##
## gnupg is needed to add new key
RUN apt-get update && apt-get install -y gnupg2

## Install Java 
RUN apt-get update \
    && apt-get install -t jessie-backports -y openjdk-8-jdk \
    && echo "MAVEN IS NOT IN THE UPSTREAM LIST (JOSH)" \
    && apt-get install -y maven \ 
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean 

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN rm -rf /usr/lib/jvm/java
RUN ln -s  /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/java

RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c r r
RUN R CMD javareconf
    
## make sure Java can be found in rApache and other daemons not looking in R ldpaths
RUN echo "/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/amd64/server/" > /etc/ld.so.conf.d/rJava.conf
RUN /sbin/ldconfig

###
### Fix install2.r
### --------------
### See https://github.com/rocker-org/rocker/blob/e9758030e435915d5e6f21aaab0fc35a5a8efaae/r-base/Dockerfile#L41
### https://github.com/rocker-org/rocker/issues/149
### --------------
## Now install R and littler, and create a link for littler in /usr/local/bin
## Also set a default CRAN repo, and make sure littler knows about it too
RUN apt-get update \
        && echo "MIGRATE THIS BLOCK TO THE APT-GET ABOVE" \
    && apt-get install -y --no-install-recommends \
        littler \
        && echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site \
        && echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r \
    && ln -s /usr/share/doc/littler/examples/install.r /usr/local/bin/install.r \
    && ln -s /usr/share/doc/littler/examples/install2.r /usr/local/bin/install2.r \
    && ln -s /usr/share/doc/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
    && ln -s /usr/share/doc/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
    && install.r docopt \
    && rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
    && rm -rf /var/lib/apt/lists/*

## Install rJava package
ENV PATH=$PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin
RUN conda install --quiet --yes -c r r-rjava=0.9_8

# Changed from rOMERO-gateway/Dockerfile
RUN chown jovyan /usr/local/lib/R/site-library

##
##
#########################################################################################

USER root

# install romero
ENV _JAVA_OPTIONS="-Xss2560k -Xmx2g"
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c anaconda gfortran_linux-64
RUN mkdir /romero \
 && wget https://raw.githubusercontent.com/ome/rOMERO-gateway/master/install.R \
 && Rscript install.R --user=ome --branch=master

# install r-kernel
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c r r-irkernel

# install ipywidgets
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c conda-forge ipywidgets

# switch user and working directory to /notebooks folder
USER jovyan
WORKDIR /notebooks
RUN git clone https://github.com/IDR/idr-notebooks.git /notebooks

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
