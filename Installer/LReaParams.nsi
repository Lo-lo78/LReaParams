; LReaParams native Windows x64 installer (TEST61.12)
; Compile with NSIS 3.x makensis on GitHub Actions, after the C++ build.
; The installer itself is open source; it never deletes native user profiles.
; NSIS/zlib compressor is used (no LZMA module required).

; PROJECT_ROOT must be the ABSOLUTE workspace directory; all packaged input
; files are rooted here because NSIS File paths are relative to the script
; directory even when the compiler is invoked from the repository root.
!ifndef PROJECT_ROOT
  !error "PROJECT_ROOT is required: makensis /DPROJECT_ROOT=C:\path\to\repository Installer/LReaParams.nsi"
!endif

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
OutFile "${PROJECT_ROOT}\dist\LReaParams-${APP_VERSION}-Windows-x64-Setup.exe"
; $APPDATA is resolved at runtime on the target computer for the user
; launching the installer (not for the user who built or published the EXE).
; If this same user previously installed to a custom/portable resource path,
; InstallDirRegKey reuses that saved selection, never another user's HKCU.
InstallDir "$APPDATA\REAPER"
InstallDirRegKey HKCU "${SETTINGS_KEY}" "ResourcePath"
RequestExecutionLevel user
SetCompressor /SOLID zlib
ShowInstDetails show
; Automatically progress from the copy log to the standard Finish page;
; the localized Finish / Fine button closes the installer when pressed.
; The final page is only reached after the installation steps complete.
AutoCloseWindow true
ShowUninstDetails show
BrandingText "LReaParams - free and open-source REAPER extension"

VIProductVersion "0.0.61.0"
VIAddVersionKey "ProductName" "LReaParams"
VIAddVersionKey "CompanyName" "Lo-lo78"
VIAddVersionKey "FileDescription" "LReaParams multilingual installer for REAPER x64"
VIAddVersionKey "FileVersion" "0.0.61"
VIAddVersionKey "LegalCopyright" "Copyright (C) 2026 Lo-lo78"

!define MUI_ABORTWARNING
; Always present the language selection, including on updates where NSIS
; previously stored English. MUI2 will localize Next/Back/Install accordingly.
!define MUI_LANGDLL_ALWAYSSHOW
!define MUI_LANGDLL_ALLLANGUAGES
!define MUI_LANGDLL_WINDOWTITLE "LReaParams - Installer language / Lingua installazione"
!define MUI_LANGDLL_INFO "Choose interface language / Scegli la lingua dell'interfaccia:"
!define MUI_WELCOMEPAGE_TEXT "$(InstallerWelcome)"
!define MUI_DIRECTORYPAGE_TEXT_TOP "$(ResourceDirectoryHelp)"
!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "${SETTINGS_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "InstallerLanguage"

!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE ValidateResourceDirectory
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
; The dedicated completion screen has the standard localized Finish button.
; Do not define MUI_FINISHPAGE_NOAUTOCLOSE: no extra Next is required.
!define MUI_FINISHPAGE_TEXT "$(InstallerFinished)"
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
!insertmacro MUI_RESERVEFILE_LANGDLL

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

; Short screen-reader-friendly messages. The destination edit field displays
; the actual expanded path for THIS Windows account. No personal path is embedded
; into these language strings and no redundant intermediate dialog is shown.
LangString InstallerWelcome ${LANG_ENGLISH} "This wizard installs LReaParams and its offline guides. Close REAPER before continuing. Select Next to choose the resource folder, then Install. When installation is complete, select Finish to close. Existing profiles and settings are preserved."
LangString InstallerWelcome ${LANG_ITALIAN} "Questa procedura installa LReaParams e le guide offline. Chiudi REAPER prima di continuare. Premi Avanti per scegliere la cartella delle risorse, poi Installa. Al termine premi Fine per chiudere. Profili e impostazioni vengono conservati."
LangString InstallerWelcome ${LANG_SPANISH} "Este asistente instala LReaParams y las guías sin conexión. Cierra REAPER antes de continuar. Pulsa Siguiente para elegir la carpeta de recursos y después Instalar. Al finalizar, pulsa Finalizar para cerrar. Se conservan los perfiles y ajustes."
LangString InstallerWelcome ${LANG_FRENCH} "Cet assistant installe LReaParams et les guides hors ligne. Fermez REAPER avant de continuer. Choisissez Suivant pour sélectionner le dossier des ressources, puis Installer. Une fois terminé, choisissez Terminer pour fermer. Vos profils et réglages sont conservés."
LangString InstallerWelcome ${LANG_RUSSIAN} "Мастер установит LReaParams и автономные руководства. Перед продолжением закройте REAPER. Нажмите «Далее», чтобы выбрать папку ресурсов, затем «Установить». После установки нажмите «Готово», чтобы закрыть окно. Профили и настройки сохраняются."
LangString InstallerWelcome ${LANG_SIMPCHINESE} "本向导将安装 LReaParams 和离线指南。请先关闭 REAPER。点击“下一步”选择资源文件夹，然后点击“安装”。安装完成后点击“完成”关闭。现有配置和设置将保留。"
LangString InstallerWelcome ${LANG_JAPANESE} "このウィザードは LReaParams とオフラインガイドをインストールします。先に REAPER を終了してください。「次へ」でリソースフォルダーを選び、「インストール」を選択します。完了後は「完了」で閉じます。既存の設定は保持されます。"

