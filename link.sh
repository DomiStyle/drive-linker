#!/bin/bash

# Import config file
. config.sh

# Saves all folders that were linked for usage with the daemon
linked_folders=();

if [[ "$daemonize" = true && "$create_drive_folder" = true ]]; then
	printf "ERROR: Can't run as daemon and create drive folders.\n";
	exit 1;
fi

# Check if we should clear link
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
					linked_folders+=("$full_drive$inner_folder/$folder");
					ln -s $full_drive$inner_folder/$folder/* $active_folder; # Link all files inside the folder to the link folder
				fi
			fi
		done
	fi
done

if [ "$daemonize" = true ]; then
	printf "Starting daemon...\n";

	parameters="-m -e moved_to,moved_from,move,move_self,delete_self,create,delete";

	for linked_folder in "${linked_folders[@]}"; do
		parameters+=" $linked_folder";
	done

	inotifywait $parameters |
	while read path action file; do
		link_path=$link_folder/$(basename $path)/$file;
		action=${action%,ISDIR};

		if [[ "$action" == "CREATE" || "$action" == "MOVED_TO" ]]; then
			if [[ ! -d $link_path && ! -f $link_path ]]; then
				printf "\tLINK $file\n";
				ln -s $path$file $link_path;
			else
				echo "\tIGNORE $file\n";
			fi
		elif [[ "$action" == "DELETE" || "$action" == "MOVED_FROM" ]]; then
			if [ -L $link_path ]; then
				echo "\tUNLINK $file\n";
				unlink $link_path;
			else
				echo "\tIGNORE $file\n";
			fi
		else
			echo "\tUNKNOWN $path $action $file\n";
		fi
	done
fi
