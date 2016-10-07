#!/bin/sh
Xvfb :0 -screen 0 1024x768x24&
sleep 5
export DISPLAY=:0
screen -S cytoscape -d -m /home/omero/Cytoscape_v3.4.0/cytoscape.sh
