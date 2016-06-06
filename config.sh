#!/bin/bash

# The folder where all of your drives are mounted to
drive_folder="/media";
# The folder where all of your drives should be linked to (make sure the directory exists and is writeable by current user)
link_folder="/media/pool";
# The folder which exists on every drive and should be linked
inner_folder="media";

# Array of drives to link
drives=("drive1" "drive2" "drive3" "drive4");
# Array of folders to link
folders=("movies" "shows");

# Run a daemon to link/unlink in realtime (does not work with create_drive_folder)
daemonize=false;
# Set to true to clear the link folder before creating new links
clear_first=false;
# Merge all files into the same directory (no duplicates possible!) or create a own folder for each drive
create_drive_folder=false;