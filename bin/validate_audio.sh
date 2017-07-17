#!/bin/bash

export HTFEED_CONFIG=/l/local/feed/etc/config_audio.yaml

# Append 'data' to given directory (which is the root of the bag) and redirect
# STDERR to STDOUT, since we aren't currently saving STDOUT

EXTERNAL_ID=$1
BAG_DIRECTORY=$2
perl /l/local/feed/bin/validate_vendoraudio_chipmunk.pl "$EXTERNAL_ID" "$BAG_DIRECTORY/data" -level INFO -file - 1>&2
