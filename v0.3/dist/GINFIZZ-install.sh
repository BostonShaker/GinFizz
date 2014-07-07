#!/bin/bash

# Copyright (c) 2014, K.-H. Hofacker, Hamburg, Germany. All rights reserved.
# This is free software, licensed under the 'BSD 2-Clause License'.
# See file 'copyright.txt' for details.

PRGRM="GINFIZZ"
PRGRM_LWR="$(echo "${PRGRM}"|tr 'A-Z' 'a-z')"
PRGRM_VER="0.3"
SCRIPT_VER="${PRGRM_VER}.4"
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_DIR}")"
EXIT_CD=0

WDTH=90

ETC_FSTAB="/etc/fstab"
ETC_FSTAB_BACKUP="/etc/fstab.${PRGRM}.backup"

DIR_BASE="${HOME}/${PRGRM_LWR}"
DIR_APPDIR="${HOME}/.${PRGRM_LWR}"
DIR_ICONDIR="${DIR_APPDIR}/icons"
DIR_CHIPHER="${DIR_BASE}/.chipher"
DIR_CLOUD="${DIR_BASE}/.cloud"
DIR_DATA="${DIR_BASE}/data"
DIR_REUSE="${SCRIPT_DIR}/reuse"

ENC_XML=".encfs6.xml"
ENC_CONFIG="${DIR_BASE}/${ENC_XML}"
ENC_REUSEFILE="${DIR_REUSE}/$(echo "${ENC_XML}" | sed 's/^\.//g')"

DAV_GROUP="davfs2"
DAV_SECFILE="secrets"
DAV_FOLDER="${HOME}/.davfs2"
DAV_CONFIG="${DAV_FOLDER}/davfs2.conf"
DAV_SECRETS="${DAV_FOLDER}/${DAV_SECFILE}"
DAV_REUSEFILE="${DIR_REUSE}/${DAV_SECFILE}"

SCR_UNLOCK="${PRGRM}-unlock.sh"
SCR_LOCK="${PRGRM}-lock.sh"

TMP_FOLDER="${TMPDIR}/${USER}.${PRGRM}.tmp"
TMP_FILE1="${TMP_FOLDER}/temp1.tmp"
TMP_FILE2="${TMP_FOLDER}/temp2.tmp"

