#!/bin/bash

# ToDo: auto detection of the latest TS3 server version, local installed version, auto updates using CRON

# ToDo: wziac przepisac na argumenty

# ToDo: komunikaty gdy sie nie uda jakiejs operacji wykonac (backup/download/decompress)


#= Constant variables =#
readonly DOWNLOAD_LINK_TEMPLATE="https://files.teamspeak-services.com/releases/server/%VERSION%/teamspeak3-server_linux_amd64-%VERSION%.tar.bz2"

readonly TS3_USER="ts3aod"
readonly TS3_SERVICE_TSDNS="tsdns"
readonly TS3_SERVICE_SERVER="ts3server"
readonly BACKUP_CMD="backup $TS3_USER"

readonly DOWNLOAD_DIR="/tmp/ts3autoupdate/$(date +%s)"
readonly UPDATE_DIR="${DOWNLOAD_DIR}/update"
readonly SERVER_DIR="/home/ts3aod"

###

downloadedFile=""

# Download file contents with given URL.
function download() {
    # Init variables
    downloadedFile=$1
    downloadedFile=$DOWNLOAD_DIR/${downloadedFile##*/}
    
    # Perform startup 
    mkdir -p $DOWNLOAD_DIR
    
    # Download the file
    echo "Downloading $1..."
    wget -O $downloadedFile $1
    echo "Saved file to $downloadedFile"
}

# Decompress and extract the file with given path
function decompress() {
    # Determine the file type
    local readonly FILE_TYPE="$(file -b --mime-type $downloadedFile)"
    echo "File type: $FILE_TYPE"
    echo "Trying to decompress..."
    
    # Init update directory
    mkdir -p $UPDATE_DIR
    
    # ZIP file type
    if [[ $FILE_TYPE == "application/zip" ]]; then
        echo "Extracting the update to $UPDATE_DIR..."
        unzip -qd $UPDATE_DIR $downloadedFile
        echo "OK"
    # TAR BZIP2 file type
    elif [[ $FILE_TYPE == "application/x-bzip2" ]]; then
        echo "Extracting the update to $UPDATE_DIR..."
        tar -xf $downloadedFile -C $UPDATE_DIR
        echo "OK"
    fi
    
    
    # Move the possible contents of a single directory inside the extraction result.
    if [[ $(ls -l $UPDATE_DIR | wc -l) -eq 2 ]]; then
        echo "It's possible that the archive contained a directory. Making sure..."
        
        local possibleDirectory=$UPDATE_DIR/$(ls $UPDATE_DIR | tail -1)
        # Move the contents of the possible dir to the UPDATE_DIR
        if [[ -d $possibleDirectory ]]; then
            echo "Correct. Moving its contents to the root dir..."
            cp -r $possibleDirectory/* $UPDATE_DIR
            rm -rf $possibleDirectory
            ls $UPDATE_DIR
            echo "Moved!"
        fi
    fi
}

# Stop the TS3-related services and perform preupdate tasks
function preUpdate() {
    echo "Performing preupdate tasks..."
    
    # Prepare services
    echo "Stopping services..."
    sudo service $TS3_SERVICE_TSDNS stop
    sudo service $TS3_SERVICE_SERVER stop
    echo "Services stopped"
    
    # Perform backup
    echo "Performing backup..."
    eval $BACKUP_CMD
    echo "Backup completed!"
}

# Update the teamspeak 3 server
function update() {
	echo "Updating..."
	sudo cp -r $UPDATE_DIR/* $SERVER_DIR/
	echo "Update completed!"
}

# Perform postupdate tasks
function postUpdate() {
	# Start the services
    echo "Starting services..."
    sudo service $TS3_SERVICE_TSDNS start
    sudo service $TS3_SERVICE_SERVER start
    echo "Services started"
    
    # Change permissions
    echo "Changing file permissions..."
    sudo chown $TS3_USER -R $SERVER_DIR/*
}

function cleanup() {
	echo "Performing cleanup..."
	echo "Removing files..."
	rm -vr $DOWNLOAD_DIR
	echo "Cleanup completed!"
}


# Main execution function.
function run() {
    download $*
    decompress $downloadedFile
    preUpdate
    update
    postUpdate
    cleanup
}

# Verification function.
function verify() {
    echo "Verifying..."

    if [[ $# -eq 0 ]]; then
        echo "Too little arguments!"
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
