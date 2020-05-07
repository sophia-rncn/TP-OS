#!/bin/bash

# menu

function menu() {

	clear
	echo "===================================================== MENU ====================================================="
	echo "Tapez le caractère pour réaliser l'action que vous souhaitez :"
	echo "H : Affichage de l'aide"
	echo "C : Synchronisation automatique de toutes les données de la partition chiffrée dans le conteneur chiffré"
	echo "P : Synchronisation automatique de toutes les données du conteneur chiffré dans la partition chiffrée"
	echo "M : Synchronisation manuelle d un fichier ou d un dossier (partition chiffrée <=> conteneur chiffré) "
	echo "O : Ouverture de la partition chiffrée et/ou du conteneur"
	echo "F : Fermeture de la partition chiffrée et/ou du conteneur"
	echo "Q : Quitter le programme"

	read choix
	case $choix in

		# Si l utilisateur demande de l'aide
		h | H)
		help ;;

		# Si l utilisateur veut synchroniser la partition dans le conteneur
		c | C)
		synchronisationConteneur;;

		# Si l utilisateur veut synchroniser le conteneur dans la partition
		p | P)
		synchronisationPartition;;

		# Si l utilisateur veut synchroniser manuellement un fichier ou un dossier (partition <=> conteneur)
		m | M)
		synchronisationManuelle;;

		# Si l utilisateur veut ouvrir la partition chiffrée et/ou le conteneur chiffré
		o | O)
		open;;

		# Si l utilisateur veut fermer la partition chiffrée et/ou le conteneur chiffré
		f | F)
		close;;

		q | Q)
		exit 0;;

		*)
		echo "Vous vous êtes sûrement trompé de commande, veuillez réeesayer"
		sleep 2
		menu
	esac

}

#Affichage de l'aide

function help {

	clear
	echo "Entrée dans le menu aide" >> $LOG
	echo "================================================== AIDE ================================================== "
	echo "$0 [OPT]"
	echo "Vous pouvez ajouter les options suivantes afin de réaliser l'action de votre choix :"
	echo "-h | --help    : Affichage de l'aide"
	echo "-c             : Synchronisation automatique de toutes les données de la partition chiffrée dans le conteneur chiffré"
	echo "-p             : Synchronisation automatique de toutes les données du conteneur chiffré dans la partition chiffrée"
	echo "-m	     : Synchronisation manuelle d un fichier ou d un dossier (partition chiffrée <=> conteneur chiffré) "
	echo "-o | --open    : Ouverture de la partition chiffrée et/ou du conteneur"
	echo "-f | --close   : Fermeture de la partition chiffrée et/ou du conteneur"
	echo "Si vous ne mettez pas d'options vous serez redirigé vers le menu intéractif"
}

# openConteneur : Monte le conteneur sur le dossier /home/user/conteneurDossier

function openConteneur {

	echo "Entrée dans la fonction openConteneur" >> $LOG
	read -p " Remplissez le nom de votre conteneur (chemin absolu) " conteneurChemin

	veracrypt -l > tmp.txt 2>&1
	tmp=$( cat tmp.txt | cut -d ':' -f 1)
	sudo rm tmp.txt
	# Si le conteneur est déjà ouvert
	if [ "$tmp" == "1" ]; then
		echo "Le conteneur est déjà ouvert, veuillez le fermer et ré-éxécuté le script"
		echo "Le conteneur déjà ouvert, fermeture du script" >> $LOG
		exit 0;

	# Si le conteneur n'est pas ouvert
	else
		cd /home/$USERNAME
		sudo mkdir conteneurDossier
		veracrypt $conteneurChemin conteneurDossier
		echo "Conteneur ouvert" >> $LOG
	fi
}

# closeConteneur : Démonte le conteneur

function closeConteneur {

	echo "Entrée dans la fonction closeConteneur" >> $LOG

	veracrypt -l > tmp.txt 2>&1
	tmp=$( cat tmp.txt | cut -d ':' -f 1)
	sudo rm tmp.txt
	# Si le conteneur est ouvert
	if [ "$tmp" == "1" ]; then
		cd /home/$USERNAME
		veracrypt -d conteneurDossier

	# Si le conteneur est déjà fermé
	else
		echo "Le conteneur est déjà fermé" >> $LOG

	fi
}

