FROM jupyter/notebook:latest
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN git clone -b v5.2.5 --depth=1 git://github.com/ome/omero-install /omero-install
WORKDIR /omero-install/linux
RUN \
	bash -eux step01_ubuntu1404_init.sh && \
	bash -eux step01_ubuntu1404_java_deps.sh && \
	bash -eux step01_ubuntu1404_deps.sh && \
	bash -eux step01_ubuntu1404_ice_deps.sh && \
	OMERO_DATA_DIR=/home/omero/data bash -eux step02_all_setup.sh

RUN apt-get install -y -q \
    python-joblib \
    python-markdown \
    python-matplotlib \
    python-pandas \
    python-sklearn

RUN pip2 install \
    omego \
    seaborn

WORKDIR /opt/omero
RUN omego install --ice 3.5 --no-start -q && \
    echo /opt/omero/OMERO-CURRENT/lib/python > \
    /usr/local/lib/python2.7/dist-packages/omero.pth

RUN apt-get install -y libigraph0-dev && \
    add-apt-repository ppa:igraph/ppa && \
    apt-get update && \
    apt-get install python-igraph
RUN pip2 install py2cytoscape

USER root

# RISE
RUN git clone https://github.com/damianavila/RISE /tmp/RISE && \
    cd /tmp/RISE && \
    python setup.py install

# Copied from jupyterhub/singleuser
# https://github.com/jupyterhub/dockerspawner/blob/master/singleuser/Dockerfile
RUN wget -q https://raw.githubusercontent.com/jupyterhub/jupyterhub/0.6.1/scripts/jupyterhub-singleuser \
    -O /usr/local/bin/jupyterhub-singleuser && \
    chmod 755 /usr/local/bin/jupyterhub-singleuser
ADD singleuser.sh /srv/singleuser/singleuser.sh

COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json
RUN chown -R omero:omero /home/omero/.local

USER omero
# Add a notebook profile.
WORKDIR /notebooks
RUN mkdir -p -m 700 /home/omero/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> /home/omero/.jupyter/jupyter_notebook_config.py

# smoke test that it's importable at least
RUN sh /srv/singleuser/singleuser.sh -h > /dev/null
CMD ["sh", "/srv/singleuser/singleuser.sh"]
