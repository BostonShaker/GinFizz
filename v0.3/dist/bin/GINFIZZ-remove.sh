#!/bin/bash

# Copyright (c) 2014, K.-H. Hofacker, Hamburg, Germany. All rights reserved.
# This is free software, licensed under the 'BSD 2-Clause License'.
# See file 'copyright.txt' for details.

PRGRM="GINFIZZ"
PRGRM_LWR="$(echo "${PRGRM}"|tr 'A-Z' 'a-z')"
PRGRM_VER="0.3"
SCRIPT_VER="${PRGRM_VER}.2"
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR=""
EXIT_CD=0

DAV_SECRETS="${HOME}/.davfs2/secrets"
DOT_PROFILE="${HOME}/.profile"
ETC_FSTAB="/etc/fstab"

DIR_BASE="${HOME}/${PRGRM_LWR}"
DIR_APPDIR="${HOME}/.${PRGRM_LWR}"
DIR_CHIPHER="${DIR_BASE}/.chipher"
DIR_CLOUD="${DIR_BASE}/.cloud"
DIR_DATA="${DIR_BASE}/data"

ENC_XML=".encfs6.xml"
ENC_CONFIG="${DIR_BASE}/${ENC_XML}"

SCR_UNLOCK="${PRGRM}-unlock.sh"
SCR_LOCK="${PRGRM}-lock.sh"

TMP_FOLDER="${TMPDIR}/${USER}.${PRGRM}.tmp"
TMP_FILE1="${TMP_FOLDER}/temp1.tmp"

DESKTOP_TYPE=""
WEBDAV_URL=""
TWO_INPUT=""
WDTH=90
CLOC=""

