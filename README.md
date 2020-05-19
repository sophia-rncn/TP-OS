============================================= SAUVEGARDE.SH =============================================
Groupe 31-3 : Hélène RECOTILLON & Sophia RANCON
TP Synthèse

----------------------------------------------Introduction----------------------------------------------

Le but de ce script est d'automatiser la synchronisation entre une partition chiffrée et un conteneur 
chiffré.

-----------------------------------------------Pré-requis-----------------------------------------------

1) Avoir un conteneur chiffré (Veracrypt)
	Si ce n'est pas le cas suivez les étapes suivantes :
		-> Installer Veracrypt
				sudo apt-get update 
				sudo apt-get upgrade
				wget https://launchpad.net/trunk/1.23/+download/veracrypt-1.23-setup.tar.bz2 (ou 
				télécharger sur le site)
				tar xjfv veracrypt-1.23-setup.tar.bz2
				Lancer l'installation qui vous convient (graphique ou console ; 64 ou 86)
		
		-> Créer un conteneur 
				Suivre l'installation en choisissant les options qui conviennent
				Exemple : Normal - /home/$USERNAME/nom_conteneur - 1GB - AES - SHA-512 - FAT -
				password - PIM - keyfile path 

2) Avoir une partition chiffrée avec dm-crypt et cryptsetup
	Si ce n'est pas le cas suivez les étapes suivantes :
		-> Utiliser GParted pour créer la partition chiffrée avec dm-crypt
				sudo apt-get update
				sudo apt-get upgrade
				sudo apt install gparted
			Suivre l'installation sur le logiciel, utiliser dm-crypt pour chiffrer la partition

		-> Utiliser Cryptsetup
			Installer cryptsetup : sudo apt-get install cryptsetup
			Création partition : sudo cryptsetup luksFormat /dev/sdaX (X = partition prévue plus haut)
			Ouverture : sudo cryptsetup luksOpen /dev/sdaX nom_partition
			Créer un dossier de montage : sudo mkdir point_montage
			Formatage : sudo mkfs.ext4 /dev/mapper/nom_partition
			Montage : sudo mount /dev/mapper/nom_partition point_montage
			Modif. user : sudo chown $USER:users point-montage -R
			Démontage : sudo umount point_montage (être dans le répertoire ../point_montage) 
			Fermeture : sudo cryptsetup luksClose nom_partition

3) Avoir veracrypt d'installé 
	Si ce n'est pas le cas veuillez vous référer à la section 1)

4) Avoir cryptsetup d'installé
	Si ce n'est pas le cas veuillez vous référer à la section 2) 

5) Avoir accès aux droits super utilisateurs (utilisation de sudo possible)

----------------------------------------------Utilisation----------------------------------------------

./Sauvegarde.sh [OPTS]

Voici les options possibles :

-h  --help  : Affiche l'aide
-c          : Synchronise toutes les données de la partition dans le conteneur
-p          : Synchronise toutes les données du conteneur dans la partition
-m          : Synchronise manuellement un fichier/dossier (conteneur <=> partition)
-o          : Ouvre la partition chiffrée et/ou le conteneur chiffré
-f          : Ferme la partition chiffrée et/ou le conteneur chiffré

--------------------------------------------Avertissements---------------------------------------------

-> Le script produit un fichier .log.txt dans le home de l'utilisateur, il permet de voir toutes les 
actions réalisées durant le déroulement de Sauvegarde.sh. Si vous ne voulez pas qu'on puisse avoir 
accès aux informations contenues à l'intérieur, veuillez le supprimer à chaque fois que vous éxécuter
 le script.

-> Si vous décidez d'ouvrir (grâce à Sauvegarde.sh -o) la partition chiffrée ou le conteneur chiffré, 
n'oubliez pas de relancer le script afin de les fermer (./Sauvegarde.sh -f). Dans le cas contraire, 
vos données pourront être à la portée d'un autre utilisateur ayant accès à votre home.

-> Si vous n'ouvrez pas votre conteneur chiffré ou votre partition chiffrée avec notre script, nous ne
 pourrons pas accéder à votre requête de les fermer correctement.

-> Lorsque vous procédez à une synchronisation de type -c ou -p, sachez que toutes les données sont
 synchronisées de l'un à l'autre. Si certaines données doivent rester inchangées, procédez à une 
 synchronisation manuelle de préférence.
