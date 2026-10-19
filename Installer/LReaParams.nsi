; LReaParams native Windows x64 installer (TEST61.9)
; Compile with NSIS 3.x makensis on GitHub Actions, after the C++ build.
; The installer itself is open source; it never deletes native user profiles.
; NSIS/zlib compressor is used (no LZMA module required).

Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!define APP_NAME "LReaParams"
!define APP_VERSION "0.0.61"
!define APP_PUBLISHER "Lo-lo78"
!define APP_URL "https://github.com/Lo-lo78/LReaParamsSwitch"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\LReaParams"
!define SETTINGS_KEY "Software\Lo-lo78\LReaParams"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "${__FILEDIR__}\..\dist\LReaParams-${APP_VERSION}-Windows-x64-Setup.exe"
InstallDir "$APPDATA\REAPER"
InstallDirRegKey HKCU "${SETTINGS_KEY}" "ResourcePath"
RequestExecutionLevel user
SetCompressor /SOLID zlib
ShowInstDetails show
ShowUninstDetails show
BrandingText "LReaParams - free and open-source REAPER extension"

VIProductVersion "0.0.61.0"
VIAddVersionKey "ProductName" "LReaParams"
VIAddVersionKey "CompanyName" "Lo-lo78"
VIAddVersionKey "FileDescription" "LReaParams multilingual installer for REAPER x64"
VIAddVersionKey "FileVersion" "0.0.61"
VIAddVersionKey "LegalCopyright" "Copyright (C) 2026 Lo-lo78"

!define MUI_ABORTWARNING
!define MUI_DIRECTORYPAGE_TEXT_TOP "Choose the REAPER *resource* directory, NOT the folder where reaper.exe is installed. Default: $APPDATA\REAPER. For a portable REAPER, choose the portable folder containing reaper.ini."
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "${SETTINGS_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"

!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE ValidateResourceDirectory
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "Japanese"

LangString WrongArchitecture ${LANG_ENGLISH} "This installer requires Windows x64."
LangString WrongArchitecture ${LANG_ITALIAN} "Questo programma di installazione richiede Windows a 64 bit."
LangString WrongArchitecture ${LANG_SPANISH} "Este instalador requiere Windows de 64 bits."
LangString WrongArchitecture ${LANG_FRENCH} "Ce programme d'installation nécessite Windows 64 bits."
LangString WrongArchitecture ${LANG_RUSSIAN} "Для установки требуется 64-разрядная Windows."
LangString WrongArchitecture ${LANG_SIMPCHINESE} "此安装程序需要 64 位 Windows。"
LangString WrongArchitecture ${LANG_JAPANESE} "このインストーラーには64ビット版Windowsが必要です。"

LangString PathUnrecognized ${LANG_ENGLISH} "There is no reaper.ini in the selected directory. It may not be the REAPER resource folder. Continue anyway? Choose No to select another folder."
LangString PathUnrecognized ${LANG_ITALIAN} "Nella cartella scelta non c'è reaper.ini. Potrebbe non essere la cartella delle risorse di REAPER. Continuare comunque? Scegli No per correggere il percorso."
LangString PathUnrecognized ${LANG_SPANISH} "No se encontró reaper.ini en la carpeta elegida. Puede que no sea la carpeta de recursos de REAPER. ¿Continuar? Elige No para cambiarla."
LangString PathUnrecognized ${LANG_FRENCH} "Le fichier reaper.ini est introuvable dans le dossier choisi. Ce n'est peut-être pas le dossier des ressources REAPER. Continuer ? Choisissez Non pour modifier le chemin."
LangString PathUnrecognized ${LANG_RUSSIAN} "В выбранной папке нет файла reaper.ini. Возможно, это не папка ресурсов REAPER. Продолжить? Нажмите Нет, чтобы изменить путь."
LangString PathUnrecognized ${LANG_SIMPCHINESE} "所选文件夹中没有 reaper.ini，可能不是 REAPER 资源文件夹。仍要继续吗？选择“否”更改路径。"
LangString PathUnrecognized ${LANG_JAPANESE} "選択したフォルダーに reaper.ini がありません。REAPERのリソースフォルダーではない可能性があります。続行しますか？「いいえ」で選び直します。"

LangString BeforeInstall ${LANG_ENGLISH} "Close REAPER before installing or updating LReaParams, then press OK. Existing profiles and settings will be preserved."
LangString BeforeInstall ${LANG_ITALIAN} "Prima di installare o aggiornare LReaParams, chiudi REAPER e premi OK. Profili e impostazioni esistenti saranno conservati."
LangString BeforeInstall ${LANG_SPANISH} "Cierra REAPER antes de instalar o actualizar LReaParams y pulsa Aceptar. Se conservarán los perfiles y ajustes existentes."
LangString BeforeInstall ${LANG_FRENCH} "Fermez REAPER avant d'installer ou de mettre à jour LReaParams, puis validez. Les profils et réglages existants seront conservés."
LangString BeforeInstall ${LANG_RUSSIAN} "Закройте REAPER перед установкой или обновлением LReaParams и нажмите OK. Существующие профили и настройки сохранятся."
LangString BeforeInstall ${LANG_SIMPCHINESE} "安装或更新 LReaParams 前，请关闭 REAPER，然后按确定。现有配置和设置将保留。"
LangString BeforeInstall ${LANG_JAPANESE} "LReaParams のインストールまたは更新前に REAPER を終了し、OK を押してください。既存の設定とプロファイルは保持されます。"