DESKTOP_TYPE=""
VERIFIED_INPUT=""
LINUX_DESC=""
LINUX_DIST=""
DAV_REUSE=0
ENC_REUSE=0
PROGRAM_LIST=""
TWO_INPUT=""
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
            E_CopyFail) LOCTX="Die Datei '@1' konnte nicht auf das Ziel '@2' kopiert werden." ;;
            E_CopySrc)  LOCTX="Die Ausgangsdatei '@1' existiert nicht." ;;
            E_CopyTrg)  LOCTX="Die Zieldatei '@1' existiert bereits." ;;
            E_CrFiFail) LOCTX="Die Datei '@1' konnte nicht angelegt werden." ;;
            E_CrFiTrg)  LOCTX="Die Datei '@1' existiert bereits und ist nicht leer." ;;
            E_CrFoFail) LOCTX="Das Verzeichnis '@1' konnte nicht angelegt werden." ;;
            E_DblInUsr) LOCTX="Abbruch durch Leereingabe erkannt." ;;
            E_DoDstErr) LOCTX="Unbekannte bzw. nicht unterstützte Linux-Distribution '@1'.\n" ;;
            E_InstAlry) LOCTX="Offensichtlich ist ${PRGRM} bereits installiert (Environment-Variablen ${PRGRM}_* sind gesetzt)." ;;
            E_InstCopy) LOCTX="Eine oder mehrere erforderliche Dateien konnten nicht in's Ziel kopiert werden.${ERROR_END}" ;;
            E_InstDirs) LOCTX="Ein oder mehrere benötigte Verzeichnisse konnten nicht angelegt werden.${ERROR_END}" ;;
            E_InstDist) LOCTX="Die vorliegende Linux-Distribution wird nicht unterstützt.${ERROR_END}" ;;
            E_InstEnc)  LOCTX="Die Einrichtung der Datenverschlüsselung ist gescheitert.${ERROR_END}" ;;
            E_InstEnd)  LOCTX="\nDas Installationsskript wird beendet." ;;
            E_InstEnv)  LOCTX="Die Einbettung der Skripte in die Arbeitsumgebung ist gescheitert.${ERROR_END}" ;;
            E_InstInit) LOCTX="Das Skript konnte nicht initialisiert werden.${ERROR_END}" ;;
            E_InstNet)  LOCTX="Es besteht keine Verbindung zum Internet. Daher können keine Programme installiert werden.${ERROR_END}" ;;
            E_InstPrgs) LOCTX="Ein oder mehrere benötigte Pakete '@1' oder ein benötigtes Repository konnte nicht installiert werden.${ERROR_END}" ;;
            E_InstProf) LOCTX="Pfad-Variablen ${PRGRM}_* konnten nicht in ~/.profile eingetragen werden.${ERROR_END}" ;;
            E_InstRoot) LOCTX="Das root-Passwort wurde nicht oder falsch eingegeben.${ERROR_END}" ;;
            E_InstSync) LOCTX="Die Einrichtung der Datensynchronisation ist gescheitert.${ERROR_END}" ;;
            E_InstUser) LOCTX="Abbruch der Dateneingabe durch den Benutzer.${ERROR_END}" ;;
            E_TwoChUsr) LOCTX="Abbruch durch Leereingabe erkannt." ;;
            E_Unknown)  LOCTX="Unbekannter Fehler!? ${ERROR_END}" ;;
            M_CopyOk)   LOCTX="Die Datei '@1'  wurde auf das Ziel ${MM}@2${ZZ} kopiert." ;;
            M_CrFiOk)   LOCTX="Die Datei '${MM}@1${ZZ}' wurde angelegt." ;;
            M_CrFoOk)   LOCTX="Das Verzeichnis '${MM}@1${ZZ}' wurde angelegt." ;;
            M_DblIn)    LOCTX="\nEingabe @1" ;;
            M_DblInOk)  LOCTX="Erkannte Eingabe: @1" ;;
            M_DblInOne) LOCTX="Ersteingabe.....: " ;;
            M_DblInTwo) LOCTX="Kontrolleingabe.: " ;;
            M_DblInUsg) LOCTX="(Abbrechen mit leerer Eingabe oder STRG-C. Einfügen aus Zwischenablge mit STRG-UMSCH-V)" ;;
            M_DoCpy)    LOCTX="Die erforderlichen Dateien werden kopiert." ;;
            M_DoCpyOk)  LOCTX="Die erforderlichen Dateien wurden kopiert.\n" ;;
            M_DoDirs)   LOCTX="Die Verzeichnisstruktur wird angelegt." ;;
            M_DoDirsOk) LOCTX="Die Verzeichnisstruktur wurde angelegt.\n" ;;
            M_DoDstOk)  LOCTX="Die Linux-Distribution ${MM}@1${ZZ} wurde erkannt." ;;
            M_DoEnc)    LOCTX="Die Datenverschlüsselug mit EncFS wird eingerichtet." ;;
            M_DoEnc1)   LOCTX="\nSollen die Vorgaben für die Datenverschlüsselung zwecks Wiederverwendung auf weiteren Geräten, die auf die Cloud-Daten zugreifen sollen, im Installationsquellverzeichnis ${MM}@1${ZZ} gespeichert werden?\n" ;;
            M_DoEnc2)   LOCTX="Hinweis: der Zugriff auf die Cloud-Daten ist nur mit jeweils identischen Verschlüsselungsvorgaben möglich! Das Verschlüsselungs-Kennwort wird nicht gespeichert.\n" ;;
            M_DoEncOk)  LOCTX="Die Datenverschlüsselug mit EncFS wurde eingerichtet.\n" ;;
            M_DoEnvOk)  LOCTX="Die Desktop-Umgebung ${MM}@1${ZZ} wurde erkannt.\n" ;;
            M_DoIniOk)  LOCTX="Startverzeichnis ist ${MM}@1${ZZ}." ;;
            M_DoKde)    LOCTX="Der KDE-Desktop wird eingerichtet." ;;
            M_DoKdeAut) LOCTX="${MM}@1${ZZ} wurde im Autostart-Ordner verlinkt." ;;
            M_DoKdeMnu) LOCTX="${MM}@1${ZZ} wurde in das KDE-Menü eingetragen." ;;
            M_DoKdeOk)  LOCTX="Die KDE-Arbeitsumgebung wurde eingerichtet.\n" ;;
            M_DoKdeShu) LOCTX="${MM}@1${ZZ} wurde im shutdown-Ordner verlinkt." ;;
            M_DoOse)    LOCTX="Die Installation der Pakete ${MM}@1${ZZ} wird sichergestellt." ;;
            M_DoOseOk)  LOCTX="Die erforderlichen Pakete sind nun vollständig installiert.\n" ;;
            M_DoOseRep) LOCTX="Das filesystems-Repository wurde erfolgreich installiert.\n" ;;
            M_DoPrf)    LOCTX="Die ${PRGRM}-Umgebungsvariablen werden in die Datei ~/.profile eingetragen." ;;
            M_DoPrfOk)  LOCTX="Die ${PRGRM}-Umgebungsvariablen wurden in ~/.profile eingetragen.\n" ;;
            M_DoSyn)    LOCTX="Die Datensynchronisation mit dem WebDAV-Server wird eingerichtet." ;;
            M_DoSyn1)   LOCTX="\nSollen die Vorgaben für den WebDAV-Zugriff zwecks Wiederverwendung auf weiteren Geräten, auf die Cloud-Daten zugreifen sollen, im Installationsquellverzeichnis ${MM}@1${ZZ} gespeichert werden?\n" ;;
            M_DoSyn2)   LOCTX="Hinweis: der Zugriff auf die Cloud-Daten ist nur mit jeweils identischen WebDAV-Parametern für Server-URL und Benutzerkennung möglich! Das WebDAV-Kennwort wird nicht gespeichert.\n" ;;
            M_DoSynBck) LOCTX="Es wurde eine Sicherheitskopie der Datei ${MM}@1${ZZ} angelegt (${MM}@2${ZZ})." ;;
            M_DoSynOk)  LOCTX="Die Datensynchronisation mit dem WebDAV-Server wurde eingerichtet.\n" ;;
            M_InDav)    LOCTX="Die Anmeldeparameter für den WebDAV-Server müssen eingegeben werden." ;;
            M_InDavRe1) LOCTX="\nEine Datei ${MM}@1${ZZ} mit WebDAV-Anmeldeparametern aus einer bestehenden ${PRGRM}-Installation wurde gefunden. Sollen die WebDAV-Vorgaben der bestehenden Installation wiederverwendet werden, oder soll eine Neueingabe der WebDAV-Anmeldeparameter erfolgen?\n" ;;
            M_InDavRe2) LOCTX="Bei Eingabe abweichender WevDAV-Parameter kann nicht auf bereits vorhandene Daten zugegriffen werden! Das WebDAV-Kennwort muss in jedem Fall neu eingegeben werden.\n" ;;
            M_InDavUrl) LOCTX="Die WebDAV-URL ${MM}@1${ZZ} wird wiederverwendet." ;;
            M_InDavUsr) LOCTX="Der WebDAV-Benutzer ${MM}@1${ZZ} wird wiederverwendet." ;;
            M_InEnc)    LOCTX="Die Vorgaben für die Verschlüsselung der Cloud-Daten müssen eingegeben werden." ;;
            M_InEnc1)   LOCTX="\nEine Datei ${MM}@1${ZZ} aus einer bestehenden ${PRGRM}-Installation wurde gefunden. Sollen die Verschlüsselungsvorgaben der bestehenden Installation wiederverwendet werden, oder soll eine Neuerstellung der ${MM}@1${ZZ} erfolgen?\n" ;;
            M_InEnc2)   LOCTX="Bei Neuerstellung der '@1' kann nicht auf schon vorhandene verschlüsselte Daten zugegriffen werden! Das Verschlüsselungs-Kennwort muss in jedem Fall neu einegegeben werden.\n" ;;
            M_InEncIn)  LOCTX="des Verschlüsselungs-Passworts für die Cloud-Daten" ;;
            M_InEncOk)  LOCTX="\nDie Verschlüsselungs-Vorgaben für die Cloud-Daten sind nun festgelegt.\n" ;;
            M_InRoo1)   LOCTX="Für einige Aktionen dieses Skripts sind root-Rechte erforderlich. Die root-Rechte werden für die Installation der erforderlichen Programme wie EncFS, Unison und DavFS2 sowie für Einträge in die Konfigurations-Datei '@1' benötigt, von der eine Sicherheitskopie unter dem Namen '@2' angelegt wird.\n" ;;
            M_InRooOk)  LOCTX="\nDer root-Account ist nun freigeschaltet.\n" ;;
            M_InstSuc1) LOCTX="${PRGRM} ${PRGRM_VER} ist nun installiert." ;;
            M_InstSuc2) LOCTX="Das System sollte nun neu gestartet werden (Reboot)." ;;
            M_InstTtle) LOCTX="${PRGRM}: Installation" ;;
            M_RmFCOk)   LOCTX="Der Ordner '${MM}@1${ZZ}' wurde samt Inhalt entfernt." ;;
            M_TwoChUsg) LOCTX="(Abbruch durch Leereingabe): " ;;
            Q_DoEnc)    LOCTX="(s) für Speichern, (n) für nicht speichern" ;;
            Q_DoEncN)   LOCTX="n" ;;
            Q_DoEncY)   LOCTX="s" ;;
            Q_DoInsAny) LOCTX="Soll die Installation jetzt trotzdem durchgeführt werden?\n" ;;
            Q_DoInsYN)  LOCTX="(j) für Durchführen, (n) für nicht durchführen" ;;
            Q_DoSyn)    LOCTX="(s) für Speichern, (n) für nicht speichern" ;;
            Q_DoSynN)   LOCTX="n" ;;
            Q_DoSynY)   LOCTX="s" ;;
            Q_InDavOk)  LOCTX="\nDie WebDAV-Serverdaten liegen nun vollständig vor.\n" ;;
            Q_InDavPwd) LOCTX="des Passworts zur Anmeldung am WebDAV-Server" ;;
            Q_InDavRe)  LOCTX="(w) für Wiederverwenden, (n) für Neueingabe" ;;
            Q_InDavReN) LOCTX="n" ;;
            Q_InDavReY) LOCTX="w" ;;
            Q_InDavUrl) LOCTX="der URL des WebDAV-Servers (z.B. https://47110815.webdav.myprovider.com/)" ;;
            Q_InDavUsr) LOCTX="der Benutzerkennung zur Anmeldung am WebDAV-Server (ist oft eine e-Mail-Adresse)" ;;
            Q_InEnc)    LOCTX="(w) für Wiederverwenden, (n) für Neueingabe" ;;
            Q_InEncN)   LOCTX="n" ;;
            Q_InEncY)   LOCTX="w" ;;
            Q_No)       LOCTX="n" ;;
            Q_Yes)      LOCTX="j" ;;
            T_InstBeg)  LOCTX="\n\n\n@1 (@2 v@3) Start..." ;;
            T_InstEnd)  LOCTX="@1 (@2 v@3) Rückgabewert ist '@4'." ;;
            W_CrFiTrg)  LOCTX="Die Datei '@1' existiert bereits." ;;
            W_CrFoTrg)  LOCTX="Das Verzeichnis '@1' existiert bereits." ;;
            W_DblInCmp) LOCTX="Die beiden Eingaben stimmen nicht überein - neuer Versuch.\n" ;;
            W_DoEnvMan) LOCTX="Die ${PRGRM}-Skripte in '~/bin/' müssen manuell in die Desktop-Umgebung eingefügt werden.\n" ;;
            W_DoEnvSup) LOCTX="Unbekannte bzw. nicht unterstützte Desktop-Umgebung '@1'." ;;
            W_DoInsAly) LOCTX="${PRGRM} scheint schon installiert zu sein!" ;;
            W_RmFCFail) LOCTX="Der Ordner '@1' bzw. sein Inhalt konnte nicht entfernt werden." ;;
            W_RmFCTrg)  LOCTX="Der Ordner '@1' existiert nicht." ;;
            W_TwoChErr) LOCTX="Ungültige Eingabe - neuer Versuch.\n" ;;
            *)          LOCTX="LocTx: $1 ??? (${CLOC})" ;;
         esac ;;

      *)
         case "$1" in
            E_CopyFail) LOCTX="Failed to copy file '@1' to target '@2'." ;;
            E_CopySrc)  LOCTX="File '@1' not found." ;;
            E_CopyTrg)  LOCTX="Target file '@1' alread exists." ;;
            E_CrFiFail) LOCTX="Failed to create file '@1'." ;;
            E_CrFiTrg)  LOCTX="File '@1' already exists and is not empty." ;;
            E_CrFoFail) LOCTX="Failed to create directory '@1'." ;;
            E_DblInUsr) LOCTX="User cancellation detected by empty input." ;;
            E_DoDstErr) LOCTX="Unknown or unsupported LINUX distribution '@1'.\n" ;;
            E_InstAlry) LOCTX="Apparently ${PRGRM} is already installed (environment variables ${PRGRM}_* are defined)." ;;
            E_InstCopy) LOCTX="Failed to copy one or more necessary files.${ERROR_END}" ;;
            E_InstDirs) LOCTX="Failed to create one or more needed directories.${ERROR_END}" ;;
            E_InstDist) LOCTX="The recognized LINUX distribution is not supported.${ERROR_END}" ;;
            E_InstEnc)  LOCTX="Failed to configure data encryption.${ERROR_END}" ;;
            E_InstEnd)  LOCTX="\nThe install script is terminated." ;;
            E_InstEnv)  LOCTX="Failed to embed the scripts into the desktop environment.${ERROR_END}" ;;
            E_InstInit) LOCTX="Failed to initialize the script.${ERROR_END}" ;;
            E_InstNet)  LOCTX="There is no connection with the Internet. Hence, no programs can be installed.${ERROR_END}" ;;
            E_InstPrgs) LOCTX="Failed to install one or more needed repositories or programs from list '@1'.${ERROR_END}" ;;
            E_InstProf) LOCTX="Faild to add the environment variables ${PRGRM}_* to ~/.profile.${ERROR_END}" ;;
            E_InstRoot) LOCTX="Wrong or empty root password.${ERROR_END}" ;;
            E_InstSync) LOCTX="Failed to configure the data synchronization.${ERROR_END}" ;;
            E_InstUser) LOCTX="Data input aborted by the user.${ERROR_END}" ;;
            E_TwoChUsr) LOCTX="User cancellation detected by empty input." ;;
            E_Unknown)  LOCTX="Unknown error!? ${ERROR_END}" ;;
            M_CopyOk)   LOCTX="File '@1'  copied to target ${MM}@2${ZZ}." ;;
            M_CrFiOk)   LOCTX="File '${MM}@1${ZZ}' created." ;;
            M_CrFoOk)   LOCTX="Directory '${MM}@1${ZZ}' created." ;;
            M_DblIn)    LOCTX="\nInput @1" ;;
            M_DblInOk)  LOCTX="Identified input: @1" ;;
            M_DblInOne) LOCTX="First input.....: " ;;
            M_DblInTwo) LOCTX="Second input....: " ;;
            M_DblInUsg) LOCTX="(abort by empty input or CTRL-C. Paste from clipboard by CTRL-SHIFT-V)" ;;
            M_DoCpy)    LOCTX="The required files will be copied." ;;
            M_DoCpyOk)  LOCTX="All necessary files were copied successfully.\n" ;;
            M_DoDirs)   LOCTX="The directory structure will be created." ;;
            M_DoDirsOk) LOCTX="All necessary directores were created successfully.\n" ;;
            M_DoDstOk)  LOCTX="Identified LINUX distribution is ${MM}${LINUX_DESC}${ZZ}" ;;
            M_DoEnc)    LOCTX="The EncFS data enncryption will be configured." ;;
            M_DoEnc1)   LOCTX="\nStore the encryption defaults file now in the directory ${MM}@1${ZZ} for the purpose of re-use on other devices in order to access the Cloud data?\n" ;;
            M_DoEnc2)   LOCTX="Note: cloud data access is possible ONLY with the identical encryption defaults file! The encryption password is NOT stored in that file.\n" ;;
            M_DoEncOk)  LOCTX="EncFS data encryption was configured successfully.\n" ;;
            M_DoEnvOk)  LOCTX="Identified desktop environment is ${MM}@1${ZZ}.\n" ;;
            M_DoIniOk)  LOCTX="Script directory is ${MM}@1${ZZ}." ;;
            M_DoKde)    LOCTX="The KDE desktop environment will be configured." ;;
            M_DoKdeAut) LOCTX="Registered ${MM}@1${ZZ} in Autostart directory." ;;
            M_DoKdeMnu) LOCTX="Registered ${MM}@1${ZZ} in KDE menu." ;;
            M_DoKdeOk)  LOCTX="The KDE desktop environment was configured successfully.\n" ;;
            M_DoKdeShu) LOCTX="Registered ${MM}@1${ZZ} in shutdown directory." ;;
            M_DoOse)    LOCTX="The installation of the packages ${MM}@1${ZZ} will be assured." ;;
            M_DoOseOk)  LOCTX="All necessary packages were installed successfully.\n" ;;
            M_DoOseRep) LOCTX="The 'filesystems' repository was added successfully.\n" ;;
            M_DoPrf)    LOCTX="The ${PRGRM} environment variables will be registered in ~/.profile." ;;
            M_DoPrfOk)  LOCTX="The ${PRGRM} environment variables were registered in ~/.profile successfully.\n" ;;
            M_DoSyn)    LOCTX="The WebDAV data synchronization will be configured." ;;
            M_DoSyn1)   LOCTX="\nStore the WebDAV access defaults now in the directory ${MM}@1${ZZ} for the purpose of re-use on other devices in order to access the Cloud data?\n" ;;
            M_DoSyn2)   LOCTX="Note: cloud data access is possible ONLY with the identical WebDAV access defaults! The WebDAV access password is NOT stored.\n" ;;
            M_DoSynBck) LOCTX="A backup copy of ${MM}@1${ZZ} was created as (${MM}@2${ZZ})." ;;
            M_DoSynOk)  LOCTX="The WebDAV data synchronization were configured successfully.\n" ;;
            M_InDav)    LOCTX="The WebDAV server login credentials must be entered now." ;;
            M_InDavRe1) LOCTX="\nA file '${MM}@1${ZZ}' with WebDAV login credentials from an existing ${PRGRM} installation was found. Should these credentials be used now, or should a new input of login credentials take place now?\n" ;;
            M_InDavRe2) LOCTX="The access to the WebDAV storage used by ${PRGRM} installations on other devices is possible ONLY with the correct login credentials! The WebDAV password must be enterd in any case.\n" ;;
            M_InDavUrl) LOCTX="WebDAV URL ${MM}@1${ZZ} is reused." ;;
            M_InDavUsr) LOCTX="WebDAV user ${MM}@1${ZZ} is reused." ;;
            M_InEnc)    LOCTX="The Cloud data encryption defaults must be entered now." ;;
            M_InEnc1)   LOCTX="\nA file '${MM}@1${ZZ}' with EncFS encryption defaults from an existing ${PRGRM} installation was found. Should these be used now, or should a new input of encryption defaults take place now?" ;;
            M_InEnc2)   LOCTX="Note: access to existing encrypted cloud data is NOT possible with a new '@1'. The encryption password must be enterd in any case.\n" ;;
            M_InEncIn)  LOCTX="of the cloud data encryption password" ;;
            M_InEncOk)  LOCTX="\nThe Cloud data encryption defaults are defined now successfully.\n" ;;
            M_InRoo1)   LOCTX="Root access is necessary for some activities of the installation script, e.g. for the installation of the programs like EncFS, Unison, and DavFs2, and for the entries in the system configuration file '@1', of which a backup copy '@2' will be created.\n" ;;
            M_InRooOk)  LOCTX="\nRoot access is activated now.\n" ;;
            M_InstSuc1) LOCTX="${PRGRM} ${PRGRM_VER} was installed successfully." ;;
            M_InstSuc2) LOCTX="Now the system should be restarted (reboot)." ;;
            M_InstTtle) LOCTX="${PRGRM}: Installation" ;;
            M_RmFCOk)   LOCTX="Directory '${MM}@1${ZZ}' was removed (including contents)." ;;
            M_TwoChUsg) LOCTX="(abort by empty input): " ;;
            Q_DoEnc)    LOCTX="(s) for saving, (n) for NOT saving" ;;
            Q_DoEncN)   LOCTX="n" ;;
            Q_DoEncY)   LOCTX="s" ;;
            Q_DoInsAny) LOCTX="Nevertheless carry out the installation now?\n" ;;
            Q_DoInsYN)  LOCTX="(y) for installation, (n) for NOT" ;;
            Q_DoSyn)    LOCTX="(s) for saving, (n) for NOT saving" ;;
            Q_DoSynN)   LOCTX="n" ;;
            Q_DoSynY)   LOCTX="s" ;;
            Q_InDavOk)  LOCTX="\nAll WebDAV server data are complete now.\n" ;;
            Q_InDavPwd) LOCTX="of the WebDAV server login password" ;;
            Q_InDavRe)  LOCTX="(r) for re-use, (n) for new input" ;;
            Q_InDavReN) LOCTX="n" ;;
            Q_InDavReY) LOCTX="r" ;;
            Q_InDavUrl) LOCTX="of the WebDAV server URL (e.g. https://47110815.webdav.myprovider.com/)" ;;
            Q_InDavUsr) LOCTX="of the WebDAV server login user (e.g may be a mail address)" ;;
            Q_InEnc)    LOCTX="(r) for re-use, (n) for new input" ;;
            Q_InEncN)   LOCTX="n" ;;
            Q_InEncY)   LOCTX="r" ;;
            Q_No)       LOCTX="n" ;;
            Q_Yes)      LOCTX="y" ;;
            T_InstBeg)  LOCTX="\n\n\n@1 (@2 v@3) Begin..." ;;
            T_InstEnd)  LOCTX="@1 (@2 v@3) exit code is '@4'." ;;
            W_CrFiTrg)  LOCTX="File '@1' already exists." ;;
            W_CrFoTrg)  LOCTX="Directory '@1' already exists." ;;
            W_DblInCmp) LOCTX="The two inputs do not match - try again.\n" ;;
            W_DoEnvMan) LOCTX="The ${PRGRM} scripts in ~/bin/ must be manually embedded into the desktop environment.\n" ;;
            W_DoEnvSup) LOCTX="Unknown or not supported desktop environment '@1'." ;;
            W_DoInsAly) LOCTX="${PRGRM}  already seems to be installed!" ;;
            W_RmFCFail) LOCTX="Failed to remove directory '@1' (or it's contents)." ;;
            W_RmFCTrg)  LOCTX="Directory '@1' does not exist." ;;
            W_TwoChErr) LOCTX="Invalid input - try again.\n" ;;
            *)          LOCTX="LocTx: $1 ??? (${CLOC})" ;;
         esac ;;
   esac

   if [ -n "$2" ]; then
      LOCTX="${LOCTX//@1/$2}"
   fi

   if [ -n "$3" ]; then
      LOCTX="${LOCTX//@2/$3}"
   fi

   if [ -n "$4" ]; then
      LOCTX="${LOCTX//@3/$4}"
   fi

   if [ -n "$5" ]; then
      LOCTX="${LOCTX//@4/$5}"
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

