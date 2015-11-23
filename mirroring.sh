#!/bin/bash
#################################################################################
#	MIRROR Backup de les dades de NETETA assumint:					#
#NO es fa còpia de Qmultimedia							#
#Mirror permanent de Qfotos
#Mirror permanent de Qprogs (pentent)
#BACKUPs circulars (Setmanals i Mensuals) de Qdocs i Qdisk (pendent)

unset PATH #Es recomana per evitar mals usos

#Definim comandes
ID=/usr/bin/id
ECHO=/bin/echo
MOUNT=/bin/mount
RSYNC=/usr/bin/rsync
GREP=/bin/grep
DATE=/bin/date

SOURCEFOTOS=/media/Qfotos/
SOURCEPROGS=/media/Qprogs/

DESTFOTOS=/BACKUP/Qfotos/
DESTPROGS=/BACKUP/Qprogs/

FILELOGFOTOS=/var/log/rsync/rsyncFotos.log.$($DATE +%Y%m)
FILELOGPROGS=/var/log/rsync/rsyncProgs.log.$($DATE +%Y%m)

MOUNT_DEVICE=/dev/sdb3;
BACKUP_RW=/BACKUP;

#Make sure we are root
if (( `$ID -u` != 0 )); then { $ECHO "Sorry, must be root.  Exiting..."; exit; } fi

#Check if mount (and try to mount)
if ! $MOUNT | $GREP -q '/media/Qfotos'; then 
	$MOUNT $SOURCEFOTOS;
	if (( $? )); then { $ECHO "[MIRRORING]: ERROR mounting $SOURCEFOTOS"; exit; } fi
fi
if ! $MOUNT | $GREP -q '/media/Qprogs'; then
        $MOUNT $SOURCEPROGS;
        if (( $? )); then { $ECHO "[MIRRORING]: ERROR mounting $SOURCEPROGS"; exit; } fi
fi
 
#Remount Backup disk RW
$MOUNT -o remount,rw $MOUNT_DEVICE $BACKUP_RW ;
if (( $? )); then
{
	$ECHO "[MIRRORING]: ERROR. Could not remount $BACKUP_RW readwrite";
	exit;
}
fi;

#Mirror SOURCE1 (FOTOS)
$ECHO '--------------------------------------------------' >> $FILELOGFOTOS
$ECHO $($DATE "+%b %d %H:%M:%S")'. Iniciem la sincronització de les Fotos...' >> $FILELOGFOTOS 
$RSYNC --delete -avz $SOURCEFOTOS $DESTFOTOS >> $FILELOGFOTOS 2>&1
$ECHO $($DATE "+%b %d %H:%M:%S")'. Finalitzem la sincronització de les Fotos...' >> $FILELOGFOTOS
$ECHO '--------------------------------------------------' >> $FILELOGFOTOS

#Mirror SOURCE2 (PROGS)
$ECHO '--------------------------------------------------' >> $FILELOGPROGS
$ECHO $($DATE "+%b %d %H:%M:%S")'. Iniciem la sincronització de PROGS...' >> $FILELOGPROGS
$RSYNC --delete -avz $SOURCEPROGS $DESTPROGS >> $FILELOGPROGS 2>&1
$ECHO $($DATE "+%b %d %H:%M:%S")'. Finalitzem la sincronització de PROGS...' >> $FILELOGPROGS
$ECHO '--------------------------------------------------' >> $FILELOGPROGS

#Now mount BACKUP disk read only
$MOUNT -o remount,ro $MOUNT_DEVICE $BACKUP_RW ;
if (( $? )); then
{
	$ECHO "[MIRRORING]: ERROR. Could not remount $BACKUP_RW readonly"
	exit;
} fi;

