# RAID_remount
## Bash script which able you to remount automaticly your RAID1  
![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=flat&logo=gnu-bash&logoColor=white)  
YUM Version released
<br>Next update in progress..<br>

## Dependances
I'm currently using 3 programs for my script.
* MDADM this program is used for remount the RAID.
* GDISK and SGDISK to copy the partition table form disk 1 to disk 2.
* NWIPE to wipe the disk 2 to ensure that it is empty.  

## Future of code
When the first version will be release, I will work on 2 diferent ways :  
* Other RAID   
  I will working on the capacity of my code to be usefull for other RAID than only RAID 1.  
  This means implementing RAID 0, 5, and 10.
* Improving the code  
  Improve error feedback and enforce root user verification. 
    * exit when nwipe or sgidsk error append + log  
  Take useful code elements from nwipe and gdisk and integrate them into my own code.  
