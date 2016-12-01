#!/bin/bash

# Import config file
. config.sh

# Saves all folders that were linked for usage with the daemon
linked_folders=();

if [[ "$daemonize" = true && "$create_drive_folders" = true ]]; then
	printf "ERROR: Can't run as daemon and create drive folders.\n";
	exit 1;
fi

# Check if we should clear link folder
if [[ "$clear_links" = true && -n "$link_folder" ]]; then
	printf "CLEARING\n";
	rm -rf "$link_folder/*"; # Clear link folder
fi

# Loop through available mounted drives in folder
for full_drive in "$drive_folder"/*/; do
	drive=$(basename "$full_drive"); # Get the basename of the drive
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
		for full_folder in "$full_drive$inner_folder"/*/; do
			folder=$(basename "$full_folder"); # Get the basename of the folder
			allow=false;
			active_folder="$link_folder/$folder";

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
					mkdir -p "$active_folder"; # Folder doesn't exist yet, create it
				else
					printf "\tIGNORE $folder\n";
				fi

				printf "\t\tLINK $drive\n";

				# Check if we need to create a folder for each drive
				if [ "$create_drive_folders" = true ]; then
					ln -s "$full_drive$inner_folder/$folder" "$active_folder/$drive"; # Link the folder to a subfolder with the name of the drive
				else
					linked_folders+=("$full_drive$inner_folder/$folder");
					ln -s "$full_drive$inner_folder/$folder/"* "$active_folder"; # Link all files inside the folder to the link folder
				fi
			fi
		done
	fi
done

# Check if we should run the daemon
if [ "$daemonize" = true ]; then
	printf "Starting daemon...\n";

	# Set the parameters for inotifywait
	parameters="-m -e moved_to,moved_from,move,move_self,delete_self,create,delete";

	# Loop through linked folders and append them to the parameter list
	for linked_folder in "${linked_folders[@]}"; do
		parameters+=" $linked_folder";
	done

	# Execute inotifywait
	inotifywait $parameters |
	while read path action file; do
		link_path="$link_folder"/$(basename "$path")/"$file"; # Generate path of the file/folder just added
		action="${action%,ISDIR}"; # Remove ISDIR from action type - we don't care if it's a folder or file

		if [[ "$action" == "CREATE" || "$action" == "MOVED_TO" ]]; then # Check if a new file/folder needs to be linked
			# Check if the target file/folder doesn't exist already
			if [[ ! -d "$link_path" && ! -f "$link_path" ]]; then
				printf "\tLINK $file\n";
				ln -s "$path$file" "$link_path"; # Link the new file/folder
			else
				printf "\tIGNORE $file\n"; # Ignore the new file/folder (it already is linked)
			fi
		elif [[ "$action" == "DELETE" || "$action" == "MOVED_FROM" ]]; then # Check if a file/folder has been deleted
			# Check if link still exists
			if [ -L "$link_path" ]; then
				printf "\tUNLINK $file\n";
				unlink "$link_path"; # Unlink if it exists
			else
				printf "\tIGNORE $file\n"; # Ignore if it doesn't exist
			fi
		else
			printf "\tUNKNOWN $path $action $file\n"; # Received an unhandled inotifywait event
		fi
	done
fi
