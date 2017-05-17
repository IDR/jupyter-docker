FROM jupyter/datascience-notebook:latest
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root

## Swap the name of NB_USER
RUN usermod -l omero $NB_USER && \
    ln -s /home/$NB_USER /home/omero && \
    mkdir -p /home/omero/data && \
    chown omero /home/omero/data && \
    chmod a+X /home/omero
ENV NB_USER omero
# Note: this replaces "OMERO_DATA_DIR=/home/omero/data bash -eux step02_all_setup.sh"

RUN apt-get update -y && \
    apt-get install -y nodejs wget git

## Install R tools
RUN pip install notedown
RUN conda config --add channels bioconda && \
    conda install --quiet --yes \
    'r-mclust' \
    'r-ggdendro' \
    'r-igraph' \
    'r-pheatmap'


# FROM rOMERO-gateway/Dockerfile
# ##############################
# ##############################

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
## TODO: move me to other environment variables
## RUN install2.r --error rJava \
##  && rm -rf /tmp/downloaded_packages/ /tmp/*.rds

# Changed from rOMERO-gateway/Dockerfile
RUN chown omero /usr/local/lib/R/site-library
##
##
#########################################################################################


# install romero
RUN mkdir /romero \
 && wget https://raw.githubusercontent.com/ome/rOMERO-gateway/master/install.R \
 && Rscript install.R

RUN install -o omero -g users -d /notebooks /opt/omero

USER omero

RUN pip2 install omego && \
    cd /opt/omero && \
    /opt/conda/envs/python2/bin/omego download --ice 3.6 server --release 5.3 --sym OMERO.server && \
    rm -f OMERO.server-*.zip && \
    echo /opt/omero/OMERO.server/lib/python > \
    /opt/conda/envs/python2/lib/python2.7/site-packages/omero.pth

RUN conda install --name python2 --quiet --yes \
    joblib \
    markdown \
    pytables \
    python-igraph

# TODO RISE: "Live" Reveal.js Jupyter/IPython Slideshow Extension
# https://github.com/damianavila/RISE

RUN conda install --name python2 --quiet --yes -c bioconda zeroc-ice && \
    conda install --name python2 --quiet --yes -c damianavila82 rise && \
    pip2 install py2cytoscape

# Add idr-notebook library to path
RUN echo /notebooks/library > /opt/conda/envs/python2/lib/python2.7/site-packages/idr-notebooks.pth

RUN mkdir -p /home/jovyan/.local/share/jupyter/kernels/python2 && \
    sed 's/Python 2/OMERO Python 2/' \
        /opt/conda/envs/python2/share/jupyter/kernels/python2/kernel.json > \
        /home/jovyan/.local/share/jupyter/kernels/python2/kernel.json

# Don't rename user- causes problems with earlier hardcoded paths
#RUN usermod -l omero jovyan -m -d /home/omero
#USER omero

WORKDIR /notebooks

# smoke test that it's importable at least
RUN start-singleuser.sh -h > /dev/null
CMD ["start-singleuser.sh"]
