#!/bin/bash

# Script that handles starting the game server
# Runs in the context of a docker container
# Not intended for local development

cd /ss13_server

# Global config values
source buildByond.conf

# Load any server-specific config values (will overwrite any existing global values)
if [[ -v SS13_ID ]]; then
	SS13_ENV="tools/server/.env.$SS13_ID"
	if [ -e "$SS13_ENV" ]; then
		eval $(cat "$SS13_ENV")
	fi
fi

# Apply updates
bash tools/server/update.sh

# Load any new build version values
if [ -e ".env.build" ]; then
	eval $(cat .env.build)
fi

# Temp conditional for transition to new .env.build system
if [[ -v RUSTG_VERSION ]]; then
	cp -a "/rust-g/$RUSTG_VERSION/librust_g.so" .
else
	cp -a "/rust-g/librust_g.so" .
fi

# Update external libraries
# cp -a "/rust-g/$RUSTG_VERSION/librust_g.so" .
cp "/byond-tracy/libprof.so" .

chmod -R 770 /ss13_server

# Pick a Byond version
BYONDDIR="/byond/$BYOND_MAJOR_VERSION.$BYOND_MINOR_VERSION"
export PATH=$BYONDDIR/bin:$PATH
export LD_LIBRARY_PATH=$BYONDDIR/bin${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

echo "Starting server..."
DreamDaemon "goonstation.dmb" $SS13_PORT -trusted -verbose 2>&1 | bash tools/server/log.sh >> data/errors.log