CopyFile()
{
   # helper: copy a file

   TMP_OUT=""
   TMP_FORCE="$(GetParam "$3$4" "f")"
   TMP_QUIET="$(GetParam "$3$4" "q")"

   if [ -f "$1" ]; then
      if [ "${TMP_FORCE}" != "-f" ]; then
         if [ ! -f "$2" ]; then
            TMP_FORCE="-f"
         fi
      fi

      if [ "${TMP_FORCE}" != "-f" ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            ErrOut "$(LocTx "E_CopyTrg" $2)"
         fi

         return 1
      else
         cp "${TMP_FORCE}" "$1" "$2" > /dev/null 2>&1

         if [ $? -eq 0 ]; then
            if [ "${TMP_QUIET}" != "-q" ]; then
               TextOut "$(LocTx "M_CopyOk" "$1" "$2")"
            fi
         else
            if [ "${TMP_QUIET}" != "-q" ]; then
               ErrOut "$(LocTx "E_CopyFail" "$1" "$2")"
            fi

            return 1
         fi
      fi
   else
      if [ "${TMP_QUIET}" != "-q" ]; then
         ErrOut "$(LocTx "E_CopySrc" "$1")"
      fi

      return 1
   fi

   return 0
}

CreateEmptyFile()
{
   # helper: create empty file

   TMP_QUIET="$(GetParam "$2" "q")"

   if [ -f "$1" ]; then
      if [ $(stat -c %s "$1") -eq 0 ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            WarnOut "$(LocTx "W_CrFiTrg" "$1")"
         fi
      else
         if [ "${TMP_QUIET}" != "-q" ]; then
            ErrOut "$(LocTx "E_CrFiTrg" "$1")"
         fi

         return 1
      fi
   else
      touch "$1" >/dev/null 2>&1

      if [ -f "$1" ]; then
         if [ "${TMP_QUIET}" != "-q" ]; then
            TextOut "$(LocTx "M_CrFiOk" "$1")"
         fi
      else
         if [ "${TMP_QUIET}" != "-q" ]; then
            ErrOut "$(LocTx "E_CrFiFail" "$1")"
         fi

         return 1
      fi
   fi

   return 0
}

CreateFolder()
{
   # helper: create a directory

   TMP_QUIET="$(GetParam "$2" "q")"

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

         return 1
      fi
   fi

   return 0
}

DeleteFolderWithContents()
{
   # helper: delete folder with contents

   TMP_QUIET="$(GetParam "$2" "q")"

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

DoubleCheckedInput()
{
   # helper: double checked input

   VERIFIED_INPUT=""

   TMP_INPUT1=""
   TMP_INPUT2=""

   InfoOut "$(LocTx "M_DblIn" "$1")"
   TextOut "$(LocTx "M_DblInUsg")"

   while true; do
      read -p "$(LocTx "M_DblInOne")" TMP_INPUT1

      if [ -n "${TMP_INPUT1}" ]; then
         read -p "$(LocTx "M_DblInTwo")" TMP_INPUT2

         if [ -n "${TMP_INPUT2}" ]; then
            if [ "${TMP_INPUT1}" == "${TMP_INPUT2}" ]; then
               VERIFIED_INPUT="${TMP_INPUT2}"
               InfoOut "$(LocTx "M_DblInOk" "${VERIFIED_INPUT}")"
               break
            else
               WarnOut "$(LocTx "E_DblInUsr")"
            fi
         else
            ErrOut "$(LocTx "E_DblInUsr")"
            return 1
         fi
      else
         ErrOut "$(LocTx "E_DblInUsr")"
         return 1
      fi
   done

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

CheckDistribution()
{
   # detect current LINUX distribution

   LINUX_DIST="$(lsb_release -is|cut -d\  -f1|tr 'A-Z' 'a-z')"

   case "${LINUX_DIST}" in
      "opensuse")
         LINUX_DESC="$(lsb_release -ds | sed 's/\"//g')"
         TextOut "$(LocTx "M_DoDstOk" "${LINUX_DESC}")"
         ;;

      *)
         ErrOut "$(LocTx "E_DoDstErr" "${LINUX_DIST}")"
         return 1 ;;
   esac

   DESKTOP_TYPE="$(echo ${XDG_CURRENT_DESKTOP}|cut -d\  -f1|tr 'a-z' 'A-Z')"

   case "${DESKTOP_TYPE}" in
      "KDE")
         TextOut "$(LocTx "M_DoEnvOk" "${DESKTOP_TYPE}")"
         ;;

      *)
         WarnOut "$(LocTx "W_DoEnvSup" "${DESKTOP_TYPE}")"
         WarnOut "$(LocTx "W_DoEnvMan")"
         ;;
   esac

   return 0
}

