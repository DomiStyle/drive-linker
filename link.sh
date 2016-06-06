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

# Set to true to clear the link folder before creating new links
clear_first=false;
# Merge all files into the same directory (no duplicates possible!) or create a own folder for each drive
create_drive_folder=false;

if [ "$clear_first" = true ]; then
	printf "CLEARING\n";
	rm -rf $link_folder/*; # Clear link folder
fi

# Loop through available mounted drives in folder
for full_drive in $drive_folder/*/; do
	drive="$(basename $full_drive)"; # Get the basename of the drive
	allow=false;

	# Loop through whitelisted drives
	for whitelisted_drive in "${drives[@]}"; do
		if [ "$drive" == "$whitelisted_drive" ]; then
			allow=true; # Allow drive if it exists in the array
			break;
		fi
	done

	# Check if this drive is allowed
	if [ "$allow" = true ]; then
		printf "HANDLE $drive\n";

		# Loop through folders on drive (inside the inner folder)
		for full_folder in $full_drive$inner_folder/*/; do
			folder="$(basename $full_folder)"; # Get the basename of the folder
			allow=false;
			active_folder=$link_folder/$folder;

			# Loop through whitelisted folders
			for whitelisted_folder in "${folders[@]}"; do
				if [ "$folder" == "$whitelisted_folder" ]; then
					allow=true; # Allow folder if it exists in the array
					break;
				fi
			done

			# Check if this folder is allowed
			if [ "$allow" = true ]; then
				# Check if we need to create this folder
				if [ ! -d "$active_folder" ]; then
					printf "\tCREATE $folder\n";
					mkdir -p $active_folder; # Folder doesn't exist yet, create it
				else
					printf "\tIGNORE $folder\n";
				fi

				printf "\t\tLINK $drive\n";
				
				# Check if we need to create a folder for each drive
				if [ "$create_drive_folder" = true ]; then
					ln -s $full_drive$inner_folder/$folder $active_folder/$drive; # Link the folder to a subfolder with the name of the drive
				else
					ln -s $full_drive$inner_folder/$folder/* $active_folder; # Link all files inside the folder to the link folder
				fi
			fi
		done
	fi
done
