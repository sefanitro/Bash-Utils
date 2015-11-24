#!/bin/bash
#########################################################################
# BACKUP Personal data based on Mike Rubel idea				#
#									#
# 3 FULL BACKUPs with hard links and minimum disk space usage.		#
# Space usage is close to 1 Full BACKUP plus 3 diferential backups.	#
# With hard links, all BACKUPS seems FULL BACKUPs. 			#
# This script also recycles the oldest backup to create the new one,	#
# reducing time creating the new one backup.				#
#									#
# You can use cron or anacron to run it periodically.			#
# I run it diary.				 			#
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
if [ -d $DESTDOCS/diari.2 ] ; then { $MV $DESTDOCS/diari.2 $DESTDOCS/diari.tmp ; } fi
if [ -d $DESTDISK/diari.2 ] ; then { $MV $DESTDISK/diari.2 $DESTDISK/diari.tmp ; } fi


# step 2: shift the middle snapshots(s) back by one, if they exist
if [ -d $DESTDOCS/diari.1 ] ; then { $MV $DESTDOCS/diari.1 $DESTDOCS/diari.2 ; } fi
if [ -d $DESTDOCS/diari.0 ] ; then { $MV $DESTDOCS/diari.0 $DESTDOCS/diari.1 ; } fi
if [ -d $DESTDISK/diari.1 ] ; then { $MV $DESTDISK/diari.1 $DESTDISK/diari.2 ; } fi
if [ -d $DESTDISK/diari.0 ] ; then { $MV $DESTDISK/diari.0 $DESTDISK/diari.1 ; } fi
# step 2b: shit the old one to the new one.
if [ -d $DESTDOCS/diari.tmp ] ; then { $MV $DESTDOCS/diari.tmp $DESTDOCS/diari.0 ; } fi
if [ -d $DESTDISK/diari.tmp ] ; then { $MV $DESTDISK/diari.tmp $DESTDISK/diari.0 ; } fi

# step 3: make a hard-link-only (except for dirs) copy of the latest snapshot,
# if that exists
if [ -d $DESTDOCS/diari.0 ] ; then { $CP -al $DESTDOCS/diari.1 $DESTDOCS/diari.0 ; } fi
if [ -d $DESTDISK/diari.0 ] ; then { $CP -al $DESTDISK/diari.1 $DESTDISK/diari.0 ; } fi


# step 4: rsync from the system into the latest snapshot (notice that
# rsync behaves like cp --remove-destination by default, so the destination
# is unlinked first.  If it were not so, this would copy over the other
# snapshot(s) too!

$ECHO '--------------------------------------------------' >> $FILELOGDOCS
$ECHO $($DATE "+%b %d %H:%M:%S")'. Iniciem el BACKUP setmanal de DOCS...' >> $FILELOGDOCS
$RSYNC --delete -av --delete-excluded --exclude-from="$EXCLUDES" $SOURCEDOCS $DESTDOCS/setmanal.0 >> $FILELOGDOCS 2>&1
$ECHO $($DATE "+%b %d %H:%M:%S")'. Finalitzem el BACKUP setmanal de DOCS...' >> $FILELOGDOCS
$ECHO '--------------------------------------------------' >> $FILELOGDOCS

$ECHO '--------------------------------------------------' >> $FILELOGDISK
$ECHO $($DATE "+%b %d %H:%M:%S")'. Iniciem el BACKUP setmanal de DISK...' >> $FILELOGDISK
$RSYNC --delete -av --delete-excluded --exclude-from="$EXCLUDES" $SOURCEDISK $DESTDISK/setmanal.0 >> $FILELOGDISK 2>&1
$ECHO $($DATE "+%b %d %H:%M:%S")'. Finalitzem el BACKUP setmanal de DISK...' >> $FILELOGDISK
$ECHO '--------------------------------------------------' >> $FILELOGDISK

# step 5: update the mtime of setmanal.0 to reflect the snapshot time
$TOUCH $DESTDOCS/diari.0 
$TOUCH $DESTDISK/diari.0 

$MOUNT -o remount,ro $MOUNT_DEVICE $BACKUP_RW ;
if (( $? )); then
{
	$ECHO "backup: could not remount $BACKUP_RW readonly";
	exit;
} fi;