CheckInstall()
{
   # check if PRGRM is installed

   if [ -d "${DIR_APPDIR}" ]; then
      WarnOut "$(LocTx "W_DoInsAly")"
      WarnOut "$(LocTx "Q_DoInsAny")"

      TMP_Y="$(LocTx "Q_Yes")"
      TMP_N="$(LocTx "Q_No")"
      TwoChoicesInput "$(LocTx "Q_DoInsYN")" "${TMP_Y}" "${TMP_N}"

      case "${TWO_INPUT}" in
         "${TMP_Y}") ;;
         *)        return 1 ;;
      esac
   fi

   return 0
}

CheckInternet()
{
   # check internet access

   ping -c 1 -w 3 -q 8.8.8.8 > /dev/null 2>&1

   if [ $? -ne 0 ]; then
      return 1
   fi

   return 0
}

CleanUp()
{
   # remove temporary files

   if [ -f "${TMP_FILE1}" ]; then
      rm -f "${TMP_FILE1}" > /dev/null 2>&1
   fi

   if [ -f "${TMP_FILE2}" ]; then
      rm -f "${TMP_FILE2}" > /dev/null 2>&1
   fi

   return 0
}

ConfigureEncrypting()
{
   # configure ENCFS encryption
   TextOut "$(LocTx "M_DoEnc")"

   CleanUp

   rm "${ENC_CONFIG}" > /dev/null 2>&1

   if [ ${ENC_REUSE} -ne 0 ]; then
      # reuse existing .encfs6.xml

      cp "${ENC_REUSEFILE}" "${ENC_CONFIG}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi
   else
      # create new .encfs6.xml

      echo "p" > "${TMP_FILE1}"
      if [ $? -ne 0 ]; then return 1;  fi

      echo "echo \"${ENCFSPWD}\"" > "${TMP_FILE2}"
      chmod +x "${TMP_FILE2}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi

      encfs --extpass="${TMP_FILE2}" "${DIR_CHIPHER}" "${DIR_DATA}" < "${TMP_FILE1}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi

      fusermount -u "${DIR_DATA}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi

      mv "${DIR_CHIPHER}/${ENC_XML}" "${ENC_CONFIG}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi

      TextOut "$(LocTx "M_DoEnc1" "${SCRIPT_DIR}")"
      InfoOut "$(LocTx "M_DoEnc2")"

      TMP_Y="$(LocTx "Q_DoEncY")"
      TMP_N="$(LocTx "Q_DoEncN")"
      TwoChoicesInput "$(LocTx "Q_DoEnc")" "${TMP_Y}" "${TMP_N}"

      case "${TWO_INPUT}" in
         "${TMP_Y}") CopyFile "${ENC_CONFIG}" "${ENC_REUSEFILE}" -f
                     if [ $? -ne 0 ]; then return 1;  fi ;;
         "${TMP_N}") ;;
         *)          return 1 ;;
      esac
   fi

   CleanUp

   InfoOut "$(LocTx "M_DoEncOk")"

   return 0
}