MM='\E[0;35m'
RR='\E[0;31m'
YY='\E[0;36m'
ZZ='\e[0m'

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
            E_CrFoFail)  LOCTX="Das Verzeichnis '@1' konnte nicht angelegt werden." ;;
            E_DeiInit)   LOCTX="Das Skript konnte nicht initialisiert werden.${ERROR_END}" ;;
            E_DeiInst)   LOCTX="Offensichtlich ist ${PRGRM} nicht installiert\n(Environment-Variablen ${PRGRM}_* oder ${PRGRM}-Basisverzeichnis nicht gefunden.)${ERROR_END}" ;;
            E_DeiRoot)   LOCTX="Das root-Passwort wurde nicht oder falsch eingegeben.${ERROR_END}" ;;
            E_DeiUser)   LOCTX="Abbruch der Deinstallation durch den Benutzer.${ERROR_END}" ;;
            E_InstEnd)   LOCTX="\nDas Deinstallations-Skript wird beendet." ;;
            E_TwoChUsr)  LOCTX="Abbruch durch Leereingabe erkannt." ;;
            E_UmnDav)    LOCTX="Das WebDAV-Verzeichnis '@1' konnte nicht ausgehängt werden." ;;
            E_UmnEnc)    LOCTX="Das EncFS-Verzeichnis '@1' konnte nicht ausgehängt werden." ;;
            E_Unknown)   LOCTX="Unbekannter Fehler!?${ERROR_END}" ;;
            M_CrFoOk)    LOCTX="Das Verzeichnis '${MM}@1${ZZ}' wurde angelegt." ;;
            M_DeiSuc1)   LOCTX="\n${PRGRM} ${PRGRM_VER} ist nun deinstalliert." ;;
            M_DeiSuc2)   LOCTX="Das System sollte nun neu gestartet werden (Reboot)." ;;
            M_DeiSuc3)   LOCTX="\nDas Skript ${MM}@1${ZZ} im Verzeichnis ${MM}@2${ZZ} kann nun manuell gelöscht werden." ;;
            M_DoAsk1)    LOCTX="Soll ${MM}${PRGRM} @1${ZZ} jetzt vollständig von diesem Rechner entfernt werden?\n" ;;
            M_DoAsk2)    LOCTX="Hinweis: die verwalteten verschlüsselten Cloud-Daten verbleiben vollständig im versteckten Ordner '@1'. Da diese Daten aber verschlüsselt bleiben, können sie auf diesem Gerät erst nach erneuter Installation von ${PRGRM} wieder gelesen werden, sofern keine Datensicherung im unverschlüsselten Zustand vorliegt.\n" ;;
            M_DoDscEty)  LOCTX="Die Datei '@1' beinhaltet keine WebDAV-Anmeldeparameter." ;;
            M_DoDscExt)  LOCTX="Die Datei '@1' existiert nicht." ;;
            M_DoDscOk)   LOCTX="Die WebDAV-Anmeldeparameter wurden aus '@1' entfernt." ;;
            M_DoDavOk)   LOCTX="Die WebDAV-URL ${MM}@1${ZZ} wurde erkannt." ;;
            M_DoDelOk)   LOCTX="Alle ${PRGRM}-Dateien und -Verzeichnisse wurden entfernt." ;;
            M_DoDotEty)  LOCTX="Die Datei '@1' beinhaltet keine ${PRGRM}-Variablen." ;;
            M_DoDotOk)   LOCTX="Die ${PRGRM}-Variablen wurden aus '@1' entfernt." ;;
            M_DoFstOk)   LOCTX="Die WebDAV-Verbindungsinformation wurden aus '@1' entfernt." ;;
            M_DoIniOk)   LOCTX="Startverzeichnis ist ${MM}@1${ZZ}." ;;
            M_DoKdeAsEx) LOCTX="Der Autostart-Eintrag existiert nicht." ;;
            M_DoKdeMnEx) LOCTX="Die ${PRGRM}-Menükategorie existiert nicht." ;;
            M_DoKdeOk)   LOCTX="Die KDE-Arbeitsumgebung wurde bereinigt." ;;
            M_DoKdeShEx) LOCTX="Der shutdown-Eintrag existiert nicht." ;;
            M_DoPreOk)   LOCTX="Die Desktop-Umgebung ${MM}@1${ZZ} wurde erkannt.\n" ;;
            M_DoRly)     LOCTX="Sicherheitsnachfrage: ${PRGRM} ${PRGRM_VER} jetzt vom Gerät entfernen?" ;;
            M_InRoo1)    LOCTX="\nFür einige Aktionen dieses Skripts sind root-Rechte erforderlich, z.B. für das Entfernen von Einträgen aus der Systemtabelle '@1'.\n" ;;
            M_InRooOk)   LOCTX="\nDer root-Account ist nun freigeschaltet.\n" ;;
            M_InstTtle)  LOCTX="${PRGRM}: Deinstallation" ;;
            M_MnKdeOk)   LOCTX="Der Menüeintrag '@1' wurde aus der Kategorie '@2' entfernt." ;;
            M_RmFCOk)    LOCTX="Der Ordner '${MM}@1${ZZ}' wurde samt Inhalt entfernt." ;;
            M_TwoChUsg)  LOCTX="(Abbruch durch Leereingabe): " ;;
            M_UmnDavNo)  LOCTX="Das WebDAV-Verzeichnis ist nicht eingehängt." ;;
            M_UmnDavOk)  LOCTX="Das WebDAV-Verzeichnis '@1' ist nun ausgehängt." ;;
            M_UmnEncNo)  LOCTX="Das EncFS-Verzeichnis ist nicht eingehängt." ;;
            M_UmnEncOk)  LOCTX="Das EncFS-Verzeichnis '@1' ist nun ausgehängt." ;;
            Q_DoAsk)     LOCTX="(e) für vollständige Entfernung, (n) für nicht nicht entfernen" ;;
            Q_DoAskN)    LOCTX="n" ;;
            Q_DoAskY)    LOCTX="e" ;;
            Q_DoRly)     LOCTX="(j) für JA, (n) für NEIN" ;;
            Q_DoRlyN)    LOCTX="n" ;;
            Q_DoRlyY)    LOCTX="j" ;;
            T_InstBeg)   LOCTX="\n\n\n@1 (@2 v@3) Start..." ;;
            T_InstEnd)   LOCTX="@1 (@2 v@3) Rückgabewert ist '@4'." ;;
            W_CrFoTrg)   LOCTX="Das Verzeichnis '@1' existiert bereits." ;;
            W_DoDscFail) LOCTX="Die WebDAV-Anmeldeparameter konnten nicht aus '@1' entfernt werden." ;;
            W_DoDavIfo)  LOCTX="Nicht genügend Informationen zu den WebDAV-Anmeldeparametern. Die Dateien '@1' und '@2' bleiben unverändert. (Root-Rechte sind nicht erforderlich.)\n" ;;
            W_DoDotFail) LOCTX="Die ${PRGRM}-Variablen konnten nicht aus '@1' entfernt werden." ;;
            W_DoFstFail) LOCTX="Die WebDAV-Information konnten nicht aus '@1' entfernt werden." ;;
            W_DoPreMan)  LOCTX="Unbekannte bzw. nicht unterstützte Desktop-Umgebung.\nAutostart, shutdown, sowie das Desktop-Menü müssen manuell bereinigt werden.\n" ;;
            W_MnKdeFail) LOCTX="Der Menüeintrag '@1' konnte nicht aus der Kategorie '@2' entfernt werden." ;;
            W_RmFCFail)  LOCTX="Der Ordner '@1' bzw. sein Inhalt konnte nicht entfernt werden." ;;
            W_RmFCTrg)   LOCTX="Der Ordner '@1' existiert nicht." ;;
            W_RmFiExst)  LOCTX="Die zu löschende Datei '$1' existiert nicht." ;;
            W_RmFiFail)  LOCTX="Die Datei '$1' konnte nicht entfernt werden." ;;
            W_RmFiOk)    LOCTX="Die Datei '${MM}$1${ZZ}' wurde entfernt." ;;
            W_RmLiExst)  LOCTX="Der zu löschende Link '$1' existiert nicht." ;;
            W_RmLiFail)  LOCTX="Der Link '$1' konnte nicht entfernt werden." ;;
            W_RmLiOk)    LOCTX="Der Link '${MM}$1${ZZ}' wurde entfernt." ;;
            W_TwoChErr)  LOCTX="Ungültige Eingabe - neuer Versuch.\n" ;;
            *)           LOCTX="LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_CrFoFail)  LOCTX="Failed to create directory '@1'." ;;
            E_DeiInit)   LOCTX="Failed to initialize script.${ERROR_END}" ;;
            E_DeiInst)   LOCTX="Apparently ${PRGRM} is not correctly installed. (environment variables ${PRGRM}_* are not defined, or ${PRGRM} base folder not found).${ERROR_END}" ;;
            E_DeiRoot)   LOCTX="Wrong or empty root password.${ERROR_END}" ;;
            E_DeiUser)   LOCTX="Abort of the deinstallation by user.${ERROR_END}" ;;
            E_InstEnd)   LOCTX="\nThe deinstall script is terminated." ;;
            E_TwoChUsr)  LOCTX="User cancellation detected by empty input." ;;
            E_UmnDav)    LOCTX="Failed to unmount WebDAV directory '@1'." ;;
            E_UmnEnc)    LOCTX="Failed to unmount data directory '@1'." ;;
            E_Unknown)   LOCTX="Unknown error!?${ERROR_END}" ;;
            M_CrFoOk)    LOCTX="Directory '${MM}@1${ZZ}' created." ;;
            M_DeiSuc1)   LOCTX="\n${PRGRM} ${PRGRM_VER} removed successfully." ;;
            M_DeiSuc2)   LOCTX="Now the system should be restarted (reboot)." ;;
            M_DeiSuc3)   LOCTX="\nScript ${MM}@1${ZZ} in directory ${MM}@2${ZZ} may now be removed manually." ;;
            M_DoAsk1)    LOCTX="Remove ${MM}${PRGRM} @1${ZZ} now completely from this computer?\n" ;;
            M_DoAsk2)    LOCTX="Note: the complete encrypted Cloud data will remain on this computer in the hidden directory '@1'. Because these data is still encrypted, it may be read on this computer only after re-installing ${PRGRM} (, if no unencrypted backup exists).\n" ;;
            M_DoDscEty)  LOCTX="File '@1' does not contain valid WebDAV login credentials." ;;
            M_DoDscExt)  LOCTX="File '@1' not found." ;;
            M_DoDscOk)   LOCTX="The WebDAV login credentials were removed from '@1'." ;;
            M_DoDavOk)   LOCTX="WebDAV URL ${MM}@1${ZZ} found." ;;
            M_DoDelOk)   LOCTX="All ${PRGRM} files and directories were removed." ;;
            M_DoDotEty)  LOCTX="File '@1' does not contain ${PRGRM} environment variables." ;;
            M_DoDotOk)   LOCTX="${PRGRM} environment variables successfully removed from '@1'." ;;
            M_DoFstOk)   LOCTX="The WebDAV connection informations successfully removed from '@1'." ;;
            M_DoIniOk)   LOCTX="Script directory is ${MM}@1${ZZ}." ;;
            M_DoKdeAsEx) LOCTX="No Autostart entry found." ;;
            M_DoKdeMnEx) LOCTX="${PRGRM} menu category does not exist." ;;
            M_DoKdeOk)   LOCTX="KDE desktop environment revised successfully." ;;
            M_DoKdeShEx) LOCTX="No shutdown entry found." ;;
            M_DoPreOk)   LOCTX="Desktop environment ${MM}@1${ZZ} detected.\n" ;;
            M_DoRly)     LOCTX="Confirm: remove ${PRGRM} ${PRGRM_VER} from this computer now?" ;;
            M_InRoo1)    LOCTX="Root access is necessary for some activities of the installation script, e.g. for removing entries from the system configuration file '@1'.\n" ;;
            M_InRooOk)   LOCTX="\nRoot access is activated now.\n" ;;
            M_InstTtle)  LOCTX="${PRGRM}: Deinstallation" ;;
            M_MnKdeOk)   LOCTX="Menu entry '@1' removed from the category '@2'." ;;
            M_RmFCOk)    LOCTX="Directory '${MM}@1${ZZ}' was removed (including contents)." ;;
            M_TwoChUsg)  LOCTX="(abort by empty input): " ;;
            M_UmnDavNo)  LOCTX="WebDAV directory is not mounted." ;;
            M_UmnDavOk)  LOCTX="WebDAV directory '@1' is now unmounted." ;;
            M_UmnEncNo)  LOCTX="EncFS data directory is not mounted." ;;
            M_UmnEncOk)  LOCTX="EncFS data directory '@1' is now unmounted." ;;
            Q_DoAsk)     LOCTX="(r) for remove completely, (n) for abort" ;;
            Q_DoAskN)    LOCTX="n" ;;
            Q_DoAskY)    LOCTX="r" ;;
            Q_DoRly)     LOCTX="(y) for YES, (n) for NO" ;;
            Q_DoRlyN)    LOCTX="n" ;;
            Q_DoRlyY)    LOCTX="y" ;;
            T_InstBeg)   LOCTX="\n\n\n@1 (@2 v@3) Begin..." ;;
            T_InstEnd)   LOCTX="@1 (@2 v@3) exit code is '@4'." ;;
            W_CrFoTrg)   LOCTX="Directory '@1' already exists." ;;
            W_DoDscFail) LOCTX="Failed to remove WebDAV login credentials from file '@1'." ;;
            W_DoDavIfo)  LOCTX="Not enough information about the WebDAV login credentials. The files '@1' and '@2' will not be changed (no root right necessary).\n" ;;
            W_DoDotFail) LOCTX="Failed to remove ${PRGRM} environment variables from '@1'." ;;
            W_DoFstFail) LOCTX="Failed to remove WebDAV informations from '@1'." ;;
            W_DoPreMan)  LOCTX="Unknown or unsupported desktop environment.\nAutostart, shutdown, and desktop menu must be revised manually.\n" ;;
            W_MnKdeFail) LOCTX="Failed to remove menu entry from '@1' category '@2'." ;;
            W_RmFCFail)  LOCTX="Failed to remove directory '@1' (or it's contents)." ;;
            W_RmFCTrg)   LOCTX="Directory '@1' does not exist." ;;
            W_RmFiExst)  LOCTX="File '$1' does not exist." ;;
            W_RmFiFail)  LOCTX="Failed to remove file '$1'." ;;
            W_RmFiOk)    LOCTX="File '${MM}$1${ZZ}' removed successfully." ;;
            W_RmLiExst)  LOCTX="Link '$1' does not exist." ;;
            W_RmLiFail)  LOCTX="Failed to remove link '$1'." ;;
            W_RmLiOk)    LOCTX="Link '${MM}$1${ZZ}' removed successfully." ;;
            W_TwoChErr)  LOCTX="Invalid input - try again.\n" ;;
            *)           LOCTX="LocTx: $1 ??? (${CLOC})" ;;
         esac ;;
   esac

   if [ -n "$2" ]; then
       LOCTX="${LOCTX/@1/$2}"
   fi

   if [ -n "$3" ]; then
       LOCTX="${LOCTX/@2/$3}"
   fi

   if [ -n "$4" ]; then
       LOCTX="${LOCTX/@3/$4}"
   fi

   if [ -n "$5" ]; then
       LOCTX="${LOCTX/@4/$5}"
   fi

   echo "${LOCTX}"
}

