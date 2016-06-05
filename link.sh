#!/bin/bash

DRIVE_FOLDER="/media";
LINK_FOLDER="/media/pool";
INNER_FOLDER="media";

DRIVE_EXCEPTIONS=("pool");

CLEAR_FIRST=false;

if [ "$CLEAR_FIRST" = true ]; then
	printf "CLEARING\n";
	rm -rf $LINK_FOLDER/*;
fi

for full_drive in $DRIVE_FOLDER/*/; do
	drive="$(basename $full_drive)";
	skip=false;

	for exception in "${DRIVE_EXCEPTIONS[@]}"; do
		if [ "$drive" == "$exception" ]; then
			skip=true;
			break;
		fi
	done

	if [ "$skip" = false ]; then
		printf "HANDLE $drive\n";

		for full_folder in $full_drive$INNER_FOLDER/*/; do
			folder="$(basename $full_folder)";
			active_folder=$LINK_FOLDER/$folder;

			if [ ! -d "$active_folder" ]; then
				printf "\tCREATE $folder\n";
				mkdir -p $active_folder;
			else
				printf "\tIGNORE $folder\n";
			fi

			if [[ -L "$active_folder/$drive" && -d "$active_folder/$drive" ]]; then
				printf "\t\tIGNORE $drive\n";
			else
				printf "\t\tLINK $drive\n";
				ln -s $full_drive$INNER_FOLDER/$folder $active_folder/$drive;
			fi
		done
	fi
done