ConfigureDesktop()
{

   case "${DESKTOP_TYPE}" in
      "KDE")
         ConfigureDesktopKDE
         if [ $? -ne 0 ]; then return 1;  fi ;;

      *)
         # not supported
         ;;
   esac

   return 0
}

ConfigureDesktopKDE()
{
   # configure KDE desktop environment
   TextOut "$(LocTx "M_DoKde")"

   CleanUp

   # copy all desktop files to temp folder and replace home path
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.(desktop|directory)$"

   for TMP_LOOP in $(find "${SCRIPT_DIR}/env/desk" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      TMP_TARGET="${TMP_FOLDER}/$(basename "${TMP_LOOP}")"
      cat "${TMP_LOOP}" | sed "s/@H@/$(echo ${HOME}|sed -e 's/[]\/()$*.^|[]/\\&/g')/g" > "${TMP_TARGET}"
      if [ $? -ne 0 ]; then return 1;  fi
   done

   # install all desktop files to program menu
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.directory$"
   MENU_FOLDER="$(find "${TMP_FOLDER}" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)"

   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.desktop$"

   for TMP_LOOP in $(find "${TMP_FOLDER}" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      xdg-desktop-menu install --mode user "${MENU_FOLDER}" "${TMP_LOOP}" > /dev/null 2>&1
      if [ $? -ne 0 ]; then return 1;  fi

      TextOut "$(LocTx "M_DoKdeMnu" "${TMP_FOLDER}/$(basename "${TMP_LOOP}")")"
   done

   # remove desktop files from temp folder
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.(desktop|directory)$"

   for TMP_LOOP in $(find "${TMP_FOLDER}" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      rm -f "${TMP_LOOP}" > /dev/null 2>&1
   done

   # register unlock / lock scripts in Autotart / shutdown folders
   KDE_AUTOSTART="${HOME}/.kde4/Autostart"
   KDE_SHUTDOWN="${HOME}/.kde4/shutdown"

   WORK="${PRGRM}-unlock.sh"
   rm -f "${KDE_AUTOSTART}/${WORK}" > /dev/null 2>&1
   ln -s "${HOME}/bin/${WORK}" "${KDE_AUTOSTART}/${WORK}" > /dev/null 2>&1
   if [ $? -ne 0 ]; then return 1;  fi
   TextOut "$(LocTx "M_DoKdeAut" "${HOME}/bin/${WORK}")"

   if [ ! -d "${KDE_SHUTDOWN}" ]; then
      CreateFolder "${KDE_SHUTDOWN}"
      if [ $? -ne 0 ]; then return 1;  fi
   fi

   WORK="${PRGRM}-lock.sh"
   rm -f "${KDE_SHUTDOWN}/${WORK}" > /dev/null 2>&1
   ln -s "${HOME}/bin/${WORK}" "${KDE_SHUTDOWN}/${WORK}" > /dev/null 2>&1
   if [ $? -ne 0 ]; then return 1;  fi
   TextOut "$(LocTx "M_DoKdeShu" "${HOME}/bin/${WORK}")"

   InfoOut "$(LocTx "M_DoKdeOk")"

   return 0
}

ConfigureSynchronization()
{
   # configure WebDAV access
   TextOut "$(LocTx "M_DoSyn")"

   CleanUp

   if [ -f "${DAV_SECRETS}" ]; then
      rm -f "${DAV_SECRETS}" > /dev/null 2>&1
   fi

   if [ -f "${ETC_FSTAB_BACKUP}" ]; then
      sudo rm -f "${ETC_FSTAB_BACKUP}" > /dev/null 2>&1
   fi

   # add current user to davfs2 group
   if [ $(groups | grep -o "${DAV_GROUP}" | wc -l) -eq 0 ]; then
      TMP_USERMOD="$(sudo which usermod)"
      TMP_USERMOD="$(sudo ${TMP_USERMOD} -aG "${DAV_GROUP}" "${USER}" > /dev/null 2>&1; echo $?)"
      if [ ${TMP_USERMOD} -ne 0 ]; then return 1;  fi
   fi

   # create private .davfs2 folder
   CreateFolder "${DAV_FOLDER}"
   if [ $? -ne 0 ]; then return 1;  fi

   # create private .davfs2.conf file with 'delay_upload 0' and 'use_locks 0'
   if [ -f "${DAV_CONFIG}" ]; then
      cat "${DAV_CONFIG}" | grep -vE 'delay_upload|use_locks' > "${TMP_FILE1}"
   else
      DAV_CONF_GLOBAL="$(find /etc -iname davfs2.conf -print 2>/dev/null|grep 'davfs2\.conf')"

      if [ -n "${DAV_CONF_GLOBAL}" ]; then
         cat "${DAV_CONF_GLOBAL}" | grep -vE 'delay_upload|use_locks' > "${TMP_FILE1}"
      else
         CreateEmptyFile "${TMP_FILE1}" -q
         if [ $? -ne 0 ]; then return 1;  fi
      fi
   fi

   echo "delay_upload 0" >> "${TMP_FILE1}"
   echo "use_locks 0" >> "${TMP_FILE1}"

   cat "${TMP_FILE1}" > "${DAV_CONFIG}"
   if [ $? -ne 0 ]; then return 1;  fi

   CleanUp

   # create private davfs2 secrets file, modify rights
   echo "${WEBDAVURL} ${WEBDAVUSR} ${WEBDAVPWD}" > "${DAV_SECRETS}"
   if [ $? -ne 0 ]; then return 1;  fi

   chmod g-rw,o-rw,a-x,u+rw "${DAV_SECRETS}" > /dev/null 2>&1
   if [ $? -ne 0 ]; then return 1;  fi

   # add WebDAV mount informations to /etc/fstab
   sudo sh -c "cat ${ETC_FSTAB} > ${ETC_FSTAB_BACKUP}"
   if [ $? -ne 0 ]; then return 1;  fi
   TextOut "$(LocTx "M_DoSynBck" "${ETC_FSTAB}" "${ETC_FSTAB_BACKUP}")"

   cat "${ETC_FSTAB}" | grep -vi "${WEBDAVURL}" > "${TMP_FILE1}"
   if [ $? -gt 1 ]; then return 1;  fi

   echo "${WEBDAVURL} ${DIR_CLOUD} davfs user,rw,noauto 0 0" >> "${TMP_FILE1}"
   if [ $? -ne 0 ]; then return 1;  fi

   sudo sh -c "cat ${TMP_FILE1} > ${ETC_FSTAB}"
   if [ $? -ne 0 ]; then return 1;  fi

   # mount / unmount is not possible here, because the usermod command is
   # effective not before logoff / logon
   ## mount "${DIR_CLOUD}"
   ## fusermount -u "${DIR_CLOUD}"

   if [ ${DAV_REUSE} -eq 0 ]; then
      TextOut "$(LocTx "M_DoSyn1" "${SCRIPT_DIR}")"
      InfoOut "$(LocTx "M_DoSyn2")"

      TMP_Y="$(LocTx "Q_DoSynY")"
      TMP_N="$(LocTx "Q_DoSynN")"
      TwoChoicesInput "$(LocTx "Q_DoSyn")" "${TMP_Y}" "${TMP_N}"

      case "${TWO_INPUT}" in
         "${TMP_Y}") echo "${WEBDAVURL} ${WEBDAVUSR}" > "${DAV_REUSEFILE}"
                     if [ $? -ne 0 ]; then return 1;  fi ;;
         "${TMP_N}") ;;
         *)          return 1 ;;
      esac
   fi

   InfoOut "$(LocTx "M_DoSynOk")"

   return 0
}