# ### ### ### Helper ### ### ###

ErrOut()
{
   echo -e "${RR}$1${ZZ}" | fold -s -w ${WDTH}
}

InfoOut()
{
   echo -e "${MM}$1${ZZ}" | fold -s -w ${WDTH}
}

TextOut()
{
   echo -e "$1" | fold -s -w ${WDTH}
}

WarnOut()
{
   echo -e "${YY}$1${ZZ}" | fold -s -w ${WDTH}
}

CreateFolder()
{
   # helper: create a directory (no error return)

   TMP_QUIET=$(GetParam "$2" "q")

   if [ -d "$1" ]; then
      if [ "${TMP_QUIET}" != "-q" ]; then
         WarnOut "$(LocTx "W_CrFoTrg" "$1")"
      fi
   else
      mkdir "$1" >/dev/null 2>&1

      if [ -d "$1" ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            TextOut "$(LocTx "M_CrFoOk" "$1")"
         fi
      else
         if [ "${TMP_QUIET}" != "-q" ]; then
            ErrOut "$(LocTx "E_CrFoFail" "$1")"
         fi
      fi
   fi

   return 0
}

DeleteFile()
{
   # helper: delete a file (no error return)

   TMP_QUIET=$(GetParam "$2" "q")

   if [ -f  "$1" ]; then
      rm -f "$1" > /dev/null 2>&1

      if [ $? -ne 0 ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            WarnOut "$(LocTx "W_RmFiFail" "$1")"
         fi
      fi

      if [ "${TMP_QUIET}" != "-q" ]; then
         TextOut "$(LocTx "W_RmFiOk" "$1")"
      fi
   else
      if [ "${TMP_QUIET}" != "-q" ]; then
         TextOut "$(LocTx "W_RmFiExst" "$1")"
      fi
   fi

   return 0
}

DeleteFolderWithContents()
{
   # helper: delete folder with contents (no error return)

   TMP_QUIET=$(GetParam "$2" "q")

   if [ -d  "$1" ]; then
      rm -r "$1" > /dev/null 2>&1

      if [ "${TMP_QUIET}" != "-q" ]; then
         if [ $? -ne 0 ]; then
            WarnOut "$(LocTx "W_RmFCFail" "$1")"
         else
            TextOut "$(LocTx "M_RmFCOk" "$1")"
         fi
      fi
   else
      if [ "${TMP_QUIET}" != "-q" ]; then
         WarnOut "$(LocTx "W_RmFCTrg" "$1")"
      fi
   fi

   return 0
}

DeleteLink()
{
   # helper: delet link (no error return)

   TMP_QUIET=$(GetParam "$2" "q")

   if [ -h  "$1" ]; then
      rm -f "$1" > /dev/null 2>&1

      if [ $? -ne 0 ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            WarnOut "$(LocTx "W_RmLiFail" "$1")"
         fi
      fi

      if [ "${TMP_QUIET}" != "-q" ]; then
         TextOut "$(LocTx "W_RmLiOk" "$1")"
      fi
   else
      if [ "${TMP_QUIET}" != "-q" ]; then
         TextOut "$(LocTx "W_RmLiExst" "$1")"
      fi
   fi

   return 0
}

GetParam()
{
   # helper: extract function parameters

   if [ -n "$1" ]; then
      if [ -n "$2" ]; then
         if [ $(echo "$1" | grep -ie "\-$2" | wc -l) -gt 0 ]; then
            echo "-$2"
         fi
      fi
   fi
}

TwoChoicesInput()
{
   # helper: user choice between two alternatives

   TWO_INPUT=""

   if [ -n "$1" ]; then
      if [ -n "$2" ]; then
         if [ -n "$3" ]; then
            while true; do
               read -p "$1 $(LocTx "M_TwoChUsg")" TWO_INPUT

               if [ -n "${TWO_INPUT}" ]; then
                  if [ "${TWO_INPUT}" == "$2" ]; then
                     break
                  fi

                  if [ "${TWO_INPUT}" == "$3" ]; then
                     break
                  fi

                  WarnOut "$(LocTx "W_TwoChErr")"
               else
                  ErrOut "$(LocTx "E_TwoChUsr")"
                  break
               fi
            done
         fi
      fi
   fi
}

# ### ### ### Worker ### ### ###

AskReallyRemove()
{
   TextOut "$(LocTx "M_DoAsk1" "${PRGRM_VER}")"
   InfoOut "$(LocTx "M_DoAsk2" "${DIR_CHIPHER}")"

   TMP_Y="$(LocTx "Q_DoAskY")"
   TMP_N="$(LocTx "Q_DoAskN")"
   TwoChoicesInput "$(LocTx "Q_DoAsk")" "${TMP_Y}" "${TMP_N}"

   case "${TWO_INPUT}" in
      "${TMP_Y}") ;;
      *)        return 1 ;;
   esac

   return 0
}

AskReallyReally()
{
   InfoOut "$(LocTx "M_DoRly" "${PRGRM_VER}")"

   TMP_Y="$(LocTx "Q_DoRlyY")"
   TMP_N="$(LocTx "Q_DoRlyN")"
   TwoChoicesInput "$(LocTx "Q_DoRly")" "${TMP_Y}" "${TMP_N}"

   case "${TWO_INPUT}" in
      "${TMP_Y}") ;;
      *)        return 1 ;;
   esac

   return 0
}

