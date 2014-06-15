#!/bin/bash

# Copyright (c) 2014, K.-H. Hofacker, Hamburg, Germany. All rights reserved.
# This is free software, licensed under the 'BSD 2-Clause License'.
# See file 'copyright.txt' for details.

PRGRM="GINFIZZ"
PRGRM_VER="0.3"
SCRIPT_VER="${PRGRM_VER}.2"
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR=""
EXIT_CD=0

CLOC=""
SCR_UNLOCK="${PRGRM}-unlock.sh"
TMP_UNLOCK=0

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
            E_Fail)    echo "Der Datenordner '${DIR_DATA}' konnte nicht geöffnet werden." ;;
            E_Install) echo "${PRGRM} ist nicht oder nur unvollständig installiert." ;;
            E_Title)   echo "${PRGRM}: FEHLER beim Öffnen" ;;
            E_Unknown) echo "Unbekannter Fehler!?" ;;
            E_Unlock)  echo "Das Freischalten ist gescheitert (ggf. Passwort falsch oder Benutzerabbruch)." ;;
            M_Success) echo "" ;; #no message at all
            M_Title)   echo "${PRGRM}: Verzeichnis öffnen" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Rückgabewert ist '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Start..." ;;
            W_Close)   echo "Die Daten sollten abschließend wieder gesperrt werden." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_Fail)    echo "Failed to open data directory '${DIR_DATA}'." ;;
            E_Install) echo "${PRGRM} is not installed correctly." ;;
            E_Title)   echo "${PRGRM}: ERROR exploring data" ;;
            E_Unknown) echo "Unknown error!?" ;;
            E_Unlock)  echo "Failed to unlock data directory (wrong password or user cancellation)." ;;
            M_Success) echo "" ;; #no message at all
            M_Title)   echo "${PRGRM}: Explore data" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) exit code is '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Begin..." ;;
            W_Close)   echo "Don't forget to relock data finally." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;
   esac
}

# *** Worker ***

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

PRGRM_ICON="${DIR_APPDIR}/icons/${SCRIPT_NAME/.sh/.svg}"

if [ ! -f "${PRGRM_ICON}" ]; then
   PRGRM_ICON="dialog-information"
fi

XOUT=$(LocTx "T_Start"); echo -e "${XOUT}"

while true; do
   # check installation
   CheckInstall

   if [ $? -ne 0 ]; then
      EXIT_CD=1
      break
   fi

   # check if data directory is unlocked
   CheckEncFS

   if [ $? -ne 0 ]; then
      # if not: unlock now
      "$SCR_UNLOCK"

      if [ $? -ne 0 ]; then
         EXIT_CD=2
         break
      fi

      # bear in mind for warning message
      EXIT_CD=3
   fi

   # open data folder
   xdg-open "${DIR_DATA}" 2>/dev/null

   if [ $? -ne 0 ]; then
      EXIT_CD=4
      break
   fi

   # success and exit
   break
done

case "${EXIT_CD}" in
   0) OUT_MSG="$(LocTx "M_Success")"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="${PRGRM_ICON}";;

   1) OUT_MSG="$(LocTx "E_Install")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   2) OUT_MSG="$(LocTx "E_Unlock")"
      OUT_TIME=5;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-error";;

   3) OUT_MSG="$(LocTx "W_Close")"
      OUT_TIME=10; OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-warning";;

   4) OUT_MSG="$(LocTx "E_Fail")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   *) OUT_MSG="$(LocTx "E_Unknown")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;
esac

if [ ${EXIT_CD} -eq 3 ]; then
   EXIT_CD=0
fi

MsgOut "${OUT_MSG}" ${OUT_TIME} "${OUT_TITLE}" "${OUT_ICON}"

XOUT=$(LocTx "T_End"); echo -e "${XOUT}"
exit "${EXIT_CD}"

# *** Main program ends here ***