CopyFiles()
{
   # copy all necessary files
   TextOut "$(LocTx "M_DoCpy")"

   # copy all shell scripts ~/bin, change mode to executable
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.sh$"

   for TMP_LOOP in $(find "${SCRIPT_DIR}/bin" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      TMP_TARGET="${HOME}/bin/$(basename "${TMP_LOOP}")"

      CopyFile "${TMP_LOOP}" "${TMP_TARGET}" -f
      if [ $? -ne 0 ]; then return 1;  fi

      chmod u+x "${TMP_TARGET}"
      if [ $? -ne 0 ]; then return 1;  fi
   done

   # copy all icon files to DIR_APPDIR/icons
   TMP_REGEX=".*\/${PRGRM}-[a-z]+\.svg$"

   for TMP_LOOP in $(find "${SCRIPT_DIR}/env/icons" -regextype posix-extended -regex "${TMP_REGEX}" 2>/dev/null)
   do
      TMP_TARGET="${DIR_ICONDIR}/$(basename "${TMP_LOOP}")"

      CopyFile "${TMP_LOOP}" "${TMP_TARGET}" -f
      if [ $? -ne 0 ]; then return 1;  fi
   done

   # copy copyright file to ~/bin
   TMP_SOURCE="${SCRIPT_DIR}/copyright.txt"
   TMP_TARGET="${HOME}/bin/${PRGRM}-$(basename "${TMP_SOURCE}")"

   CopyFile "${TMP_SOURCE}" "${TMP_TARGET}" -f
   if [ $? -ne 0 ]; then return 1;  fi

   InfoOut "$(LocTx "M_DoCpyOk")"

   return 0
}

CreateFolders()
{
   # create all necessary directories
   TextOut "$(LocTx "M_DoDirs")"

   CreateFolder "${DIR_APPDIR}"
   if [ $? -ne 0 ]; then return 1;  fi

   CreateFolder "${DIR_ICONDIR}"
   if [ $? -ne 0 ]; then return 1;  fi

   CreateFolder "${DIR_BASE}"
   if [ $? -ne 0 ]; then return 1;  fi

   CreateFolder "${DIR_CHIPHER}"
   if [ $? -ne 0 ]; then return 1;  fi

   CreateFolder "${DIR_DATA}"
   if [ $? -ne 0 ]; then return 1;  fi

   CreateFolder "${DIR_CLOUD}"
   if [ $? -ne 0 ]; then return 1;  fi

   InfoOut "$(LocTx "M_DoDirsOk")"

   return 0
}

EncFsInput()
{
   # ask user for all encryption specifications
   TextOut "$(LocTx "M_InEnc")"

   ENC_CONF=""

   if [ ${ENC_REUSE} -ne 0 ]; then
      TextOut "$(LocTx "M_InEnc1" "${ENC_XML}")"
      WarnOut "$(LocTx "M_InEnc2" "${ENC_XML}")"

      TMP_Y="$(LocTx "Q_InEncY")"
      TMP_N="$(LocTx "Q_InEncN")"
      TwoChoicesInput "$(LocTx "Q_InEnc")" "${TMP_Y}" "${TMP_N}"

      case "${TWO_INPUT}" in
         "${TMP_Y}") ;;
         "${TMP_N}") ENC_REUSE=0 ;;
         *)        return 1 ;;
      esac
   else
   echo "AHA!"
   fi

   DoubleCheckedInput "$(LocTx "M_InEncIn")"
   if [ $? -ne 0 ]; then
      return 1
   else
      ENCFSPWD="${VERIFIED_INPUT}"
   fi

   InfoOut "$(LocTx "M_InEncOk")"
   return 0
}