CheckPrerequsites()
{
   if [ -z "${DIR_BASE}" ]; then
      return 1
   fi

   if [ ! -d "${DIR_BASE}" ]; then
      return 1
   fi

   DESKTOP_TYPE=$(echo ${XDG_CURRENT_DESKTOP}|cut -d\  -f1|tr 'a-z' 'A-Z')

   case "${DESKTOP_TYPE}" in
      "KDE")
         TextOut "$(LocTx "M_DoPreOk" "${DESKTOP_TYPE}")"
         ;;

      *)
         WarnOut "$(LocTx "W_DoPreMan")"
         ;;
   esac

   return 0
}

CleanUp()
{
   if [ -f "${TMP_FILE1}" ]; then
      rm -f "${TMP_FILE1}" > /dev/null 2>&1
   fi

   return 0
}

ClearDavSecrets()
{
   TMP_ERR=0

   if [ -n "${WEBDAV_URL}" ]; then
      if [ -f "${DAV_SECRETS}" ]; then
         if [ $(cat "${DAV_SECRETS}" | grep "${WEBDAV_URL}" | wc -l) -gt 0 ]; then
            cat "${DAV_SECRETS}" | grep -v "${WEBDAV_URL}" > "${TMP_FILE1}"
            if [ $? -gt 1 ]; then TMP_ERR=1; fi

            mv -fb "${TMP_FILE1}" "${DAV_SECRETS}" >/dev/null 2>&1
            if [ $? -ne 0 ]; then TMP_ERR=1; fi

            CleanUp

            if [ ${TMP_ERR} -ne 0 ]; then
               WarnOut "$(LocTx "W_DoDscFail" "${DAV_SECRETS}")"
            else
               InfoOut "$(LocTx "M_DoDscOk" "${DAV_SECRETS}")"
            fi
         else
            TextOut "$(LocTx "M_DoDscEty" "${DAV_SECRETS}")"
         fi
      else
         TextOut "$(LocTx "M_DoDscExt" "${DAV_SECRETS}")"
      fi
   fi

   return 0
}

