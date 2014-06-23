#!/bin/bash

# Copyright (c) 2014, K.-H. Hofacker, Hamburg, Germany. All rights reserved.
# This is free software, licensed under the 'BSD 2-Clause License'.
# See file 'copyright.txt' for details.

PRGRM="GINFIZZ"
PRGRM_VER="0.3"
SCRIPT_VER="${PRGRM_VER}.3"
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR=""
EXIT_CD=0

LOG_FULL=${TMPDIR}/${PRGRM}-backup.log
LOG_TEMP=${LOG_FULL}.tmp
FILE_COUNT=0
DIR_TARGET=""
TMP_MOUNT=0
CLOC=""

# *** i18n ***

LocTx()
{
   # language specific text definitions

   if [ -z "${CLOC}" ]; then
      CLOC="$(echo "${LANG}" | grep -oE "[a-z]{2}_[A-Z]{2}" | grep -oE "^[a-z]{2}" 2>/dev/null)"
   fi

   case "${CLOC}" in
      de)
         case "$1" in
            E_Install) echo "${PRGRM} ist nicht oder nur unvollständig installiert." ;;
            E_Mount)   echo "Das Datenverzeichnis '${DIR_DATA}' ist nicht engehängt." ;;
            E_RSync)   echo "Der Datensicherungs-Befehl lieferte einen Fehlerkode zurück." ;;
            E_Title)   echo "${PRGRM}: FEHLER bei Datensicherung" ;;
            E_Unknown) echo "Unbekannter Fehler!?" ;;
            E_User)    echo "Die Datensicherung wurde durch den Benutzer abgebrochen." ;;
            E_Write)   echo "Keine ausreichenden Rechte am Verzeichnis '@0'." ;;
            M_NoData)  echo "Keine neuen oder veränderten Dateien gefunden." ;;
            M_Success) echo "Es wurden @0 Datei(en) gesichert." ;;
            M_Title)   echo "${PRGRM}: Daten sichern" ;;
            Q_BckDir)  echo "${PRGRM}: Zielverzeichnis für die Datensicherung auswählen" ;;
            Q_HomeDir) echo "${PRGRM}: Soll die Datensicherung wirklich in das Home-Verzeichnis '${HOME}' erfolgen?" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Rückgabewert ist '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Start..." ;;
            W_Running) echo "Datensicherung läuft bereits - Abbruch der zweiten Instanz." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_Install) echo "${PRGRM} is not installed correctly." ;;
            E_Mount)   echo "The data directory '${DIR_DATA}' is locked." ;;
            E_RSync)   echo "The backup command reports an error." ;;
            E_Title)   echo "${PRGRM}: Backup ERROR" ;;
            E_Unknown) echo "Unknown error!?" ;;
            E_User)    echo "Backup cancelled by user." ;;
            E_Write)   echo "No sufficient rights to write to directory '@0'." ;;
            M_NoData)  echo "No new or modified files found." ;;
            M_Success) echo "@0 file(s) saved." ;;
            M_Title)   echo "${PRGRM}: Backup" ;;
            Q_BckDir)  echo "${PRGRM}: Select backup target directory" ;;
            Q_HomeDir) echo "${PRGRM}: really backup data in home directory '${HOME}'?" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) exit code is '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Begin..." ;;
            W_Running) echo "Backup already running - second instance aborted." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;
   esac
}

# *** Worker ***

EnsureEnvironment()
{
   # set environment if running under 'cron'

   if [ -z "$(eval echo \$${PRGRM}_BASE)" ]; then
      if [ -f "${HOME}/.profile" ]; then
         source "${HOME}/.profile"
      fi
   fi
}

CheckRunning()
{
   # check if script already running

   if [ $(ps ax|grep '/bin/bash $0'|grep -v 'grep') -lt 1 ]; then
      return 0
   else
      return 1
   fi
}

CheckEncFS()
{
   # check if data directory is mounted

   if [ $(cat "/etc/mtab" | grep "${DIR_DATA} fuse.encfs " | wc -l) -gt 0 ]; then
      return 0
   else
      return 1
   fi
}

CheckInstall()
{
   # check if PRGRM is installed

   if [ -d "${DIR_DATA}" ]; then
      return 0
   else
      return 1
   fi
}

CheckFolderReadWrite()
{
   # check for sufficient rights on directory

   TMP_CONTENTS=""
   TMP_FILE=""
   TMP_FOLDER=""

   if [ -n "$1" ]; then
      TMP_FOLDER="$1"

      # build test file name
      TMP_FILE="${TMP_FOLDER}/$(date +.Tmp%Y%m%d%M%S.tmp)"

      # write test file
      if [ $(echo "${TMP_FILE}" > "${TMP_FILE}" 2>/dev/null; echo $?) -ne 0 ]; then
         return 1
      fi

      # check if test file exists on target
      if [ ! -f "${TMP_FILE}" ]; then
         return 1
      fi

      # read test file contents
      TMP_CONTENTS="$(cat "${TMP_FILE}")"

      # check if the read data matches the data written
      if [ "${TMP_FILE}" != "${TMP_CONTENTS}" ]; then
         return 1
      fi

      # delete test file
      if [ $(rm "${TMP_FILE}" 2>/dev/null; echo $?) -ne 0 ]; then
         return 1
      fi

      # check if test file is deleted
      if [ -f "${TMP_FILE}" ]; then
         return 1
      fi
   else
      return 1
   fi
}

