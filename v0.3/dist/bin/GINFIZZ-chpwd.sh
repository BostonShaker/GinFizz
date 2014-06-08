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

TMP_FILE1="${TMPDIR}/${USER}.${PRGRM}.temp1.tmp"
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
            E_Fail)    echo "Das Passwort konnte nicht geändert werden, oder Abbruch durch den Benutzer." ;;
            E_Install) echo "${PRGRM} ist nicht oder nur unvollständig installiert." ;;
            E_Temp)    echo "Fehler bei der Anlage einer Hilfsdatei." ;;
            E_Title)   echo "${PRGRM}: FEHLER bei Passwortänderung" ;;
            E_Unknown) echo "Unbekannter Fehler!?" ;;
            M_Success) echo "Das Passwort wurde erfolgreich geändert." ;;
            M_Title)   echo "${PRGRM}: Passwort ändern" ;;
            Q_Passwd)  echo "Passwort zur Entschlüsselung der Daten eingeben:" ;;
            T_End)     echo "${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Rückgabewert ist '${EXIT_CD}'." ;;
            T_Start)   echo "\n${MSG_TITLE} (${SCRIPT_NAME} v${SCRIPT_VER}) Start..." ;;
            *)         echo "LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_Fail)    echo "Failed to change password, or cancellation by user." ;;
            E_Install) echo "${PRGRM} is not installed correctly." ;;
            E_Temp)    echo "Failed to create an auxiliary file." ;;
            E_Title)   echo "${PRGRM}: ERROR changing password" ;;
            E_Unknown) echo "Unknown error!?" ;;
            M_Success) echo "The password was changed successfully." ;;
            M_Title)   echo "${PRGRM}: Password change" ;;
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

      kdialog --passivepopup "${TMP_MSG}" ${TMP_TIME} \
              --title="${TMP_TITLE}" --icon "${TMP_ICON}" 2>/dev/null
   fi
}

# *** Main program starts here ***

DIR_APPDIR=$(eval echo \$${PRGRM}_APPDIR)
DIR_BASE=$(eval echo \$${PRGRM}_BASE)
DIR_CHIPHER=$(eval echo \$${PRGRM}_CHIPHER)
DIR_CLOUD=$(eval echo \$${PRGRM}_CLOUD)
DIR_DATA=$(eval echo \$${PRGRM}_DATA)

ERR_TITLE="$(LocTx "E_Title")"
MSG_TITLE="$(LocTx "M_Title")"
MSG_PWDINPUT="$(LocTx "Q_Passwd")"

XOUT=$(LocTx "T_Start"); echo -e "${XOUT}"

while true; do
   # check installation
   CheckInstall
   if [ $? -ne 0 ]; then
      EXIT_CD=1
      break
   fi

   # delete temp file if existing
   if [ -f "${TMP_FILE1}" ]; then
      rm -f "${TMP_FILE1}" > /dev/null 2>&1
   fi

   # create new temp file (with current timestamp)
   echo "temp" > "${TMP_FILE1}"
   if [ $? -ne 0 ]; then
      EXIT_CD=2
      break
   fi

   # call 'ENCFSCTL passwd' in TERM window
   "${TERM}" -g 80x24+200+200 -e " ENCFS6_CONFIG="${DIR_BASE}/.encfs6.xml" \
                   encfsctl passwd "${DIR_CHIPHER}" " > /dev/null 2>&1

   # check if .encfs6.xml is changed after the previously created temp file
   if [ $(find "${DIR_BASE}" -newer "${TMP_FILE1}" 2>/dev/null|grep ".encfs6.xml"|wc -l) -lt 1 ]; then
      EXIT_CD=3
      break
   fi

   # success and exit
   break
done

# delete temp file if existing
if [ -f "${TMP_FILE1}" ]; then
   rm -f "${TMP_FILE1}" > /dev/null 2>&1
fi

case "${EXIT_CD}" in
   0) OUT_MSG="$(LocTx "M_Success")"
      OUT_TIME=3;  OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-information";;

   1) OUT_MSG="$(LocTx "E_Install")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   2) OUT_MSG="$(LocTx "E_Temp")"
      OUT_TIME=10; OUT_TITLE="${MSG_TITLE}"; OUT_ICON="dialog-error";;

   3) OUT_MSG="$(LocTx "E_Fail")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;

   *) OUT_MSG="$(LocTx "E_Unknown")"
      OUT_TIME=10; OUT_TITLE="${ERR_TITLE}"; OUT_ICON="dialog-error";;
esac

MsgOut "${OUT_MSG}" ${OUT_TIME} "${OUT_TITLE}" "${OUT_ICON}"

XOUT=$(LocTx "T_End"); echo -e "${XOUT}"
exit "${EXIT_CD}"

# *** Main program ends here ***