ClearDotProfile()
{
   TMP_ERR=0
   TMP_PATTERN="export ${PRGRM}_"

   if [ -f "${DOT_PROFILE}" ]; then
      if [ $(cat "${DOT_PROFILE}" | grep "${TMP_PATTERN}" | wc -l) -gt 0 ]; then
         cat "${DOT_PROFILE}" | grep -v "${TMP_PATTERN}" > "${TMP_FILE1}"
         if [ $? -gt 1 ]; then TMP_ERR=1; fi

         mv -fb "${TMP_FILE1}" "${DOT_PROFILE}" >/dev/null 2>&1
         if [ $? -ne 0 ]; then TMP_ERR=1; fi

         CleanUp

         if [ ${TMP_ERR} -ne 0 ]; then
            WarnOut "$(LocTx "W_DoDotFail" "${DOT_PROFILE}")"
         else
            InfoOut "$(LocTx "M_DoDotOk" "${DOT_PROFILE}")"
         fi
      else
         TextOut "$(LocTx "M_DoDotEty" "${DOT_PROFILE}")"
      fi
   fi

   return 0
}

ClearEnvironment()
{
   case "${DESKTOP_TYPE}" in
      "KDE")
         ClearEnvironmentKDE
         if [ $? -ne 0 ]; then return 1;  fi
         ;;

      *)
         # not supported
         ;;
   esac

   return 0
}