MsgOut()
{
   # perform GUI messages output using kdialog --passivepopup

   if [ -n "$1" ]; then
      TMP_MSG="$1 ($(date +"%c"))"
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
         TMP_ICON="${PRGRM_ICON}"
      fi

      kdialog --passivepopup "${TMP_MSG}" ${TMP_TIME} \
              --title="${TMP_TITLE}" --icon "${TMP_ICON}" 2>/dev/null
   fi
}

# *** Main program starts here ***

EnsureEnvironment

DIR_APPDIR=$(eval echo \$${PRGRM}_APPDIR)
DIR_BASE=$(eval echo \$${PRGRM}_BASE)
DIR_CHIPHER=$(eval echo \$${PRGRM}_CHIPHER)
DIR_CLOUD=$(eval echo \$${PRGRM}_CLOUD)
DIR_DATA=$(eval echo \$${PRGRM}_DATA)

MSG_TITLE="$(LocTx "M_Title")"
ERR_TITLE="$(LocTx "E_Title")"
ASK_TITLE="$(LocTx "Q_BckDir")"
ASK_HOMEDIR="$(LocTx "Q_HomeDir")"

PRGRM_ICON="${DIR_APPDIR}/icons/${SCRIPT_NAME/.sh/.svg}"

if [ ! -f "${PRGRM_ICON}" ]; then
   PRGRM_ICON="dialog-information"
fi

XOUT=$(LocTx "T_Start"); echo -e "${XOUT}"

while true; do
   # check installation
   CheckInstall
   if [ $? -ne 0 ]; then
      EXIT_CD=2
      break
   fi

   # check if data directory is mounted
   CheckEncFS
   if [ $? -ne 0 ]; then
      # unlock data directory temporarily
      "${PRGRM}-unlock.sh" 2>/dev/null

      # check if data directory is mounted now
      CheckEncFS
      if [ $? -ne 0 ]; then
         EXIT_CD=3
         break
      fi

      TMP_MOUNT=1
   fi

   # check if command line parameter is an existing directory
   if [ -d "S1" ]; then
      # use target dir from command line parameter
      DIR_TARGET="$1"
   else
      # read most recently used target directory
      DIR_TARGET="$(cat "${DIR_APPDIR}/last_backup_dir" 2>/dev/null)"

      # on first use suggest home directory
      if [ -z "${DIR_TARGET}" ]; then
         DIR_TARGET="~"
      fi

      # ask user to select new target directory
      DIR_TARGET="$(kdialog --getexistingdirectory "${DIR_TARGET}" --title="${ASK_TITLE}" 2>/dev/null)"

      # check if user cancelled the selection
      if [ -z "${DIR_TARGET}" ]; then
         EXIT_CD=4
         break
      fi
   fi

   # check if target directory is the HOME directory (== user clicked OK without selection)
   if [ "${DIR_TARGET}" = "${HOME}" ]; then
      # ask user if that is ok
      if [ $(kdialog --warningcontinuecancel "${ASK_HOMEDIR/@0/${HOME}}" --title="${MSG_TITLE}" 2>/dev/null; echo $?) -ne 0 ]; then
         EXIT_CD=4
         break
      fi
   fi

   # check for sufficient rights on target directory
   CheckFolderReadWrite "${DIR_TARGET}"
   if [ $? -ne 0 ]; then
      EXIT_CD=5
      break
   fi

   # save target directory as most recently used backup directory
   echo "${DIR_TARGET}" > "${DIR_APPDIR}/last_backup_dir" 2>/dev/null

   # create empty log file
   echo " " > "${LOG_TEMP}"
   echo "*** $(date -R) ***" >> "${LOG_TEMP}"

   # do the backup using RSYNC
   rsync -qrthi --exclude="lost+found" --log-file="${LOG_TEMP}" "${DIR_DATA}" "${DIR_TARGET}"

   # check if backup command reports an error
   if [ $? -ne 0 ]; then
      EXIT_CD=6
      break
   fi

   # read number of saved files from log file
   FILE_COUNT="$(cat "${LOG_TEMP}" | grep -o ' >f' | wc -l)"

   # append temp log file to main log file
   cat "${LOG_TEMP}" >> "${LOG_FULL}" 2>/dev/null

   # check if number of saved files is zero
   if [ ${FILE_COUNT} -lt 1 ]; then
      # success, but no files
      EXIT_CD=7
      break
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
   0) OUT_MSG="$(LocTx "M_Success")"
      OUT_MSG="${OUT_MSG/@0/${FILE_COUNT}}"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="${PRGRM_ICON}";;

   1) OUT_MSG="$(LocTx "W_Running")"
      OUT_TIME=5; OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-warning";;

   1) OUT_MSG="$(LocTx "E_Install")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   2) OUT_MSG="$(LocTx "E_Mount")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   3) OUT_MSG="$(LocTx "E_User")"
      OUT_TIME=5;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-warning";;

   4) OUT_MSG="$(LocTx "E_Write")"
      OUT_MSG="${OUT_MSG/@0/${DIR_TARGET}}"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   5) OUT_MSG="$(LocTx "E_RSync")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   6) OUT_MSG="$(LocTx "M_NoData")"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="${PRGRM_ICON}";;

   *) OUT_MSG="$(LocTx "E_Unknown")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;
esac

MsgOut "${OUT_MSG}" ${OUT_TIME} "${OUT_TITLE}" "${OUT_ICON}"

if [ ${EXIT_CD} -eq 6 ]; then
   EXIT_CD=0
fi

XOUT=$(LocTx "T_End"); echo -e "${XOUT}"
exit "${EXIT_CD}"

# *** Main program ends here ***
