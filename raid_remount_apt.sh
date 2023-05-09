#!/bin/bash
#
#Author : Alexandre L
#Created : 26/04/2023
#Version : 1.0 (apt version)
# This file is part of RAID remount.
#
# RAID remount is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
#any later version.
#
# RAID remount is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with RAID remount.  If not, see <https://www.gnu.org/licenses/>.

#
# Standard Disclaimer: Author assumes no liability for any damage.
# Clause de non-responsabilité standard : l'auteur n'assume aucune responsabilité en cas de dommages.
#

# ask for a disk, check his existence and the format 
# we use the variable $volume to keep the information about the volume

demande_volume () {
	echo 
	echo -e "Please indicate the desired volume (format sdx)"
	echo -e "Or press ctrl+c to exit"
	read volume
	if [[ -b /dev/$volume ]]
	then 
		echo "Format is good and disk exist"
	else 	
		echo "it seems that the disk doesn't exist" 
		exit 1
	fi
	}
# Able us to remount the RAID automatically
remontage_manu () {
	demande_volume
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
# Array init
	vir=()
	part=()

# Store the result of the firt column in an array
	while read -r v1 _; do
  	vir+=("$v1")
	done < <(cat /proc/mdstat | grep md | awk '{print $1}' )

# Store the result of the second column in an array and remount the raid
	while read -r p2; do
  	part+=("$p2")
	done < <(cat /proc/mdstat | grep md | awk '{print $5}' | rev | cut -c4- | rev | sed "s/$volume_2//g")

	for i in "${!vir[@]}"; do
  		mdadm --add /dev/${vir[$i]} /dev/$volume${part[$i]}
	done
}
remontage_auto () {
	
# Array init
	vir=()
	part=()

# Store the result of the firt column in an array
	while read -r v1 _; do
  	vir+=("$v1")
	done < <(cat /proc/mdstat | grep md | awk '{print $1}' )

# Store the result of the second column in an array and remount the raid
	while read -r p2; do
  	part+=("$p2")
	done < <(cat /proc/mdstat | grep md | awk '{print $5}' | rev | cut -c4- | rev | sed "s/$volume_2//g" )

	for i in "${!vir[@]}"; do
  		mdadm --add /dev/${vir[$i]} /dev/$volume${part[$i]}
	done
}
# Launch NWIPE for the desire volume

formatage () {
	demande_volume
	clear
	echo "Choice of process"
	echo -e " A : automated process (for automated remount of the RAID)"
	echo -e " M : manual process (Expert Mode)"
	echo "Selected volume : $volume"
	read -n1 -p "make your choice :" optionformat_2
	
	case $optionformat_2 in
		a|A)
			echo "\n Poursuite procédure automatisé"
			nwipe --method=quick /dev/$volume
			clear
			copie_table_auto
			;;
		m|M)
			echo "\n Formatage en cours"
			nwipe --method=quick /dev/$volume
			clear
		
			echo -e "1 : Copying the partition table"
			echo -e "2 : Stop the program"
			read -n1 -p "What do you want to do ?" optionformat_1
		
			case $optionformat_1 in
				1)
					echo " \n Continue to copy the partition table"
					copie_table_manu
					;;
				2)
					echo "\n Stopping the program"
					exit;;
				*)
					echo "\n Bad choice choose 1 or 2"
					formatage
					;;
			esac
			;;
		*)
			echo "You make a bad  choice"
			formatage
			;;
	esac
}

# Copy the partition table in volume 

copie_table_auto () {
	echo "Copy in progress"
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
	sgdisk /dev/$volume_2 -R /dev/$volume
	sgdisk -G /dev/$volume
	echo "Copy ended"
	remontage_auto
}

copie_table_manu () {
	echo "Copy in progress"
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
	sgdisk /dev/$volume_2 -R /dev/$volume
	sgdisk -G /dev/$volume
	echo "Copy ended"
}

#test if the disk contains partitions, ask if we want to formate or not, if not go to the next step
	
test_table_parition () {
	demande_volume
	if [[ $(lsblk "/dev/$volume" | sed -n "/$volume[1-9]/p" | wc -l ) -gt 0 ]]; then
		echo "Volume /dev/$demande_volume contains partitions"
		echo "Do you want to formate ?"
		echo -e "O : Yes"
		echo -e "N : No"
		read -n1 -p "Make a choice : " optionpart

		case $optionpart in
			o|O)
				echo -e "\n Formatting will start"
				nwipe /dev/$volume
				;;
			n|N)
				echo -e "\n We keep going"
				copie_table
				;;
			*)
				echo "\n You make a bad choice"
				test_table_partition
				;;
		esac
	else
		echo "Volume /dev/$volume do not contains partitions"
		copie_table
	fi
	}

# Start of all the program
# Test of the different program needed (nwipe et gdisk)

menu () {
	test=$( dpkg -l | grep nwipe )
	test_2=$( dpkg -l | grep gdisk)
	clear
	if [[ ! -z "$test" && ! -z "$test_2" ]]
	then
	echo "Necessary software are installed"
	echo 
	echo -e "What do you want to do ?"
	echo -e "A : Full automatic reassembly (Recommended)"
	
	echo "Expert Mode, DO ONLY IF YOU KNOW"
	
	echo -e "F : Formate new disk"
	echo -e "C : Copy partition table"
	echo -e "R : Remount the Raid"
	echo -e "S : Stop the program"
	read -n1 -p "Make a choice : " optionmenu
	
	case $optionmenu in
		a|A)
			echo -e "\n Full automatic reassembly"
			formatage
			;;
		f|F)
			echo -e "\n Formatting the new disk"
			formatage
			;;
		c|C)
			echo -e "\n copy partition table"
			test_table_parition
			;;
		r|R)
			echo -e "\n Remount raid"
			remontage_manu
			;;
		s|S)
			echo -e "\n Exit the program"
			exit;;
		*)
			echo -e "\n Typing error"
			menu;;
	esac
	else 
		echo "Necessary software are not installed"
		echo "Installation begin"
		apt install gdisk
		apt install nwipe
		if dpkg -s gdisk &> /dev/null && dpkg -s nwipe &> /dev/null; then
			menu
		else 
			clear
			echo "Unable to install packages, please check your connection"
			exit 1
		fi
	fi
	}
	
if [[ $(id -u) -ne 0 ]]
then
	echo "You need to be root"
	exit 1
else
	menu
fi