ClearEnvironmentKDE()
{
   TMP_WORK=0
   TMP_VAR1=""
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.directory$"
   TMP_DESKDIRDIR="${HOME}/.local/share/desktop-directories/"
   TMP_DESKAPPDIR="${HOME}/.local/share/applications/"
   TMP_AUTOSTARTDIR="${HOME}/.kde4/Autostart"
   TMP_SHUTDOWNDIR="${HOME}/.kde4/shutdown"

   MENU_FOLDER="$(find "${TMP_DESKDIRDIR}" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)"
   MENU_FOLDER="$(basename "${MENU_FOLDER}")"

   if [ -n "${MENU_FOLDER}" ]; then
      TMP_REGEX=".*\/${PRGRM}-[a-z]+\.desktop$"

      for TMP_VAR1 in $(find "${TMP_DESKAPPDIR}" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
      do
         TMP_WORK=1
         RemoveMenuItemKDE "${MENU_FOLDER}" "$(basename "${TMP_VAR1}")"
      done
   else
      TextOut "$(LocTx "M_DoKdeMnEx")"
   fi

   TMP_VAR1="${TMP_AUTOSTARTDIR}/${SCR_UNLOCK}"

   if [ -h "${TMP_VAR1}" ]; then
      TMP_WORK=1
      DeleteLink "${TMP_VAR1}"
   else
      TextOut "$(LocTx "M_DoKdeAsEx")"
   fi

   TMP_VAR1="${TMP_SHUTDOWNDIR}/${SCR_LOCK}"

   if [ -h "${TMP_VAR1}" ]; then
      TMP_WORK=1
      DeleteLink "${TMP_VAR1}"
   else
      TextOut "$(LocTx "M_DoKdeShEx")"
   fi

   if [ "${TMP_WORK}" -ne 0 ];then
      InfoOut "$(LocTx "M_DoKdeOk")"
   fi

   return 0
}

RemoveMenuItemKDE()
{
   xdg-desktop-menu uninstall --mode user "$1" "$2" > /dev/null 2>&1

   if [ "$3" != "-q" ]; then
      if [ $? -ne 0 ]; then
         WarnOut "$(LocTx "W_MnKdeFail" "$2" "$1")"
      else
         TextOut "$(LocTx "M_MnKdeOk" "$2" "$1")"
      fi
   fi
}

ClearFsTab()
{
   if [ -n "${WEBDAV_URL}" ]; then
      TMP_ERR=0

      cat "${ETC_FSTAB}" | grep -v "${WEBDAV_URL}" > "${TMP_FILE1}"
      if [ $? -gt 1 ]; then TMP_ERR=1; fi

      sudo sh -c "cat ${TMP_FILE1} > ${ETC_FSTAB}"
      if [ $? -ne 0 ]; then TMP_ERR=1; fi

      if [ ${TMP_ERR} -ne 0 ]; then
         WarnOut "$(LocTx "W_DoFstFail" "${ETC_FSTAB}")"
      else
         InfoOut "$(LocTx "M_DoFstOk" "${ETC_FSTAB}")"
      fi
   fi

   CleanUp

   return 0
}

DeleteFilesAndFolders()
{
   TMP_WORK=0

   if [ -f "${ENC_CONFIG}" ]; then
      TMP_WORK=1
      DeleteFile "${ENC_CONFIG}"
   fi

   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.(sh|txt)$"

   for TMP_VAR1 in $(find "${HOME}/bin" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      if [ "$(basename ${TMP_VAR1})" != "${SCRIPT_NAME}" ]; then
         TMP_WORK=1
         DeleteFile "${TMP_VAR1}"
      fi
   done

   if [ -d "${DIR_CLOUD}" ]; then
      TMP_WORK=1
      DeleteFolderWithContents "${DIR_CLOUD}"
   fi

   if [ -d "${DIR_DATA}" ]; then
      TMP_WORK=1
      DeleteFolderWithContents "${DIR_DATA}"
   fi

   if [ -d "${DIR_APPDIR}" ]; then
      TMP_WORK=1
      DeleteFolderWithContents "${DIR_APPDIR}"
   fi

   if [ "${TMP_WORK}" -ne 0 ];then
      InfoOut "$(LocTx "M_DoDelOk")"
   fi

   return 0
}

GetWebDavUrl()
{
   TMP_WORK=0

   if [ -n "${DIR_CLOUD}" ]; then
      WEBDAV_URL=$(cat "${ETC_FSTAB}" | grep "${DIR_CLOUD}" | cut -d\  -f1)

      if [ -n "${WEBDAV_URL}" ]; then
         TextOut "$(LocTx "M_DoDavOk" "${WEBDAV_URL}")"
         TMP_WORK=1
      fi
   fi

   if [ ${TMP_WORK} -eq 0 ]; then
      WEBDAV_URL=""
      WarnOut "$(LocTx "W_DoDavIfo" "${DAV_SECRETS}" "${ETC_FSTAB}")"
   fi

   return 0
}

RootPasswordInput()
{
   TextOut "$(LocTx "M_InRoo1" "${ETC_FSTAB}")"

   sudo -v
   if [ $? -ne 0 ]; then return 1; fi

   InfoOut "$(LocTx "M_InRooOk")"
   return 0
}

ScriptFinish()
{
   # root-Account wieder sperren
   sudo -k

   # temporäres Verzeichnis löschen
   DeleteFolderWithContents "${TMP_FOLDER}" -q

   return 0
}

ScriptInit()
{
   CreateFolder "${TMP_FOLDER}" -q
   if [ $? -ne 0 ]; then return 1;  fi

   SCRIPT_DIR=$(readlink -f "$0")
   SCRIPT_DIR=$(dirname "${SCRIPT_DIR}")

   cd "${SCRIPT_DIR}"
   if [ $? -ne 0 ]; then return 1;  fi

   TextOut "$(LocTx "M_DoIniOk" "${SCRIPT_DIR}")"

   return 0
}

UnmountEncFS()
{
   if [ -n "${DIR_DATA}" ]; then
      # ist das Verzeichnis LESBAR eingehängt?
      if [ $(cat "/etc/mtab" | grep "${DIR_DATA} fuse.encfs " | wc -l) -gt 0 ]; then
         fusermount -u "${DIR_DATA}" > /dev/null 2>&1

         if [ $? -ne 0 ]; then
            ErrOut "$(LocTx "E_UmnEnc" "${DIR_DATA}")"
            return 1
         else
            InfoOut "$(LocTx "M_UmnEncOk" "${DIR_DATA}")"
         fi
      else
         TextOut "$(LocTx "M_UmnEncNo")"
      fi
   fi

   return 0
}

UnmountWebDAV()
{
   if [ -n "${DIR_CLOUD}" ]; then
      # ist das DAVFS2-Verzeichnis eingehängt?
      if [ $(cat "/etc/mtab" | grep "${DIR_CLOUD} fuse " | wc -l) -gt 0 ]; then
         # wenn ja, dann aushängen
         fusermount -u "${DIR_CLOUD}" > /dev/null 2>&1

         if [ $? -ne 0 ]; then
            ErrOut "$(LocTx "E_UmnDav" "${DIR_CLOUD}")"
            return 1
         else
            InfoOut "$(LocTx "M_UmnDavOk" "${DIR_CLOUD}")"
         fi
      else
         TextOut "$(LocTx "M_UmnDavNo")"
      fi
   fi

   return 0
}

# ### ### ### Main ### ### ###

DIR_APPDIR=$(eval echo \$${PRGRM}_APPDIR)
DIR_BASE=$(eval echo \$${PRGRM}_BASE)
DIR_CHIPHER=$(eval echo \$${PRGRM}_CHIPHER)
DIR_CLOUD=$(eval echo \$${PRGRM}_CLOUD)
DIR_DATA=$(eval echo \$${PRGRM}_DATA)

MSG_TITLE="$(LocTx "M_InstTtle")"
ERROR_END="$(LocTx "E_InstEnd")"

InfoOut "$(LocTx "T_InstBeg" "${MSG_TITLE}" "${SCRIPT_NAME}" "${SCRIPT_VER}")"

while true; do
   ScriptInit
   if [ $? -ne 0 ]; then EXIT_CD=1; break; fi

   CheckPrerequsites
   if [ $? -ne 0 ]; then EXIT_CD=2; break; fi

   AskReallyRemove
   if [ $? -ne 0 ]; then EXIT_CD=3; break; fi

   AskReallyReally
   if [ $? -ne 0 ]; then EXIT_CD=3; break; fi

   GetWebDavUrl

   if [ -n "${WEBDAV_URL}" ]; then
      RootPasswordInput
      if [ $? -ne 0 ]; then EXIT_CD=4; break; fi
   fi

   # keine weitere Fehlerbehandlung nötig ab hier...

   UnmountWebDAV
   UnmountEncFS

   ClearEnvironment
   DeleteFilesAndFolders
   ClearFsTab
   ClearDotProfile
   ClearDavSecrets

   # success and exit
   break
done

case "${EXIT_CD}" in
   0) TextOut "$(LocTx "M_DeiSuc1")"
      InfoOut "$(LocTx "M_DeiSuc2")"
      TextOut "$(LocTx "M_DeiSuc3" "${SCRIPT_NAME}" "${SCRIPT_DIR}")"
      ;;
   1) ErrOut  "$(LocTx "E_DeiInit")" ;;
   2) ErrOut  "$(LocTx "E_DeiInst")" ;;
   3) ErrOut  "$(LocTx "E_DeiUser")" ;;
   4) ErrOut  "$(LocTx "E_DeiRoot")" ;;
   *) ErrOut  "$(LocTx "E_Unknown")" ;;
esac

ScriptFinish

InfoOut "$(LocTx "T_InstEnd" "${MSG_TITLE}" "${SCRIPT_NAME}" "${SCRIPT_VER}" "${EXIT_CD}")"

exit "${EXIT_CD}"

# ### ### ### EOF ### ### ###
