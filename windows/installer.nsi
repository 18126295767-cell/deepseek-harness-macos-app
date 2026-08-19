Unicode true
SetCompressor /SOLID lzma

!ifndef VERSION
  !define VERSION "0.1.0"
!endif
!ifndef STAGE_DIR
  !error "STAGE_DIR is required"
!endif
!ifndef OUT_FILE
  !error "OUT_FILE is required"
!endif

Name "DeepSeek Harness Windows Launcher"
OutFile "${OUT_FILE}"
InstallDir "$LOCALAPPDATA\DeepSeek Harness"
InstallDirRegKey HKCU "Software\DeepSeek Harness" "InstallDir"
RequestExecutionLevel user
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1033 "ProductName" "DeepSeek Harness Windows Launcher"
VIAddVersionKey /LANG=1033 "FileDescription" "DeepSeek Harness Windows Launcher"
VIAddVersionKey /LANG=1033 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1033 "ProductVersion" "${VERSION}"

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "DeepSeek Harness Windows Launcher"
  SetOutPath "$INSTDIR"
  File /r "${STAGE_DIR}\*"
  WriteRegStr HKCU "Software\DeepSeek Harness" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\DeepSeek Harness"
  CreateShortcut "$SMPROGRAMS\DeepSeek Harness\DeepSeek Harness.lnk" "$INSTDIR\launch-dsh.cmd"
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\DeepSeek Harness\DeepSeek Harness.lnk"
  RMDir "$SMPROGRAMS\DeepSeek Harness"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\DeepSeek Harness"
SectionEnd
