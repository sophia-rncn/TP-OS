
#!/bin/bash

# menu

function menu {

	clear
	echo -e  "=========================================== MENU ===========================================\n"
	echo "Tapez le caractère pour afficher les informations de votre choix :"
	echo "H : Affichage de l'aide"
	echo "S : Système utilisé et l'utilisateur connecté"
	echo "R : Ressources utilisées"
	echo "W : Erreurs et warnings au démarrage"
	echo "Q : Quitter le programme"

	read choix
	case $choix in

		# Si l utilisateur demande de l aide
		h | H)
		help;;

		# Si l utilisateur veut connaitre le systeme utilisé et le user actuel
		s | S)
		systeme ;;

		# Si l utilisateur veut connaitre l etat des ressources
		r | R)
		ressources ;;

		# Si l utilisateur veut connaitre les erreurs ou warnings
		w | W)
		warning ;;

		# Si l utilisateur veut quitter l interface
		q | Q)
		exit 0;;

		*)
		echo "L'option '$arg' saisie n'est pas reconnue" ; help ;;

	esac
}

# help : Affiche l aide à l utilisateur

function help {

	clear
	echo "Entrée dans le menu aide" >> $LOG
	echo -e  "============================================= AIDE =============================================\n"
	echo "$0 [OPT]"
	echo "Vous pouvez ajouter les options suivantes afin d'afficher les informations qui vous intéressent:"
	echo "-h | --help       : Affichage de l'aide"
	echo "-s | --systeme    : Système utilisé et l'utilisateur connecté"
	echo "-r | --ressources : Ressources utilisées"
	echo "-w | --warnings   : Erreurs et warnings au démarrage"
	echo "Si vous ne mettez pas d'options vous serez redirigé vers le menu intéractif"
}

# systeme : Affiche le systeme d exploitation et l utilisateur actuellement connecté

function systeme {

	clear
	echo "Entrée dans le menu systeme" >> $LOG
	set $(uname -no)
	echo "Voici le système d'exploitation utilisé actuellement : $1 $2"
	echo "L'utilisateur actuellement connecté est $USERNAME"
	uname -no >> $LOG
	echo "$USERNAME" >> $LOG
}

# ressources : Affiche les ressources du PC dynamiquement

function ressources {

	clear
	echo "Entrée dans le menu ressource" >> $LOG

	# Si glances n est pas installé sur l ordinateur
	if ! which glances > /dev/null;
	then
	top -b | head -n 12 | tail -n 6

	# Si le package est installé
	else
	glances
	echo "Utilisation de glances" >> $LOG

	fi
	echo "Ressources utilisées :" >> $LOG
	top -b | head -n 12 | tail -n 6 >> $LOG
}

# warning : Affiche les erreurs critiques et warnings au démarrage

function warning {

	clear
	echo "Entrée dans le menu warning" >> $LOG
	echo "Erreurs critiques au démarrage :"
	journalctl -b -p err
	echo "Warnings au démarrage : "
	dmesg --level=warn

	journalctl -b -p err >> $LOG
	dmesg --level=warn >> $LOG
}


# Initialisation fichier log

if [ -f /home/$USERNAME/log.txt ];
then
	echo "Fichier log.txt déjà créé, il va être effacé si vous ne quittez pas le programme sous 5s (Ctrl + C pour quitter)"
	sleep 5
fi

LOG="/home/$USERNAME/.log.txt"
echo "Fichier log.txt" > $LOG
echo -e "Créé le $(date)" >> $LOG
echo -e "Script éxécuté : $0 \n" >> $LOG

# Si l utilisateur n'a mis aucun argument -> menu interactif

if [ $# == 0 ];
then
	menu
fi

# Gestion des options

OPTS=$(getopt --options h,s,w,r,q: --long help,systeme,ressources,warnings,quit: --name "$0" -- "$@")

if [ $? != 0 ]
then
	help
	exit 1
fi

eval set -- "$OPTS"

for arg in $*; do

	case $arg in

		# Si l utilisateur demande de l aide
		-h | --help)
		help;;

		# Si l utilisateur veut connaitre le systeme utilisé et le user actuel
		-s | --systeme)
		systeme ;;

		# Si l utilisateur veut connaitre l etat des ressources
		-r | --ressources)
		ressources ;;

		# Si l utilisateur veut connaitre les erreurs ou warnings
		-w | --warnings)
		warning ;;

		--)
		break;;

		*)
		echo "L'option '$arg' saisie n'est pas reconnue, vous allez être redirigé vers l'aide" ; sleep 3 ; echo "Mauvais argument redirection aide" >> $LOG ;  help ;;

	esac
done