InstallOpenSuse()
{
   # openSuSE: install all necessary software
   PROGRAM_LIST="encfs davfs2 unison rsync kdialog"

   TextOut "$(LocTx "M_DoOse" "${PROGRAM_LIST}")"

   # openSuSE: if necessary, add filesystems repository for davfs2
   if [ $(zypper lr 2>/dev/null | grep "| filesystems " | wc -l) -eq 0 ]; then
      SUSEVER="$(lsb_release -rs)"
      REPOURL=http://download.opensuse.org/repositories/filesystems/openSUSE_${SUSEVER}/filesystems.repo

      sudo zypper -qn --gpg-auto-import-keys ar -f "${REPOURL}"
      if [ $? -ne 0 ]; then return 1;  fi

      InfoOut "$(LocTx "M_DoOseRep")"
   fi

   # openSuSE: install needed packages
   sudo  zypper -qn --gpg-auto-import-keys in ${PROGRAM_LIST} >/dev/null 2>&1
   if [ $? -ne 0 ]; then return 1;  fi

   InfoOut "$(LocTx "M_DoOseOk")"
   return 0
}

InstallPrograms()
{
   # install all necessary software
   case "${LINUX_DIST}" in
      "opensuse")
         InstallOpenSuse
         if [ $? -ne 0 ]; then return 1;  fi ;;

      *)
         return 1 ;;
   esac

   return 0
}

RootPasswordInput()
{
   # open root access for script

   TextOut "$(LocTx "M_InRoo1" "${ETC_FSTAB}" "${ETC_FSTAB_BACKUP}")"

   sudo -v
   if [ $? -ne 0 ]; then return 1;  fi

   InfoOut "$(LocTx "M_InRooOk")"
   return 0
}

