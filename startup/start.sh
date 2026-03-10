#!/bin/bash

# Absolute path to this script. /home/user/bin/foo.sh
SCRIPT=$(readlink -f $0)
# Absolute path this script is in. /home/user/bin
SCRIPTPATH=`dirname $SCRIPT`
cd "$SCRIPTPATH"

SETUP_NAME=$1
[ -z "$SETUP_NAME" ] && SETUP_NAME=${CFS_TYPE}_setup.sh

# start tmuxinator
tmuxinator start -p session_${CFS_TYPE}.yml setup_name=$SETUP_NAME