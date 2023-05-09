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

#permet de demander le volum,vérifier que le format démandé est bon mais aussi tester l'existence du disque
# on récupère le nom du volume dans la variable $volume, on teste si le volume existe

demande_volume () {
	echo 
	echo -e "Veuillez indiquer le volume souhaité (format sdx)"
	echo -e "Ou appuyer sur ctrl+c pour sortir"
	read volume
	if [[ -b /dev/$volume ]]
	then 
		echo "Le format est bon et le disque existe"
	else 	
		echo "Il semble que le disque n'existe pas ! " 
		exit 1
	fi
	}
#Nous permet de remonter le RAID quasiment automatiquement
remontage_manu () {
	demande_volume
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
	# Initialiser les tableaux
	vir=()
	part=()

# Stocker les résultats de la première colonne dans un tableau
	while read -r v1 _; do
  	vir+=("$v1")
	done < <(cat /proc/mdstat | grep md | awk '{print $1}' )

# Stocker les résultats de la deuxième colonne dans un tableau
	while read -r p2; do
  	part+=("$p2")
	done < <(cat /proc/mdstat | grep md | awk '{print $5}' | rev | cut -c4- | rev | sed "s/$volume_2//g")

	for i in "${!vir[@]}"; do
  		mdadm --add /dev/${vir[$i]} /dev/$volume${part[$i]}
	done
}
remontage_auto () {
	
# Initialiser les tableaux
	vir=()
	part=()

# Stocker les résultats de la première colonne dans un tableau
	while read -r v1 _; do
  	vir+=("$v1")
	done < <(cat /proc/mdstat | grep md | awk '{print $1}' )

# Stocker les résultats de la deuxième colonne dans un tableau
	while read -r p2; do
  	part+=("$p2")
	done < <(cat /proc/mdstat | grep md | awk '{print $5}' | rev | cut -c4- | rev | sed "s/$volume_2//g" )

	for i in "${!vir[@]}"; do
  		mdadm --add /dev/${vir[$i]} /dev/$volume${part[$i]}
	done
}
# Va permettre de lancer automatiquement NWIPE sur le disque demandé

formatage () {
	demande_volume
	clear
	echo "Choix de procédure"
	echo -e " A : Procédure automatisé (Pour remontage automatisé du RAID)"
	echo -e " M : Procédure manuelle (Expert Mode)"
	echo "Volume choisi : $volume"
	read -n1 -p "Faites votre choix :" optionformat_2
	
	case $optionformat_2 in
		a|A)
			echo "\n Poursuite procédure automatisé"
			nwipe --method=quick /dev/$volume
			copie_table_auto
			;;
		m|M)
			echo "\n Formatage en cours"
			nwipe --method=quick /dev/$volume
		
			echo -e "1 : Copier la table de parition"
			echo -e "2 : Arrêter le programme"
			read -n1 -p "Que voulez-vous faire ensuite ?" optionformat_1
		
			case $optionformat_1 in
				1)
					echo " \n Poursuite pour copier la table de partition"
					copie_table_manu
					;;
				2)
					echo "\n Arrêt du programme"
					exit;;
				*)
					echo "\n Mauvais choix veuilez choisir 1 ou 2"
					formatage
					;;
			esac
			;;
		*)
			echo "vous avez réalisé un mauvais choix"
			formatage
			;;
	esac
}

#Permet de copier automatiquement la table de partition (en ayant le volume sur lequel on doit copier)

copie_table_auto () {
	echo "Copie en cours"
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
	sgdisk /dev/$volume_2 -R /dev/$volume
	sgdisk -G /dev/$volume
	echo "Copie fini"
	remontage_auto
}

copie_table_manu () {
	echo "Copie en cours"
	volume_2=$(lsblk -o NAME,TYPE |  grep -v $volume | grep "disk" | awk '{print $1}')
	sgdisk /dev/$volume_2 -R /dev/$volume
	sgdisk -G /dev/$volume
	echo "Copie fini"
}

#Test si la table a des partitions, demande si on veut formater ou pas s'il y a des partitions sinon passe à l'étape suivante
	
test_table_parition () {
	demande_volume
	if [[ $(lsblk "/dev/$volume" | sed -n "/$volume[1-9]/p" | wc -l ) -gt 0 ]]; then
		echo "Le volume /dev/$demande_volume contient des partitions"
		echo "Voulez-vous le formater ?"
		echo -e "O : Oui"
		echo -e "N : Non"
		read -n1 -p "Veuillez choisir : " optionpart

		case $optionpart in
			o|O)
				echo -e "\n Le Formatage va débuter"
				nwipe /dev/$volume
				;;
			n|N)
				echo -e "\n Nous allons poursuivre"
				copie_table
				;;
			*)
				echo "\n Vous avez réalisé un mauvais choix"
				test_table_partition
				;;
		esac
	else
		echo "Le volume /dev/$volume ne contient pas de partitions"
		copie_table
	fi
	}

#Base de départ avec choix des différents points de départs voulus
#Et test de présence des différents logiciels nécessaires (nwipe et gdisk)

menu () {
	test=$( dpkg -l | grep nwipe )
	test_2=$( dpkg -l | grep gdisk)
	clear
	if [[ ! -z "$test" && ! -z "$test_2" ]]
	then
	echo "Les logiciels nécessaires sont bien installé"
	echo 
	echo -e "Que voulez-vous faire ?"
	echo -e "A : Remontage automatique complet (Recommandé)"
	
	echo "Mode expert, NE FAIRE QUE SI ON CONNAÎT"
	
	echo -e "F : Formater le nouveau disque dur"
	echo -e "C : Copier la table de partition"
	echo -e "R : Remonter le Raid"
	echo -e "S : Arrêter le programme"
	read -n1 -p "Veuillez choisir : " optionmenu
	
	case $optionmenu in
		a|A)
			echo -e "\n Remontage complet automatique"
			formatage
			;;
		f|F)
			echo -e "\n Formatage du nouveau disque"
			formatage
			;;
		c|C)
			echo -e "\n Copie table de parition"
			test_table_parition
			;;
		r|R)
			echo -e "\n Remontage raid"
			remontage_manu
			;;
		s|S)
			echo -e "\n Sortie du programme"
			exit;;
		*)
			echo -e "\n Erreur de frappe"
			menu;;
	esac
	else 
		echo "Les logiciels nécessaires ne sont pas installés"
		echo "L'installation va débuter"
		apt install gdisk
		apt install nwipe
		if dpkg -s gdisk &> /dev/null && dpkg -s nwipe &> /dev/null; then
			menu
		else 
			clear
			echo "Impossible d'installer les paquets vérifier que vous êtes connecté à internet"
			exit 1
		fi
	fi
	}

if [[ $(id -u) -ne 0 ]]
then
	echo "L'utilisateur doit être root"
	exit 1
else
	menu
fi