LangString DllCopyFailed ${LANG_ENGLISH} "The DLL could not be installed. Please close REAPER and check write permissions, then run the installer again."
LangString DllCopyFailed ${LANG_ITALIAN} "Impossibile installare la DLL. Chiudi REAPER e controlla i permessi di scrittura, poi riprova."
LangString DllCopyFailed ${LANG_SPANISH} "No se pudo instalar la DLL. Cierra REAPER y comprueba los permisos de escritura; vuelve a intentarlo."
LangString DllCopyFailed ${LANG_FRENCH} "Impossible d'installer la DLL. Fermez REAPER et vérifiez les droits d'écriture avant de réessayer."
LangString DllCopyFailed ${LANG_RUSSIAN} "Не удалось установить DLL. Закройте REAPER, проверьте права записи и повторите установку."
LangString DllCopyFailed ${LANG_SIMPCHINESE} "无法安装 DLL。请关闭 REAPER，检查写入权限后重试。"
LangString DllCopyFailed ${LANG_JAPANESE} "DLL をインストールできません。REAPER を終了し、書き込み権限を確認してから再試行してください。"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP|MB_OK "$(WrongArchitecture)"
    Abort
  ${EndIf}
  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function ValidateResourceDirectory
  IfFileExists "$INSTDIR\reaper.ini" directory_ok
  MessageBox MB_ICONEXCLAMATION|MB_YESNO|MB_DEFBUTTON2 "$(PathUnrecognized)" IDYES directory_ok
  Abort
  directory_ok:
FunctionEnd

Section "LReaParams plugin and offline guides" SEC_LRP
  SectionIn RO
  MessageBox MB_ICONINFORMATION|MB_OK "$(BeforeInstall)"

  ; Existing Settings, Plugins, Tracks, Backups and other user data are untouched.
  CreateDirectory "$INSTDIR\UserPlugins"
  CreateDirectory "$INSTDIR\LReaParams\Plugins"
  CreateDirectory "$INSTDIR\LReaParams\Tracks"
  CreateDirectory "$INSTDIR\LReaParams\Settings"
  CreateDirectory "$INSTDIR\LReaParams\Backups"

  SetOverwrite on
  SetOutPath "$INSTDIR\UserPlugins"
  ClearErrors
  File "${__FILEDIR__}\..\package\UserPlugins\reaper_lreaparams.dll"
  IfErrors 0 dll_installed
    MessageBox MB_ICONSTOP|MB_OK "$(DllCopyFailed)"
    SetErrorLevel 1
    Quit
  dll_installed:

  SetOutPath "$INSTDIR\LReaParams\Guide"
  File /r "${__FILEDIR__}\..\Guide\*.*"

  SetOutPath "$INSTDIR\LReaParams\Licenses"
  File /oname=GPL-3.0.txt "${__FILEDIR__}\..\LICENSE"
  File "${__FILEDIR__}\..\THIRD_PARTY_NOTICES.md"

  ; Include the source for the EXACT commit built by this workflow.
  SetOutPath "$INSTDIR\LReaParams\Source"
  File /oname=LReaParams-0.0.61-Source.zip "${__FILEDIR__}\..\dist\LReaParams-0.0.61-Source.zip"
  File "${__FILEDIR__}\..\dist\SOURCE-COMMIT.txt"

  SetOutPath "$INSTDIR\LReaParams"
  WriteUninstaller "$INSTDIR\LReaParams\Uninstall-LReaParams.exe"
  WriteRegStr HKCU "${SETTINGS_KEY}" "ResourcePath" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "LReaParams ${APP_VERSION} for REAPER"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '$"$INSTDIR\LReaParams\Uninstall-LReaParams.exe$"'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd

Function un.onInit
  ; The uninstaller lives in the resource directory's LReaParams subfolder.
  GetFullPathName $INSTDIR "$EXEDIR\.."
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Section "Uninstall"
  ; Remove only installer-owned files. Never remove the users' profile trees.
  Delete "$INSTDIR\UserPlugins\reaper_lreaparams.dll"
  !include "${__FILEDIR__}\Guide-Uninstall.nsh"
  Delete "$INSTDIR\LReaParams\Licenses\GPL-3.0.txt"
  Delete "$INSTDIR\LReaParams\Licenses\THIRD_PARTY_NOTICES.md"
  RMDir "$INSTDIR\LReaParams\Licenses"
  Delete "$INSTDIR\LReaParams\Source\LReaParams-0.0.61-Source.zip"
  Delete "$INSTDIR\LReaParams\Source\SOURCE-COMMIT.txt"
  RMDir "$INSTDIR\LReaParams\Source"
  Delete "$INSTDIR\LReaParams\Uninstall-LReaParams.exe"
  ; Only remove LReaParams if actually empty (it normally contains user profiles).
  RMDir "$INSTDIR\LReaParams"
  ReadRegStr $0 HKCU "${SETTINGS_KEY}" "ResourcePath"
  StrCmp $0 $INSTDIR 0 skip_registry
    DeleteRegKey HKCU "${UNINSTALL_KEY}"
    DeleteRegKey HKCU "${SETTINGS_KEY}"
  skip_registry:
SectionEnd
