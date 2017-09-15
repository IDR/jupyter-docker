#!/bin/bash

set -ex

# Warning: scratch and shared volumes may be mounted under notebooks
# and must remain writeable
cd /notebooks
find /notebooks -xdev -exec chmod u+w {} \;
git fetch origin
git reset --hard origin/master
find /notebooks -xdev -exec chmod a-w {} \;

exec /usr/local/bin/start-singleuser.sh "$@"
