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
	rm -rf $link_folder/*;
fi

for full_drive in $drive_folder/*/; do
	drive="$(basename $full_drive)";
	allow=false;

	for whitelisted_drive in "${drives[@]}"; do
		if [ "$drive" == "$whitelisted_drive" ]; then
			allow=true;
			break;
		fi
	done

	if [ "$allow" = true ]; then
		printf "HANDLE $drive\n";

		for full_folder in $full_drive$inner_folder/*/; do
			folder="$(basename $full_folder)";
			allow=false;
			active_folder=$link_folder/$folder;

			for whitelisted_folder in "${folders[@]}"; do
				if [ "$folder" == "$whitelisted_folder" ]; then
					allow=true;
					break;
				fi
			done

			if [ "$allow" = true ]; then
				if [ ! -d "$active_folder" ]; then
					printf "\tCREATE $folder\n";
					mkdir -p $active_folder;
				else
					printf "\tIGNORE $folder\n";
				fi

				printf "\t\tLINK $drive\n";
				
				if [ "$create_drive_folder" = true ]; then
					ln -s $full_drive$inner_folder/$folder $active_folder/$drive;
				else
					ln -s $full_drive$inner_folder/$folder/* $active_folder;
				fi
			fi
		done
	fi
done
