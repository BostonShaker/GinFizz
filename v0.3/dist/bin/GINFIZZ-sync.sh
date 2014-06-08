#!/bin/bash

# Copyright (c) 2014, K.-H. Hofacker, Hamburg, Germany. All rights reserved.
# This is free software, licensed under the 'BSD 2-Clause License'.
# See file 'copyright.txt' for details.

PRGRM="GINFIZZ"
PRGRM_VER="0.3"
SCRIPT_VER="${PRGRM_VER}.0"
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR=""
EXIT_CD=0

LOG_FULL=${TMPDIR}/${PRGRM}-sync.log
LOG_TEMP=${LOG_FULL}.tmp
TMP_MOUNT=0
LOG_STATUS=""
CLOC=""

# *** iI18n ***

LocTx()
{
   # language specific text definitions

   if [ -z "${CLOC}" ]; then
      CLOC="$(echo "${LANG}" | grep -oE "[a-z]{2}_[A-Z]{2}" | grep -oE "^[a-z]{2}" 2>/dev/null)"
   fi

   case "${CLOC}" in
      de)
         case "$1" in
            E_Close)   echo "Das Schließen des Cloud-Zugriffs via '${DIR_CLOUD}' ist gescheitert." ;;
            E_Copy)    echo "Der Kopiervorgang von '${DIR_CLOUD}' nach '${DIR_CHIPHER}' ist gescheitert." ;;
            E_Fail)    echo "Die Synchronisation ist gescheitert (Fehlerkode '${UNI_CD}')." ;;
            E_Install) echo "${PRGRM} ist nicht oder nur unvollständig installiert." ;;
            E_Net)     echo "Es besteht keine Verbindung zum Internet." ;;
            E_Open)    echo "Das Öffnen des Cloud-Zugriffs via '${DIR_CLOUD}' ist gescheitert." ;;
            E_Title)   echo "${PRGRM}: FEHLER bei der Synchronisation" ;;
            E_Unknown) echo "Unbekannter Fehler!?" ;;
            M_Copy)    echo "Das lokale Verzeichnis '${DIR_CHIPHER}' ist leer. Der Inhalt des Cloud-Verzeichnisses '${DIR_CLOUD}' wird einmalig auf diesen Rechner kopiert. Dieser Vorgang kann einige Minuten dauern." ;;
            M_CopyOk)  echo "Alle Daten aus der Cloud wurden erfolgreich kopiert." ;;
            M_NoData)  echo "Keine neuen oder veränderten Dateien gefunden." ;;
            M_Sync)    echo "Synchronisation gestartet..." ;;
            M_Title)   echo "${PRGRM}: Synchronisation" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Rückgabewert ist '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Start..." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_Close)   echo "Failed to close cloud access through directory '${DIR_CLOUD}'." ;;
            E_Copy)    echo "Failed to copy data from '${DIR_CLOUD}' to '${DIR_CHIPHER}'." ;;
            E_Fail)    echo "Synchronization failure, error code is '${UNI_CD}'." ;;
            E_Install) echo "${PRGRM} is not installed correctly." ;;
            E_Net)     echo "No internet access." ;;
            E_Open)    echo "Failed to open cloud access through directory '${DIR_CLOUD}'." ;;
            E_Title)   echo "${PRGRM}: Synchronization ERROR" ;;
            E_Unknown) echo "Unknown error!?" ;;
            M_Copy)    echo "The local directory '${DIR_CHIPHER}' is empty. The cloud data from '${DIR_CLOUD}' will now be copied once to this computer. This may take some time." ;;
            M_CopyOk)  echo "All cloud data successfully copied to this computer." ;;
            M_NoData)  echo "No new or modified files found." ;;
            M_Sync)    echo "Synchronization started..." ;;
            M_Title)   echo "${PRGRM}: Synchronization" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) exit code is '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Begin..." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;
   esac
}

# *** Worker ***

CheckInstall()
{
   # check if PRGRM is installed

   if [ -d "${DIR_DATA}" ]; then
      return 0
   else
      return 1
   fi
}

CheckInternet()
{
   # check for Internet access

   ping -c 1 -w 3 -q 8.8.8.8 > /dev/null 2>&1

   if [ $? -eq 0 ]; then
      return 0
   else
      return 1
   fi
}

CheckWebDAV()
{
   # check if WebDAV directory is mounted

   if [ $(cat "/etc/mtab" | grep "${DIR_CLOUD} fuse " | wc -l) -gt 0 ]; then
      return 0
   else
      return 1
   fi
}

MsgOut()
{
   # perform GUI messages output using kdialog --passivepopup

   if [ -n "$1" ]; then
      TMP_MSG="$(date +"%x %X"): $1"
      TMP_TIME=$2
      TMP_TITLE=$3
      TMP_ICON=$4

      if [ -z "${TMP_TIME}" ]; then
         TMP_TIME=3
      fi

      if [ -z "${TMP_TITLE}" ]; then
         TMP_TITLE="${MSG_TITLE}"
      fi

      if [ -z "${TMP_ICON}" ]; then
         TMP_ICON="dialog-information"
      fi

      kdialog --passivepopup "${TMP_MSG}" ${TMP_TIME} --title="${TMP_TITLE}" --icon "${TMP_ICON}" 2>/dev/null
   fi
}

# *** Main program starts here ***

