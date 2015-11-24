#!/bin/bash
#########################################################################
# BACKUP Personal data based on Mike Rubel idea				#
#									#
# 3 FULL BACKUPs with hard links and minimum disk space usage.		#
# Space usage is close to 1 Full BACKUP plus 2 diferential backups.	#
# With hard links, all BACKUPS seems FULL BACKUPs. 			#
# This script also recycles the oldest backup to create the new one,	#
# reducing time creating the new one backup.				#
#									#
# This script should run montly.					#
# Author: Sefanitro (sefanitro@ebrenginy.com)				#
#########################################################################

unset PATH

#Commands
ID=/usr/bin/id
ECHO=/bin/echo
MOUNT=/bin/mount
RSYNC=/usr/bin/rsync
GREP=/bin/grep
DATE=/bin/date
RM=/bin/rm
MV=/bin/mv
CP=/bin/cp
TOUCH=/usr/bin/touch

SOURCEDOCS=/media/Qdocs
SOURCEDISK=/media/Qdisk

DESTDOCS=/BACKUP/Qdocs
DESTDISK=/BACKUP/Qdisk

FILELOGDOCS=/var/log/rsync/rsyncDocs.log.$($DATE +%Y%m)
FILELOGDISK=/var/log/rsync/rsyncDisk.log.$($DATE +%Y%m)

MOUNT_DEVICE=/dev/sdb3
BACKUP_RW=/BACKUP
EXCLUDES=/usr/local/etc/backup_excludes

#make sure we are root
if (( `$ID -u` != 0 )); then { $ECHO "Sorry, must be root.  Exiting..."; exit; } fi

#check if mount (and try to mount)
if ! $MOUNT | $GREP -q '/media/Qdocs'; then 
	$MOUNT $SOURCEDOCS;
	if (( $? )); then { $ECHO "No s'ha pogut montar $SOURCEDOCS"; exit; } fi
fi
if ! $MOUNT | $GREP -q '/media/Qdisk'; then
        $MOUNT $SOURCEDISK;
        if (( $? )); then { $ECHO "No s'ha pogut montar $SOURCEDISK"; exit; } fi
fi
 
#Remount RW
$MOUNT -o remount,rw $MOUNT_DEVICE $BACKUP_RW ;
if (( $? )); then
{
	$ECHO "backup: could not remount $BACKUP_RW readwrite";
	exit;
}
fi;

#Rotating backup based on Mikel Rubel idea per a QDOCS
# step 1: mv the oldest snapshot, to a temp directory
# instead of descarting the old one, we will used to create the new one backup. Much faster than discarting and creating from zero.
if [ -d $DESTDOCS/mensual.2 ] ; then { $RM -rf $DESTDOCS/mensual.2 ; } fi
if [ -d $DESTDISK/mensual.2 ] ; then { $RM -rf $DESTDISK/mensual.2 ; } fi

# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $DESTDOCS/mensual.1 ] ; then { $MV $DESTDOCS/mensual.1 $DESTDOCS/mensual.2 ; } fi
if [ -d $DESTDOCS/mensual.0 ] ; then { $MV $DESTDOCS/mensual.0 $DESTDOCS/mensual.1 ; } fi
if [ -d $DESTDISK/mensual.1 ] ; then { $MV $DESTDISK/mensual.1 $DESTDISK/mensual.2 ; } fi
if [ -d $DESTDISK/mensual.0 ] ; then { $MV $DESTDISK/mensual.0 $DESTDISK/mensual.1 ; } fi


# step 3: make a hard-link-only (except for dirs) copy of the latest snapshot,
# if that exists
if [ -d $DESTDOCS/setmanal.2 ] ; then { $CP -al $DESTDOCS/setmanal.2 $DESTDOCS/mensual.0 ; } fi
if [ -d $DESTDISK/setmanal.2 ] ; then { $CP -al $DESTDISK/setmanal.2 $DESTDISK/mensual.0 ; } fi

$MOUNT -o remount,ro $MOUNT_DEVICE $BACKUP_RW ;
if (( $? )); then
{
	$ECHO "backup: could not remount $BACKUP_RW readonly";
	exit;
} fi;

