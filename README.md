# drive-linker
## Introduction
Drive linker is a bash script written for Ubuntu (should work on other distros just fine) which allows you to pool multiple drives into a single big pool where all of your files sit.

The script uses only plain symlinks to achieve this which means that it a) doesn't require any additional CPU power like a FUSE module does and b) doesn't slow down write/read operations because it's connected directly to the source drive.

It should be noted, that this is not a complete replacement for mhddfs or UnionFS. You might require to be able to write to the pooled storage and while this works with the current implementation I can't recommend it.
If you want to know if this is the right thing for you, give it a try. Depending on your requirements it might be just the right thing for you.

## Prerequisites
The script requires a operating system which is able to interpret shell scripts as well as the **ln** utility for creating symbolic links and the **inotifywait** utility for watching directories. inotifywait is only required when using the merge mode with activated daemon.

## How does it work?
Drive linker has two modes:
* Merge mode
* Drive mode

For explaining how both modes work, lets assume you have two drives mounted inside /drives. The script works with any amount of drives and any path though.

Here is what your existing folder structure might look like:
* drives
  * drive1
    * media
      * movies
      * shows
  * drive2
    * media
      * movies
      * shows

Merge mode will convert above structure to the following:
* drives
  * pool
    * movies
      * All your movies from drive1 & drive2
    * shows
      * All your shows from drive1 & drive2

Drive mode will convert the structure from above to the following:
* drives
  * pool
    * movies
      * drive1
        * Movies from drive1
      * drive2
        * Movies from drive2
    * shows
      * drive1
        * Shows from drive1
      * drive2
        * Shows from drive2

Each mode has their advantages and disadvantages, in short:
* Merge mode
  * No duplicate folders/files possible
  * Requires a daemon to keep links updated incase the source drives change
  * Works with application that require everything to be in a single folder
* Drive mode
  * Allows duplicates
  * Doesn't require a daemon since media folders don't change that often (movies, shows, ...)
  * Doesn't work with applications like Plex that require everything to be in the root folder

Depending on your requirements you can pick one of these.

## Installation

Installation is simple. Just clone this repository:
```
git clone https://github.com/DomiStyle/drive-linker.git
cd drive-linker
```
...and allow execution of the script:
```
chmod +x link.sh
```
If you have lots of folders/files to keep track of you might need to increase the maximum amount of possible inotify watches. You can edit the amount inside of /proc/sys/fs/inotify/max_user_watches. This is only necessary if you plan to run the daemon since it needs to watch your folders for changes.

## Configuration

Below is a description of every configuration field. To configure drive linker simply open config.sh in your favorite text editor.

```
drive_folder="/media";
```
drive_folder determines where your drives are mounted. In the example from above this would be /drives.
Please note that every drive should be in this folder - no subfolders!
Read/write permissions of these files/folders are carried over so change them accordingly.

```
link_folder="/media/pool";
```
link_folder determines where your pooled drives are stored at. It's possible to place this in the same folder as your drive or a different location.
Make sure the user you are running this script as has read/write permissions for this folder.

```
inner_folder="media";
```
The inner folder is the root folder on every drive to use. Pooling of the whole drive is currently not supported, please make sure there is atleast one folder on the drive (media, data, storage, ...).

```
drives=("drive1" "drive2" "drive3" "drive4");
```
A list of drives to pool together. You can use this to blacklist drives/folders you don't want in the pool like backup drives or the pool folder itself.

```
folders=("movies" "shows");
```
A list of folders inside the inner folder to pool together. You can use this to create multiple pools of different media.
For example: start the script twice with different link folders and use one to link together your movies and TV shows while the other pools together your anime collection.

```
create_drive_folders=false;
```
Setting this to true will enable drive mode (see above). Setting it to false will enable merge mode (default, see above).

```
daemonize=false;
```
Because merge mode will require active updating of the links you can enable it here. Incase the files/folders are not updated that often you can disable the daemon and simply update your pool by executing the script again when needed.
Enabling the daemon while create_drive_folders is set to true will result in an error. Drive mode only allows manual updates right now.

```
clear_links=false;
```
Setting this to true will delete everything inside of your link folder upon every start of this script.
This might be useful if the daemon is not enabled and you want to remove old symlinks which are already outdated.
Please make sure you have set your link folder correctly or otherwise you might risk losing some of your data!

## So, what's the big deal?
If you ever worked with multiple drives but didn't want to use anything like ZFS, RAID or LVM to pool your drives together and are now stuck with mhddfs or UnionFS then this is a good alternative for you.
It uses less resources for creating the links and uses no additional resources at all when reading/writing as it's done through plain symlinks.
It also allows you to simply add another drive in your config.sh and the script will automatically pull the whitelisted folders from it - no additional work required. Comparing that to adding your new drive to every application that uses all your drives makes it a really useful tool.