DIR_APPDIR=$(eval echo \$${PRGRM}_APPDIR)
DIR_BASE=$(eval echo \$${PRGRM}_BASE)
DIR_CHIPHER=$(eval echo \$${PRGRM}_CHIPHER)
DIR_CLOUD=$(eval echo \$${PRGRM}_CLOUD)
DIR_DATA=$(eval echo \$${PRGRM}_DATA)

MSG_TITLE="$(LocTx "M_Title")"
ERR_TITLE="$(LocTx "E_Title")"

XOUT=$(LocTx "T_Start"); echo -e "${XOUT}"

while true; do
   # check installation
  CheckInstall
   if [ $? -ne 0 ]; then
      EXIT_CD=1
      break
   fi

   # check for Internet access
   CheckInternet
   if [ $? -ne 0 ]; then
      EXIT_CD=2
      break
   fi

   # if WebDAV directory is mounted...
   CheckWebDAV
   if [ $? -eq 0 ]; then
      # ... try to unmount
      fusermount -u "${DIR_CLOUD}" 2>/dev/null

      # check if WebDAV directory is unmounted now
      CheckWebDAV
      if [ $? -eq 0 ]; then
         EXIT_CD=3
         break
      fi
   fi

   # mount WebDAV directory
   if [ $(mount "${DIR_CLOUD}" 2>/dev/null; echo $?) -ne 0 ]; then
      EXIT_CD=5
      break
   else
      # check if WebDAV directory is mounted
      CheckWebDAV
      if [ $? -ne 0 ]; then
         EXIT_CD=4
         break
      fi
   fi

   # in case of no data in chiphered data folder...
   if [ $(ls -1a "${DIR_CHIPHER}" | wc -l) -lt 3 ]; then
      # ... but data in WebDav folder...
      if [ $(ls -1a "${DIR_CLOUD}" | wc -l) -gt 2 ]; then
         # copy all data from WebDAV directory to data directory
         # inform the user about the copy process
         OUT_MSG="$(LocTx "M_Copy")"
         MsgOut "${OUT_MSG}" 5

         # start copy process
         rsync -r --exclude="lost+found" "${DIR_CLOUD}/" "${DIR_CHIPHER}" 2>/dev/null

         # check for success
         if [ $? -ne 0 ]; then
            EXIT_CD=5
            break
         else
            sleep 3

            # inform the user about the copy process success
            OUT_MSG="$(LocTx "M_CopyOk")"
            MsgOut "${OUT_MSG}" 3
         fi
      fi
   fi

   # create temporary log file
   echo " " > "${LOG_FULL}"
   echo "*** $(date -R) ***" >> "${LOG_FULL}"

   # inform the user about the syncronization process
   OUT_MSG="$(LocTx "M_Sync")"
   MsgOut "${OUT_MSG}" 1

   # do the syncronization
   unison "${DIR_CHIPHER}" "${DIR_CLOUD}" -batch -ui text -ignore "Name lost+found" -times -perms 0 -prefer "${DIR_CHIPHER}" -log -logfile "${LOG_FULL}"
   UNI_CD=$?

   # check for syncronization success
   if [ ${UNI_CD} -gt 2 ]; then
      # UNISON reports serious error
      EXIT_CD=6
   else
      # check if any files transmitted
      if [ $(wc -l "${LOG_FULL}" | grep -oE '^[0-9]+') -lt 3 ]; then
         # if not: memorize that fact
         EXIT_CD=7
      else
         # read synchronization log
         LOG_STATUS="$(grep -ie '^synchronization ' "${LOG_FULL}")"

         # check for logged synchronization errors
         if [ $(grep -icP '((^| )(?<!0 )failed| error )' "${LOG_FULL}") -ne 0 ]; then
            # wenn ja: merken!
            EXIT_CD=8
         fi
      fi
   fi

   # append temporary log file to cumulative log file
   cat "${LOG_FULL}" >> "${LOG_FULL}"

   # always try to unmount WebDAV directory
   sleep 3
   fusermount -u "${DIR_CLOUD}" 2>/dev/null

   # check for unmount success
   if [ $? -ne 0 ]; then
      # check if no serious error was reported previously
      if [ ${EXIT_CD} -eq 0 -o ${EXIT_CD} -eq 7 ]; then
         # if not: memorize unmount error
         EXIT_CD=3
      fi
   fi

   # success and exit
   break
done

# check if data directory was unlocked temporarily
if [ ${TMP_MOUNT} -ne 0 ]; then
   # lock again
   "${PRGRM}-lock.sh" 2>/dev/null
fi

case "${EXIT_CD}" in
   0) OUT_MSG="${LOG_STATUS}"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-information";;

   1) OUT_MSG="$(LocTx "E_Install")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   2) OUT_MSG="$(LocTx "E_Net")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   3) OUT_MSG="$(LocTx "E_Close")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   4) OUT_MSG="$(LocTx "E_Open")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   5) OUT_MSG="$(LocTx "M_Copy")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   6) OUT_MSG="$(LocTx "E_Fail")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   7) OUT_MSG="$(LocTx "M_NoData")"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-information"; EXIT_CD=0;;

   8) OUT_MSG="${LOG_STATUS}"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   *) OUT_MSG="$(LocTx "E_Unknown")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;
esac

MsgOut "${OUT_MSG}" ${OUT_TIME} "${OUT_TITLE}" "${OUT_ICON}"

XOUT=$(LocTx "T_End"); echo -e "${XOUT}"
exit "${EXIT_CD}"

# *** Main program ends here ***