# openPartition : Monte la partition sur le dossier /home/user/partitionDossier

function openPartition {

	echo "Entrée dans la fonction openPartition" >> $LOG
	read -p "Remplissez le numéro de la partion /dev/sdaX " partitionNum

	tmp=$(lsblk | grep -c "Luks8")

	# Si la partition n'est pas encore montée
	if [ "$tmp" == "0" ]; then
		cd /home/$USERNAME
		sudo mkdir partitionDossier
		sudo cryptsetup luksOpen /dev/sda$partitionNum Partition
		sudo mount /dev/mapper/Partition partitionDossier
		echo "Partition montée" >> $LOG

	# Si la partition est déjà montée
	else
		echo "Une partition est déjà montée, veuillez la fermer et ré-éxécuté le script"
		echo "Une partition est déjà montée, fermeture du script"  >> $LOG
		exit 0
	fi
}

# closePartition : Démonte la partition

function closePartition {

	echo "Entrée dans la fonction closePartition" >> $LOG

	tmp=$(lsblk | grep -c "Luks8")

	# Si la partition n'est pas montée
	if [ "$tmp" == "1" ]; then
		echo "La partition est déjà démontée, fermeture du script" >> $LOG
		exit 0

	# Si la partition est encore montée
	else
		sudo umount /home/$USERNAME/partitionDossier
		sudo cryptsetup luksClose Partition
		echo "Partition démontée" >> $LOG
	fi
}

# synchronisationConteneur : Synchronise le conteneur avec les données de la partition

function synchronisationConteneur {

	echo "Entrée dans la fonction synchronisationConteneur" >> $LOG
	openConteneur
	openPartition
	echo "Synchronisation partition à conteneur en cours" >> $LOG
	sudo rsync -r /home/$USERNAME/partitionDossier/ /home/$USERNAME/conteneurDossier
	echo "Synchronisation réalisée !" >> $LOG
	closePartition
	closeConteneur
	sudo rmdir /home/$USERNAME/conteneurDossier
	sudo rmdir /home/$USERNAME/partitionDossier
	echo "Suppression des dossiers de point de montage" >> $LOG
}

# synchronisationPartition : Synchronise la partition avec les données du conteneur

function synchronisationPartition {

	echo "Entrée dans la fonction synchronisationPartition" >> $LOG
	openConteneur
	openPartition
	echo "Synchronisation conteneur à partition en cours" >> $LOG
	sudo rsync -r /home/$USERNAME/conteneurDossier/ /home/$USERNAME/partitionDossier
	echo "Synchronisation réalisée !" >> $LOG
	closePartition
	closeConteneur
	sudo rmdir /home/$USERNAME/conteneurDossier
	sudo rmdir /home/$USERNAME/partitionDossier
	echo "Suppression des dossiers de point de montage" >> $LOG
}

# synchronisationManuelle : Synchronise uniquement les données mises en paramètres

function synchronisationManuelle {

	echo "Entrée dans la fonction synchronisationManuelle" >> $LOG
	echo "Dans quel sens voulez-vous faire la synchronisation ?"
	echo "1) Du conteneur à la partition"
	echo "2) De la partition au conteneur"
	read rep

	case $rep in

		# Si l utilisateur veut faire du conteneur à la partition
		1)
		echo "Attention à bien saisir les champs et à vérifier qu'ils existent bien !"
		read -p "Entrez le chemin absolu de votre fichier ou dossier source" src
		read -p "Entrez le chemin absolu de votre fichier ou dossier destination" dest
		echo "Synchronisation manuelle du conteneur vers la partition en cours" >> $LOG
		openConteneur ; openPartition
		sudo rsync -r /home/$USERNAME/conteneurDossier/$src /home/$USERNAME/partitionDossier/$dest
		echo "Synchronisation réalisée" >> $LOG
		closeConteneur
		closePartition
		sudo rmdir /home/$USERNAME/conteneurDossier
		sudo rmdir /home/$USERNAME/partitionDossier
		echo "Supression des dossiers de point de montage" >> $LOG;;

		# Si l utilisateur veut faire de la partition vers le conteneur
		2)
		echo "Attention à bien saisir les champs et à vérifier qu'ils existent bien !"
		read -p "Entrez le chemin absolu de votre fichier ou dossier source" src
		read -p "Entrez le chemin absolu de votre fichier ou dossier destination" dest
		echo "Synchronisation manuelle de la partition vers le conteneur en cours" >> $LOG
		openConteneur ; openPartition
		sudo rsync -r /home/$USERNAME/partitionDossier/$src /home/$USERNAME/conteneurDossier/$dest
		echo "Synchronisation réalisée" >> $LOG
		closeConteneur
		closePartition
		sudo rmdir /home/$USERNAME/conteneurDossier
		sudo rmdir /home/$USERNAME/partitionDossier
		echo "Supression des dossiers de point de montage" >> $LOG ;;

		*)
		echo "Vous n'avez choisi aucune des propositions acceptées, vous allez être redirigé vers le menu" ; sleep 3 ; menu ;;
	esac
}