LangString ResourceDirectoryHelp ${LANG_ENGLISH} "The proposed folder is determined automatically from the current Windows user's REAPER resources. To use portable REAPER, select its folder containing reaper.ini. Then choose Install."
LangString ResourceDirectoryHelp ${LANG_ITALIAN} "La cartella proposta viene ricavata automaticamente dalle risorse di REAPER dell'utente Windows corrente. Per REAPER portatile scegli la cartella contenente reaper.ini. Poi premi Installa."
LangString ResourceDirectoryHelp ${LANG_SPANISH} "La carpeta propuesta se determina automáticamente a partir de los recursos de REAPER del usuario actual de Windows. Para REAPER portátil, elige la carpeta que contiene reaper.ini. Después pulsa Instalar."
LangString ResourceDirectoryHelp ${LANG_FRENCH} "Le dossier proposé est déterminé automatiquement pour l'utilisateur Windows actuel. Pour une version portable de REAPER, choisissez le dossier contenant reaper.ini. Puis choisissez Installer."
LangString ResourceDirectoryHelp ${LANG_RUSSIAN} "Предложенная папка определяется автоматически для текущего пользователя Windows. Для портативного REAPER выберите папку с reaper.ini. Затем нажмите «Установить»."
LangString ResourceDirectoryHelp ${LANG_SIMPCHINESE} "默认文件夹根据当前 Windows 用户的 REAPER 资源目录自动确定。若使用便携版 REAPER，请选择包含 reaper.ini 的文件夹，然后点击“安装”。"
LangString ResourceDirectoryHelp ${LANG_JAPANESE} "選択候補のフォルダーは現在の Windows ユーザーの REAPER リソースから自動設定されます。ポータブル版は reaper.ini のあるフォルダーを選び、「インストール」を選択してください。"

LangString InstallerFinished ${LANG_ENGLISH} "LReaParams and its offline guides have been installed successfully. Select Finish to close the installer."
LangString InstallerFinished ${LANG_ITALIAN} "LReaParams e le guide offline sono stati installati correttamente. Premi Fine per chiudere l'installazione."
LangString InstallerFinished ${LANG_SPANISH} "LReaParams y las guías se han instalado correctamente. Pulsa Finalizar para cerrar el instalador."
LangString InstallerFinished ${LANG_FRENCH} "LReaParams et les guides ont été installés avec succès. Choisissez Terminer pour fermer l'installation."
LangString InstallerFinished ${LANG_RUSSIAN} "LReaParams и руководства успешно установлены. Нажмите «Готово», чтобы закрыть установщик."
LangString InstallerFinished ${LANG_SIMPCHINESE} "LReaParams 和离线指南已成功安装。点击“完成”关闭安装程序。"
LangString InstallerFinished ${LANG_JAPANESE} "LReaParams とオフラインガイドのインストールが完了しました。「完了」を押して閉じてください。"

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
  ; No modal pre-install OK: the accessible welcome page already gives
  ; REAPER-closing instructions and installation begins on the InstFiles page.
  ; Existing Settings, Plugins, Tracks, Backups and other user data are untouched.
  CreateDirectory "$INSTDIR\UserPlugins"
  CreateDirectory "$INSTDIR\LReaParams\Plugins"
  CreateDirectory "$INSTDIR\LReaParams\Tracks"
  CreateDirectory "$INSTDIR\LReaParams\Settings"
  CreateDirectory "$INSTDIR\LReaParams\Backups"

  SetOverwrite on
  SetOutPath "$INSTDIR\UserPlugins"
  ClearErrors
  File "${PROJECT_ROOT}\package\UserPlugins\reaper_lreaparams.dll"
  IfErrors 0 dll_installed
    MessageBox MB_ICONSTOP|MB_OK "$(DllCopyFailed)"
    SetErrorLevel 1
    Quit
  dll_installed:

  SetOutPath "$INSTDIR\LReaParams\Guide"
  File /r "${PROJECT_ROOT}\Guide\*.*"

  SetOutPath "$INSTDIR\LReaParams\Licenses"
  File /oname=GPL-3.0.txt "${PROJECT_ROOT}\LICENSE"
  File "${PROJECT_ROOT}\THIRD_PARTY_NOTICES.md"

  ; Include the source for the EXACT commit built by this workflow.
  SetOutPath "$INSTDIR\LReaParams\Source"
  File /oname=LReaParams-0.0.61-Source.zip "${PROJECT_ROOT}\dist\LReaParams-0.0.61-Source.zip"
  File "${PROJECT_ROOT}\dist\SOURCE-COMMIT.txt"

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
  !include "${PROJECT_ROOT}\Installer\Guide-Uninstall.nsh"
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
