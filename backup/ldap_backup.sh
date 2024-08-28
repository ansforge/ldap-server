#!/bin/bash
echo "Démarrage du script de sauvegarde du LDAP de la Forge ANS"
#############################################################################
# Nom du script     : ldap-backup.sh
# Auteur            : E.RIEGEL (QM HENIX)
# Date de Création  : 15/12/2022
# Version           : 1.0.0
# Descritpion       : Script permettant la sauvegarde du LDAP de la Forge ANS
#
# Historique des mises à jour :
#-----------+--------+-------------+------------------------------------------------------
#  Version  |   Date   |   Auteur     |  Description
#-----------+--------+-------------+------------------------------------------------------
#  0.0.1    | 15/12/22 | E.RIEGEL     | Initialisation du script
#-----------+--------+-------------+------------------------------------------------------
#  0.0.2    | 21/09/23 | Y.ETRILLARD      | Modification du nom du JOB
#-----------+--------+-------------+------------------------------------------------------
#  1.0.0    | 28/08/24 | M. FAUREL   | Modification de la casse du path et timestamp
#-----------+--------+-------------+------------------------------------------------------
#
###############################################################################################

. /root/.bash_profile

# Configuration de base: datestamp e.g. YYYYMMDD
DATE=$(date +"%Y%m%d")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Dossier où sauvegarder les backups
BACKUP_DIR="/var/backup/ldap"

# Commande NOMAD
#NOMAD=/usr/local/bin/nomad
NOMAD=$(which nomad)

#LDAP PATH To BACKUP in the container
LDAP_PATH=/bitnami
#Archive Name of the backup LDAP directory
BACKUP_REPO_FILENAME="backup_ldap_${DATE}.tar.gz"


# Nombre de jours à garder les dossiers (seront effacés après X jours)
RETENTION=10

# ---- NE RIEN MODIFIER SOUS CETTE LIGNE ------------------------------------------
#
# Create a new directory into backup directory location for this date
mkdir -p $BACKUP_DIR/$DATE

# Backup LDAP
echo "${TIMESTAMP} Starting backup ldap..."

$NOMAD exec -task openldap -job  openldap-forge tar -cOzv -C $LDAP_PATH openldap > $BACKUP_DIR/$DATE/$BACKUP_REPO_FILENAME
BACKUP_RESULT=$?
if [ $BACKUP_RESULT -gt 1 ]
then
        echo "${TIMESTAMP} Backup LDAP failed with error code : ${BACKUP_RESULT}"
        exit 1
else
        echo "${TIMESTAMP} Backup LDAP done"
fi

# Remove files older than X days
find $BACKUP_DIR/* -mtime +$RETENTION -exec rm -rf {} \;

echo "${TIMESTAMP} Backup LDAP finished"