# open : Ouvre la partition et/ou le conteneur

function open {

	echo "Entrée dans la fonction open" >> $LOG
	echo "Voulez-vous ouvrir la partition chiffrée (0), le conteneur chiffré (1) ou les deux (2) ?"
	read rep

	case $rep in

		# Si l utilisateur veut ouvrir la partition
		0)
		openPartition;;

		# Si l utilisateur veut ourvrir le conteneur
		1)
		openConteneur;;

		# Si l utilisateur veut ouvrir les 2
		2)
		openPartition ; openConteneur;;

		*)
		echo "Vous n'avez choisi aucune des propositions acceptées, vous allez être redirigé vers le menu" ; sleep 3 ; menu;;
	esac
}

# close : Ferme la partition chiffrée et/ou le conteneur

function close {

	echo "Entrée dans la fonction open" >> $LOG
	echo "Voulez-vous fermer la partition chiffrée (0), le conteneur chiffré (1) ou les deux (2) ?"
	read rep

	case $rep in

		# Si l utilisateur veut fermer la partition
		0)
		closePartition ; sudo rmdir partitionDossier; echo "Point de montage supprimé" >> $LOG;;

		# Si l utilisateur veut fermer le conteneur
		1)
		closeConteneur; sudo rmdir conteneurDossier; echo "Point de montage supprimé" >> $LOG;;

		# Si l utilisateur veut fermer les 2
		2)
		closePartition ; closeConteneur; sudo rmdir conteneurDossier ; sudo rmdir partitionDossier; echo "Points de montage supprimés" >> $LOG;;

		*)
		echo "Vous n'avez choisi aucune des propositions acceptées, vous allez être redirigé vers le menu" ; sleep 3 ; menu;;
	esac
}

# Initialisation fichier log

if [ -f /home/$USERNAME/log.txt ];
then
	echo "Fichier log.txt déjà créé, il va être effacé si vous ne quittez pas le programme sous 5s (Ctrl + C pour quitter)"
	sleep 1
fi

LOG="/home/$USERNAME/.log.txt"
echo "Fichier .log.txt" > $LOG
echo -e "Créé le $(date)" >> $LOG
echo -e "Script éxécuté : $O \n" >> $LOG

# Si l utilisateur n'a mis aucun argument -> menu interactif

if [ $# == 0 ]
then
	menu
fi

# Gestion des options


OPTS=$(getopt --options h,c,p,m,o,f,q: --long help,open,close,quit: --name "$0" -- "$@")

if [ $? != 0 ];
then
	help
	exit 1
fi

eval set -- "$OPTS"

for arg in $*; do

	case $arg in

		# Si l utilisateur demande de l'aide
		-h | --help)
		help;;

		# Si l utilisateur veut synchroniser les données de la partition dans le conteneur
		-c)
		synchronisationConteneur;;

		# Si l utilisateur veut synchroniser les données du conteneur dans la partition
		-p)
		synchronisationPartition;;

		# Si l utilisateur veut synchroniser manuellement un fichier ou un dossier (conteneur <=> partition)
		-m)
		synchronisationManuelle;;

		# Si l utilisateur veut ouvrir la partition chiffrée et/ou le conteneur chiffré
		-o | --open)
		open;;

		# Si l utilisateur veut fermer la partition chiffrée et/ou le conteneur chiffré
		-f | --close)
		close;;

	esac
done
