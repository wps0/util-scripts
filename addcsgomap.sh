#!/bin/bash

readonly EXECUTION_USER="$(id -un)"
readonly CSGO_DIR="/home/$EXECUTION_USER/.steam/steam/steamapps/common/Counter-Strike Global Offensive"

# Main execution function.
function run() {
	givenPath=$1
	clearPath=${givenPath%.*}
	mv $clearPath.bsp "$CSGO_DIR/csgo/maps/"
	mv $clearPath.nav "$CSGO_DIR/csgo/maps/"
	echo "OK!"
}

# Verification function.
function verify() {
    echo "Verifying..."

    if [[ $# -eq 0 ]]; then
        echo "Too little arguments! No map path specified."
        return -1
    fi
}


# Pass all script arguments to the verification function
#  and decide whether further execution is recommended.
if verify $*; then
    echo "Running the script..."
    run $*
else
    echo "Finishing the execution with an error!"
fi