ScriptInit()
{
   CreateFolder "${TMP_FOLDER}" -q
   if [ $? -ne 0 ]; then return 1;  fi

   cd "${SCRIPT_DIR}"
   if [ $? -ne 0 ]; then return 1;  fi

   if [  -f "${DAV_REUSEFILE}" ]; then
      DAV_REUSE=1
   fi

   if [  -f "${ENC_REUSEFILE}" ]; then
      ENC_REUSE=1
   fi

   TextOut "$(LocTx "M_DoIniOk" "${SCRIPT_DIR}")"

   return 0
}

ScriptFinish()
{
   # lock root access
   sudo -k

   # remove temp directory
   DeleteFolderWithContents "${TMP_FOLDER}" -q

   return 0
}

DavFsInput()
{
   # ask user for all WebDAV specifications

   TextOut "$(LocTx "M_InDav")"

   if [ ${DAV_REUSE} -ne 0 ]; then
      TextOut "$(LocTx "M_InDavRe1" "${DAV_SECFILE}")"
      WarnOut "$(LocTx "M_InDavRe2")"

      TMP_Y="$(LocTx "Q_InDavReY")"
      TMP_N="$(LocTx "Q_InDavReN")"
      TwoChoicesInput "$(LocTx "Q_InDavRe")" "${TMP_Y}" "TMP_N"

      case "${TWO_INPUT}" in
         "${TMP_Y}") ;;
         "${TMP_N}") DAV_REUSE=0 ;;
         *)        return 1 ;;
      esac
   fi

   if [ ${DAV_REUSE} -ne 0 ]; then
      WEBDAVURL="$(head -n 1 "${DAV_REUSEFILE}" | awk '{print $1}')"
      TextOut "$(LocTx "M_InDavUrl" "${WEBDAVURL}")"

      WEBDAVUSR="$(head -n 1 "${DAV_REUSEFILE}" | awk '{print $2}')"
      TextOut "$(LocTx "M_InDavUsr" "${WEBDAVUSR}")"
   else
      DoubleCheckedInput "$(LocTx "Q_InDavUrl")"
      if [ $? -ne 0 ]; then return 1; fi
      WEBDAVURL="${VERIFIED_INPUT}"

      DoubleCheckedInput "$(LocTx "Q_InDavUsr")"
      if [ $? -ne 0 ]; then return 1; fi
      WEBDAVUSR="${VERIFIED_INPUT}"
   fi

   DoubleCheckedInput "$(LocTx "Q_InDavPwd")"
   if [ $? -ne 0 ]; then return 1; fi
   WEBDAVPWD="${VERIFIED_INPUT}"

   InfoOut "$(LocTx "Q_InDavOk")"
   return 0
}

WriteToDotProfile()
{
   # add path variables to ~/.profile
   TextOut "$(LocTx "M_DoPrf")"

   CleanUp

   if [ -f ~/.profile ]; then
      cat ~/.profile | grep -v "export ${PRGRM}_" > "${TMP_FILE1}"
   else
      echo "# .profile" > "${TMP_FILE1}"
   fi

   echo -e "\n" >> "${TMP_FILE1}"
   echo "export ${PRGRM}_BASE=${DIR_BASE}" >> "${TMP_FILE1}"
   echo "export ${PRGRM}_CHIPHER=${DIR_CHIPHER}" >> "${TMP_FILE1}"
   echo "export ${PRGRM}_DATA=${DIR_DATA}" >> "${TMP_FILE1}"
   echo "export ${PRGRM}_CLOUD=${DIR_CLOUD}" >> "${TMP_FILE1}"
   echo "export ${PRGRM}_APPDIR=${DIR_APPDIR}" >> "${TMP_FILE1}"

   mv -fb "${TMP_FILE1}" ~/.profile >/dev/null 2>&1
   if [ $? -ne 0 ]; then return 1;  fi

   InfoOut "$(LocTx "M_DoPrfOk")"
   return 0
}

# ### ### ### Main ### ### ###

MSG_TITLE="$(LocTx "M_InstTtle")"
ERROR_END="$(LocTx "E_InstEnd")"

InfoOut "$(LocTx "T_InstBeg" "${MSG_TITLE}" "${SCRIPT_NAME}" "${SCRIPT_VER}")"

while true; do
   ScriptInit
   if [ $? -ne 0 ]; then EXIT_CD=1; break; fi

   CheckInternet
   if [ $? -ne 0 ]; then EXIT_CD=2; break; fi

   CheckDistribution
   if [ $? -ne 0 ]; then EXIT_CD=3; break; fi

   CheckInstall
   if [ $? -ne 0 ]; then EXIT_CD=4; break; fi

   DavFsInput
   if [ $? -ne 0 ]; then EXIT_CD=5; break; fi

   EncFsInput
   if [ $? -ne 0 ]; then EXIT_CD=5; break; fi

   RootPasswordInput
   if [ $? -ne 0 ]; then EXIT_CD=6; break; fi

   InstallPrograms
   if [ $? -ne 0 ]; then EXIT_CD=7; break; fi

   CreateFolders
   if [ $? -ne 0 ]; then EXIT_CD=8; break; fi

   CopyFiles
   if [ $? -ne 0 ]; then EXIT_CD=9; break; fi

   WriteToDotProfile
   if [ $? -ne 0 ]; then EXIT_CD=10; break; fi

   ConfigureEncrypting
   if [ $? -ne 0 ]; then EXIT_CD=11; break; fi

   ConfigureSynchronization
   if [ $? -ne 0 ]; then EXIT_CD=12; break; fi

   ConfigureDesktop
   if [ $? -ne 0 ]; then EXIT_CD=13; break; fi

   # success and exit
   break
done

case "${EXIT_CD}" in
   0)   TextOut "$(LocTx "M_InstSuc1")"
        InfoOut "$(LocTx "M_InstSuc2")" ;;
   1)   ErrOut  "$(LocTx "E_InstInit")" ;;
   2)   ErrOut  "$(LocTx "E_InstNet")" ;;
   3)   ErrOut  "$(LocTx "E_InstDist")" ;;
   4)   ErrOut  "$(LocTx "E_InstAlry")" ;;
   5)   ErrOut  "$(LocTx "E_InstUser")" ;;
   6)   ErrOut  "$(LocTx "E_InstRoot")" ;;
   7)   ErrOut  "$(LocTx "E_InstPrgs" "${PROGRAM_LIST}")" ;;
   8)   ErrOut  "$(LocTx "E_InstDirs")" ;;
   9)   ErrOut  "$(LocTx "E_InstCopy")" ;;
   10)  ErrOut  "$(LocTx "E_InstProf")" ;;
   11)  ErrOut  "$(LocTx "E_InstEnc")" ;;
   12)  ErrOut  "$(LocTx "E_InstSync")" ;;
   13)  ErrOut  "$(LocTx "E_InstEnv")" ;;
   *)   ErrOut  "$(LocTx "E_Unknown")" ;;
esac

ScriptFinish

InfoOut "$(LocTx "T_InstEnd" "${MSG_TITLE}" "${SCRIPT_NAME}" "${SCRIPT_VER}" "${EXIT_CD}")"
exit "${EXIT_CD}"

# ### ### ### EOF ### ### ###
