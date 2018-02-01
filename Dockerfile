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
        idr-py==0.1.1

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

# Switch to root user for installing R and Cell Profiler(in future) dependencies
USER root

# # R Installation (Staying as root user)
RUN   apt-get -y update &&                                          \
      apt-get -y install                                            \
        cython             \
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

## Install R tools
RUN /opt/conda/envs/python2/bin/conda config --add channels bioconda && \
    /opt/conda/envs/python2/bin/conda install --quiet --yes \
    'r-mclust=5.3' \
    'r-ggdendro=0.1_20' \
    'r-igraph=1.0.1' \
    'r-pheatmap=1.0.8'

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

RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c r r=3.4.1
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

# install romero
ENV _JAVA_OPTIONS="-Xss2560k -Xmx2g"
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c anaconda gfortran_linux-64
RUN mkdir /romero \
 && wget https://raw.githubusercontent.com/dominikl/rOMERO-gateway/update_dev_5_3/install.R \
 && Rscript install.R --user=dominikl --branch=update_dev_5_3
# The above line uses a branch from Dominik's rOMERO-gateway repository (to make rOMERO work with IDR (OMERO_5_3)), 
# this needs to be updated to OME/dev_5_3 when that branch is fixed

# install r-kernel
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c r r-irkernel

# install ipywidgets
RUN /opt/conda/envs/python2/bin/conda install --quiet --yes -c conda-forge ipywidgets

# switch user and working directory to /notebooks folder
USER jovyan
RUN /opt/conda/envs/python2/bin/pip install --upgrade 'git+https://github.com/bramalingam/idr-py@Update_IDRPY'
WORKDIR /notebooks
RUN git clone -b Update_Notebooks https://git@github.com/bramalingam/idr-notebooks.git /notebooks

# Autodetects jupyterhub and standalone modes
CMD ["start-notebook.sh"]
