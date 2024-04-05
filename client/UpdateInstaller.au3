; ***  WSUS Offline Update 11.9.11 - Installer ***
; ***          - Community Edition -           ***
; ***        Author: T. Wittrock, Kiel         ***
; ***    Dialog scaling added by Th. Baisch    ***

#include <GUIConstants.au3>
#include <WinAPIError.au3>
#RequireAdmin
#pragma compile(CompanyName, "T. Wittrock - Community Edition")
#pragma compile(FileDescription, "WSUS Offline Update Installer")
#pragma compile(FileVersion, 11.9.11.5)
#pragma compile(InternalName, "Installer")
#pragma compile(LegalCopyright, "GNU GPLv3")
#pragma compile(OriginalFilename, UpdateInstaller.exe)
#pragma compile(ProductName, "WSUS Offline Update - Community Edition")
#pragma compile(ProductVersion, 11.9.11.5)

Dim Const $caption                    = "WSUS Offline Update - Community Edition - 11.9.11hf5 - Installer"

; Registry constants
Dim Const $reg_key_wsh_hklm64         = "HKLM64\Software\Microsoft\Windows Script Host\Settings"
Dim Const $reg_key_wsh_hklm           = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings"
Dim Const $reg_key_wsh_hkcu           = "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings"
Dim Const $reg_key_ie                 = "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer"
Dim Const $reg_key_dotnet35           = "HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v3.5"
Dim Const $reg_key_dotnet4            = "HKEY_LOCAL_MACHINE\Software\Microsoft\NET Framework Setup\NDP\v4\Full"
Dim Const $reg_key_wmf                = "HKEY_LOCAL_MACHINE\Software\Microsoft\PowerShell\3\PowerShellEngine"
Dim Const $reg_key_msse               = "HKEY_LOCAL_MACHINE\Software\Microsoft\Microsoft Security Client"
Dim Const $reg_key_hkcu_desktop       = "HKEY_CURRENT_USER\Control Panel\Desktop"
Dim Const $reg_key_hkcu_winmetrics    = "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics"
Dim Const $reg_key_windowsupdate      = "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate"

Dim Const $reg_val_default            = ""
Dim Const $reg_val_enabled            = "Enabled"
Dim Const $reg_val_version            = "Version"
Dim Const $reg_val_pshversion         = "PowerShellVersion"
Dim Const $reg_val_logpixels          = "LogPixels"
Dim Const $reg_val_applieddpi         = "AppliedDPI"
Dim Const $reg_val_wustatusserver     = "WUStatusServer"

; Defaults
Dim Const $msimax                     = 12
Dim Const $default_logpixels          = 96
Dim Const $target_version_dotnet35    = "3.5.30729"

; INI file constants
Dim Const $ini_section_installation   = "Installation"
Dim Const $ini_value_rcerts           = "updatercerts"
Dim Const $ini_value_dotnet35         = "instdotnet35"
Dim Const $ini_value_dotnet4          = "instdotnet4"
Dim Const $ini_value_wmf              = "instwmf"
Dim Const $ini_value_cpp              = "updatecpp"
Dim Const $ini_value_msse             = "instmsse"
Dim Const $ini_value_tsc              = "updatetsc"
; Hidden installation constants
Dim Const $ini_value_skipieinst       = "skipieinst"
Dim Const $ini_value_skipdefs         = "skipdefs"
Dim Const $ini_value_skipdynamic      = "skipdynamic"
Dim Const $ini_value_all              = "all"
Dim Const $ini_value_excludestatics   = "excludestatics"
Dim Const $ini_value_seconly          = "seconly"

Dim Const $ini_section_control        = "Control"
Dim Const $ini_value_verify           = "verify"
Dim Const $ini_value_autoreboot       = "autoreboot"
Dim Const $ini_value_shutdown         = "shutdown"

Dim Const $ini_section_messaging      = "Messaging"
Dim Const $ini_value_showlog          = "showlog"
; Hidden messaging constants
Dim Const $ini_value_showieinfo       = "showieinfo"
Dim Const $ini_value_showdismprogress = "showdismprogress"

Dim Const $ini_section_misc           = "Miscellaneous"
Dim Const $ini_value_monitoron        = "monitoron"
Dim Const $ini_value_wustatusserver   = "WUStatusServer"

Dim Const $ini_section_msi            = "MSI"

Dim Const $enabled                    = "Enabled"
Dim Const $disabled                   = "Disabled"

; Paths
Dim Const $path_max_length            = 192
Dim Const $path_invalid_chars         = "!%&()^+,;="
Dim Const $path_rel_builddate         = "\builddate.txt"
Dim Const $path_rel_hashes            = "\md\"
Dim Const $path_rel_autologon         = "\bin\Autologon.exe"
Dim Const $path_rel_rcerts            = "\win\glb\*.crt"
Dim Const $path_rel_cpp               = "\cpp\vcredist*.exe"
Dim Const $path_rel_instdotnet46      = "\dotnet\ndp462-kb3151800-x86-x64-allos-*.exe"
Dim Const $path_rel_instdotnet48      = "\dotnet\ndp48-x86-x64-allos-*.exe"
Dim Const $path_rel_msse_x86          = "\msse\x86-glb\MSEInstall-x86-*.exe"
Dim Const $path_rel_msse_x64          = "\msse\x64-glb\MSEInstall-x64-*.exe"
Dim Const $path_rel_msi_all           = "\wouallmsi.txt"
Dim Const $path_rel_msi_selected      = "\Temp\wouselmsi.txt"

Dim $maindlg, $scriptdir, $mapped, $tabitemfocused, $rcerts, $dotnet35, $dotnet4, $wmf, $cpp, $msse, $tsc, $verify, $autoreboot, $shutdown, $showlog, $btn_start, $btn_exit, $options, $builddate
Dim $dlgheight, $groupwidth, $txtwidth, $txtheight, $btnwidth, $btnheight, $txtxoffset, $txtyoffset, $txtxpos, $txtypos, $msiall, $msipacks[$msimax], $msicount, $msilistfile, $line, $gergui, $pRedirect, $dllCallResult, $i

Func ShowGUIInGerman()
  If $CmdLine[0] > 0 Then
    Switch StringLower($CmdLine[1])
      Case "enu"
        Return False
      Case "deu"
        Return True
    EndSwitch
  EndIf
  Return ( (@OSLang = "0007") OR (@OSLang = "0407") OR (@OSLang = "0807") OR (@OSLang = "0C07") OR (@OSLang = "1007") OR (@OSLang = "1407") )
EndFunc

; Returns script directory, also sets global variable $mapped
Func AssignScriptDirectory()
Dim $result, $netdrives, $i

  ; Check if script directory is a network share, map if unmapped
  $result = ""
  $mapped = False
  If DriveGetType(@ScriptDir) = "Network" Then
    If StringInStr(@ScriptDir, "\\") = 0 Then
      $result = @ScriptDir
    Else
      $netdrives = DriveGetDrive("NETWORK")
      If NOT @error Then
        For $i = 1 to $netdrives[0]
          If StringInStr(@ScriptDir, DriveMapGet($netdrives[$i])) > 0 Then
            $result = $netdrives[$i] & StringRight(@ScriptDir, StringLen(@ScriptDir) - StringLen(DriveMapGet($netdrives[$i])))
            ExitLoop
          EndIf
        Next
      EndIf
      If $result = "" Then
        $result = DriveMapAdd("*", @ScriptDir)
        If @error Then
          $result = ""
        Else
          $mapped = True
        EndIf
      EndIf
    EndIf
  Else
    $result = @ScriptDir
  EndIf
  Return $result
EndFunc

Func IsCheckBoxChecked($chkbox)
  Return BitAND(GUICtrlRead($chkbox), $GUI_CHECKED) = $GUI_CHECKED
EndFunc

Func CheckBoxStateToString($chkbox)
  If IsCheckBoxChecked($chkbox) Then
    Return $enabled
  Else
    Return $disabled
  EndIf
EndFunc

Func DefaultIniRead($section, $key, $default)
  Return IniRead($scriptdir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) & "ini", $section, $key, $default)
EndFunc

Func MyIniRead($section, $key, $default)
Dim $inifilepath, $result

  $result = DefaultIniRead($section, $key, $default)
  $inifilepath = @TempDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) & "ini"
  If FileExists($inifilepath) Then
    $result = IniRead($inifilepath, $section, $key, $result)
  EndIf
  Return $result
EndFunc

Func IniCopy()
Dim $ini_src, $ini_dest, $i

  $ini_src = $scriptdir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) & "ini"
  $ini_dest = @TempDir & "\" & StringLeft(@ScriptName, StringInStr(@ScriptName, ".", 0, -1)) & "ini"
  FileCopy($ini_src, $ini_dest, 1)
  FileSetAttrib($ini_dest, "-R")

  IniWrite($ini_dest, $ini_section_installation, $ini_value_rcerts, CheckBoxStateToString($rcerts))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_dotnet35, CheckBoxStateToString($dotnet35))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_dotnet4, CheckBoxStateToString($dotnet4))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_wmf, CheckBoxStateToString($wmf))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_cpp, CheckBoxStateToString($cpp))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_msse, CheckBoxStateToString($msse))
  IniWrite($ini_dest, $ini_section_installation, $ini_value_tsc, CheckBoxStateToString($tsc))

  IniWrite($ini_dest, $ini_section_control, $ini_value_verify, CheckBoxStateToString($verify))
  IniWrite($ini_dest, $ini_section_control, $ini_value_autoreboot, CheckBoxStateToString($autoreboot))
  IniWrite($ini_dest, $ini_section_control, $ini_value_shutdown, CheckBoxStateToString($shutdown))
  IniWrite($ini_dest, $ini_section_messaging, $ini_value_showlog, CheckBoxStateToString($showlog))

  For $i = 0 To $msicount - 1
    IniWrite($ini_dest, $ini_section_msi, GUICtrlRead($msipacks[$i], 1), CheckBoxStateToString($msipacks[$i]))
  Next

  Return 0
EndFunc

Func PathValid($path)
Dim $result, $arr_invalid, $i

  If StringLen($path) > $path_max_length Then
    $result = False
  Else
    $result = True
    $arr_invalid = StringSplit($path_invalid_chars, "")
    For $i = 1 to $arr_invalid[0]
      If StringInStr($path, $arr_invalid[$i]) > 0 Then
        $result = False
        ExitLoop
      EndIf
    Next
  EndIf
  Return $result
EndFunc

Func MediumBuildDate($basepath)
Dim $result

  $result = FileReadLine($basepath & $path_rel_builddate)
  If @error Then
    $result = ""
  EndIf
  Return $result
EndFunc

Func WSHAvailable()
Dim $reg_val

  If (@OSArch <> "X86") Then
    $reg_val = RegRead($reg_key_wsh_hklm64, $reg_val_enabled)
  Else
    $reg_val = RegRead($reg_key_wsh_hklm, $reg_val_enabled)
  EndIf
  If ($reg_val = "0") Then
    Return 0
  EndIf
  $reg_val = RegRead($reg_key_wsh_hkcu, $reg_val_enabled)
  If ($reg_val = "0") Then
    Return 0
  EndIf
  Return 1
EndFunc

Func IEVersion()
Dim $reg_val

  $reg_val = RegRead($reg_key_ie, $reg_val_version)
  If StringInStr($reg_val, "9.10.") > 0 Then
    Return "10"
  EndIf
  If StringInStr($reg_val, "9.11.") > 0 Then
    Return "11"
  EndIf
  Return StringLeft($reg_val, StringInStr($reg_val, ".") - 1)
EndFunc

Func DotNet35Version()
Dim $reg_val

  $reg_val = RegRead($reg_key_dotnet35, $reg_val_version)
  Return StringLeft($reg_val, StringInStr($reg_val, ".", 0, -1) - 1)
EndFunc

Func DotNet4Version()
  Return RegRead($reg_key_dotnet4, $reg_val_version)
EndFunc

Func DotNet4MainVersion()
  Return StringLeft(DotNet4Version(), 3)
EndFunc

Func DotNet4TargetVersion()
  If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR ( (@OSVersion = "WIN_10") AND (@OSBuild = "10240") ) ) Then
    Return "4.6.01590"
  Else
    Return "4.8.03761"
  EndIf
EndFunc

Func DotNet4DisplayVersion()
  If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR ( (@OSVersion = "WIN_10") AND (@OSBuild = "10240") ) ) Then
    Return "4.6.2"
  Else
    Return "4.8"
  EndIf
EndFunc

Func WMFMainVersion()
  Return StringLeft(RegRead($reg_key_wmf, $reg_val_pshversion), 3)
EndFunc

Func WMFTargetVersion()
  If ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_2012") _
    OR (@OSVersion = "WIN_81") OR (@OSVersion = "WIN_2012R2") OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") ) Then
    Return "5.1"
  Else
    Return "3.0"
  EndIf
EndFunc

Func MSSEInstalled()
Dim $dummy

  $dummy = RegRead($reg_key_msse, $reg_val_default)
  Return (@error <= 0)
EndFunc

Func HashFilesPresent($basepath)
  Return FileExists($basepath & $path_rel_hashes)
EndFunc

Func AutologonPresent($basepath)
  Return FileExists($basepath & $path_rel_autologon)
EndFunc

Func RootCertificatesPresent($basepath)
  Return FileExists($basepath & $path_rel_rcerts)
EndFunc

Func CPPPresent($basepath)
  Return FileExists($basepath & $path_rel_cpp)
EndFunc

Func DotNet4InstPresent($basepath)
  If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR ( (@OSVersion = "WIN_10") AND (@OSBuild = "10240") ) ) Then
    Return FileExists($basepath & $path_rel_instdotnet46)
  Else
    Return FileExists($basepath & $path_rel_instdotnet48)
  EndIf
EndFunc

Func MSSEPresent($basepath)
  Return (FileExists($basepath & $path_rel_msse_x86) OR FileExists($basepath & $path_rel_msse_x64))
EndFunc

Func ListMSIPackages()
Dim $result

  $result = RunWait(@ComSpec & " /D /C TouchMSITree.cmd /listall", $scriptdir & "\cmd", @SW_HIDE)
  If $result = 0 Then
    $result = @error
  EndIf
  Return $result
EndFunc

Func CalcGUISize()
  Dim $reg_val

  If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") _
    OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") OR (@OSVersion = "WIN_81") OR (@OSVersion = "WIN_2012R2") _
    OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") ) Then
    DllCall("user32.dll", "int", "SetProcessDPIAware")
  EndIf
  $reg_val = RegRead($reg_key_hkcu_winmetrics, $reg_val_applieddpi)
  If ($reg_val = "") Then
    $reg_val = RegRead($reg_key_hkcu_desktop, $reg_val_logpixels)
  EndIf
  If ($reg_val = "") Then
    $reg_val = $default_logpixels
  EndIf
  $dlgheight = 300 * $reg_val / $default_logpixels
  If $gergui Then
    $txtwidth = 240 * $reg_val / $default_logpixels
  Else
    $txtwidth = 220 * $reg_val / $default_logpixels
  EndIf
  $txtheight = 20 * $reg_val / $default_logpixels
  $btnwidth = 80 * $reg_val / $default_logpixels
  $btnheight = 25 * $reg_val / $default_logpixels
  $txtxoffset = 10 * $reg_val / $default_logpixels
  $txtyoffset = 10 * $reg_val / $default_logpixels
  Return 0
EndFunc

; Main Dialog
AutoItSetOption("GUICloseOnESC", 0)
AutoItSetOption("TrayAutoPause", 0)
AutoItSetOption("TrayIconHide", 1)
$gergui = ShowGUIInGerman()
CalcGUISize()
$groupwidth = 2 * $txtwidth + 2 * $txtxoffset
$maindlg = GUICreate($caption, $groupwidth + 4 * $txtxoffset, $dlgheight)
GUISetFont(8.5, 400, 0, "Sans Serif")

$scriptdir = AssignScriptDirectory()

;  Label
$txtxpos = $txtxoffset
$txtypos = $txtyoffset
If $gergui Then
  GUICtrlCreateLabel("Wählen Sie die gewünschten Optionen und klicken Sie auf 'Start'," & @LF & "um die fehlenden Microsoft-Updates auf Ihrem System zu installieren.", $txtxpos, $txtypos, 3 * $groupwidth / 4, 1.5 * $txtheight)
Else
  GUICtrlCreateLabel("Select desired options and click 'Start'" & @LF & "to install missing Microsoft updates on your computer.", $txtxpos, $txtypos, 3 * $groupwidth / 4, 1.5 * $txtheight)
EndIf

;  Medium info group
$builddate = MediumBuildDate($scriptdir)
If ($builddate <> "") Then
  $txtxpos = 3 * $txtxoffset + 3 * $groupwidth / 4
  $txtypos = 0
  If $gergui Then
    GUICtrlCreateGroup("Medium-Info", $txtxpos, $txtypos, $groupwidth / 4, 2 * $txtheight)
  Else
    GUICtrlCreateGroup("Medium info", $txtxpos, $txtypos, $groupwidth / 4, 2 * $txtheight)
  EndIf
  $txtxpos = $txtxpos + $txtxoffset
  $txtypos = $txtypos + 1.5 * $txtyoffset + 2
  GUICtrlCreateLabel("Build: " & $builddate, $txtxpos, $txtypos, $groupwidth / 4 - 2 * $txtxoffset, $txtheight)
EndIf

;  Tab control
$txtxpos = $txtxoffset
$txtypos = $txtyoffset + 1.5 * $txtheight
GuiCtrlCreateTab($txtxpos, $txtypos, $groupwidth + 2 * $txtxoffset, $dlgheight - $btnheight - 1.5 * $txtheight - 3 * $txtyoffset)

;  Updating Tab
If $gergui Then
  $tabitemfocused = GuiCtrlCreateTabItem("Aktualisierung")
Else
  $tabitemfocused = GuiCtrlCreateTabItem("Updating")
EndIf

;  Installation group
$txtxpos = 2 * $txtxoffset
$txtypos = 3.5 * $txtyoffset + 1.5 * $txtheight
GUICtrlCreateGroup("Installation", $txtxpos, $txtypos, $groupwidth, 6 * $txtheight)

; Update Root Certificates
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + 1.5 * $txtyoffset
If $gergui Then
  $rcerts = GUICtrlCreateCheckbox("Stammzertifikate aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $rcerts = GUICtrlCreateCheckbox("Update Root Certificates", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If RootCertificatesPresent($scriptdir) Then
  If MyIniRead($ini_section_installation, $ini_value_rcerts, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Install .NET Framework 3.5
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + $txtheight
If $gergui Then
  $dotnet35 = GUICtrlCreateCheckbox(".NET Framework 3.5 installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $dotnet35 = GUICtrlCreateCheckbox("Install .NET Framework 3.5", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") _
  OR (DotNet35Version() = $target_version_dotnet35) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If MyIniRead($ini_section_installation, $ini_value_dotnet35, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Install .NET Framework 4
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + $txtheight
If $gergui Then
  $dotnet4 = GUICtrlCreateCheckbox(".NET Framework " & DotNet4DisplayVersion() & " installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $dotnet4 = GUICtrlCreateCheckbox("Install .NET Framework " & DotNet4DisplayVersion(), $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (StringLeft(DotNet4Version(), 9) = DotNet4TargetVersion()) OR (NOT DotNet4InstPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If ( (DotNet4MainVersion() = "4.0") OR (DotNet4MainVersion() = "4.5") OR (DotNet4MainVersion() = "4.6") ) Then
    GUICtrlSetState(-1, $GUI_CHECKED + $GUI_DISABLE)
  Else
    If MyIniRead($ini_section_installation, $ini_value_dotnet4, $disabled) = $enabled Then
      GUICtrlSetState(-1, $GUI_CHECKED)
    Else
      GUICtrlSetState(-1, $GUI_UNCHECKED)
    EndIf
  EndIf
EndIf

; Install Windows Management Framework
$txtxpos = $txtxpos + $txtwidth
If $gergui Then
  $wmf = GUICtrlCreateCheckbox("Management Framework " & WMFTargetVersion() & " installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $wmf = GUICtrlCreateCheckbox("Install Management Framework " & WMFTargetVersion(), $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") _
  OR ( ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") ) AND (WMFMainVersion() = "3.0") ) _
  OR ( (DotNet4MainVersion() <> "4.5") AND (DotNet4MainVersion() <> "4.6") AND (DotNet4MainVersion() <> "4.7") AND (DotNet4MainVersion() <> "4.8") AND (NOT IsCheckBoxChecked($dotnet4)) ) _
  OR (WMFMainVersion() = WMFTargetVersion()) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If MyIniRead($ini_section_installation, $ini_value_wmf, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Update C++ Runtime Libraries
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + $txtheight
If $gergui Then
  $cpp = GUICtrlCreateCheckbox("C++-Laufzeitbibliotheken aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $cpp = GUICtrlCreateCheckbox("Update C++ Runtime Libraries", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If CPPPresent($scriptdir) Then
  If MyIniRead($ini_section_installation, $ini_value_cpp, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

; Install Microsoft Security Essentials
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + $txtheight
If $gergui Then
  If MSSEInstalled() Then
    $msse = GUICtrlCreateCheckbox("Microsoft Security Essentials aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $msse = GUICtrlCreateCheckbox("Microsoft Security Essentials installieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
Else
  If MSSEInstalled() Then
    $msse = GUICtrlCreateCheckbox("Update Microsoft Security Essentials", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $msse = GUICtrlCreateCheckbox("Install Microsoft Security Essentials", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
EndIf
If ( (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (@OSVersion = "WIN_81") OR (@OSVersion = "WIN_2012R2") OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") OR (NOT MSSEPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If MyIniRead($ini_section_installation, $ini_value_msse, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

; Update Windows Remote Desktop Client
$txtxpos = $txtxpos + $txtwidth
If $gergui Then
  $tsc = GUICtrlCreateCheckbox("Remote Desktop Client aktualisieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $tsc = GUICtrlCreateCheckbox("Update Remote Desktop Client", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") _
  OR (@OSVersion = "WIN_81")  OR (@OSVersion = "WIN_2012R2") OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If MyIniRead($ini_section_installation, $ini_value_tsc, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

;  Control group
$txtxpos = 2 * $txtxoffset
$txtypos = $txtypos + 2.5 * $txtyoffset
If $gergui Then
  GUICtrlCreateGroup("Steuerung", $txtxpos, $txtypos, $groupwidth, 3 * $txtheight)
Else
  GUICtrlCreateGroup("Control", $txtxpos, $txtypos, $groupwidth, 3 * $txtheight)
EndIf

; Verify
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + 1.5 * $txtyoffset
If $gergui Then
  $verify = GUICtrlCreateCheckbox("Installationspakete verifizieren", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $verify = GUICtrlCreateCheckbox("Verify installation packages", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If HashFilesPresent($scriptdir) Then
  If MyIniRead($ini_section_control, $ini_value_verify, $enabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
EndIf

;  Automatic reboot and recall
$txtxpos = $txtxpos + $txtwidth
If $gergui Then
  $autoreboot = GUICtrlCreateCheckbox("Automatisch neu starten und fortsetzen", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $autoreboot = GUICtrlCreateCheckbox("Automatic reboot and recall", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") OR (NOT AutologonPresent($scriptdir)) ) Then
  GUICtrlSetState(-1, $GUI_UNCHECKED + $GUI_DISABLE)
Else
  If MyIniRead($ini_section_control, $ini_value_autoreboot, $disabled) = $enabled Then
    GUICtrlSetState(-1, $GUI_CHECKED)
  Else
    GUICtrlSetState(-1, $GUI_UNCHECKED)
  EndIf
EndIf

;  Automatic shutdown
$txtxpos = 3 * $txtxoffset
$txtypos = $txtypos + $txtheight
If $gergui Then
  $shutdown = GUICtrlCreateCheckbox("Herunterfahren nach Abschluss", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $shutdown = GUICtrlCreateCheckbox("Shut down on completion", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If MyIniRead($ini_section_control, $ini_value_shutdown, $disabled) = $enabled Then
  GUICtrlSetState(-1, $GUI_CHECKED)
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED)
EndIf

; Show log file
$txtxpos = $txtxpos + $txtwidth
If $gergui Then
  $showlog = GUICtrlCreateCheckbox("Protokolldatei anzeigen", $txtxpos, $txtypos, $txtwidth, $txtheight)
Else
  $showlog = GUICtrlCreateCheckbox("Show log file", $txtxpos, $txtypos, $txtwidth, $txtheight)
EndIf
If ( (MyIniRead($ini_section_messaging, $ini_value_showlog, $disabled) = $enabled) _
 AND (NOT IsCheckBoxChecked($shutdown)) ) Then
  GUICtrlSetState(-1, $GUI_CHECKED)
Else
  GUICtrlSetState(-1, $GUI_UNCHECKED)
  If IsCheckBoxChecked($shutdown) Then
    GUICtrlSetState(-1, $GUI_DISABLE)
  EndIf
EndIf

;  Software Tab
$msicount = 1
ListMSIPackages()
If FileExists(@TempDir & $path_rel_msi_all) Then
  GuiCtrlCreateTabItem("Software")

  ; Select all
  $txtxpos = 2 * $txtxoffset
  $txtypos = 3.5 * $txtyoffset + 1.5 * $txtheight
  If $gergui Then
    $msiall = GUICtrlCreateCheckbox("Alle auswählen", $txtxpos, $txtypos, $txtwidth, $txtheight)
  Else
    $msiall = GUICtrlCreateCheckbox("Select all", $txtxpos, $txtypos, $txtwidth, $txtheight)
  EndIf
  ;  MSI packages' group
  $txtypos = $txtypos + $txtheight
  If $gergui Then
    GUICtrlCreateGroup("MSI-Pakete", $txtxpos, $txtypos, $groupwidth, ($msimax / 2 + 1) * $txtheight)
  Else
    GUICtrlCreateGroup("MSI packages", $txtxpos, $txtypos, $groupwidth, ($msimax / 2 + 1) * $txtheight)
  EndIf
  $txtxpos = 3 * $txtxoffset
  $txtypos = $txtypos + 1.5 * $txtyoffset
  For $msicount = 0 To $msimax - 1
    $line = FileReadLine(@TempDir & $path_rel_msi_all, $msicount + 1)
    If @error <> 0 Then ExitLoop
    $msipacks[$msicount] = GUICtrlCreateCheckbox($line, $txtxpos + Mod($msicount, 2) * $txtwidth, $txtypos + BitShift($msicount, 1) * $txtheight, $txtwidth, $txtheight)
    If MyIniRead($ini_section_msi, GUICtrlRead(-1, 1), $disabled) = $enabled Then
      GUICtrlSetState(-1, $GUI_CHECKED)
    EndIf
  Next
  FileDelete(@TempDir & $path_rel_msi_all)
  If $msicount = 0 Then $msicount = 1
EndIf

;  End Tab item definition
GuiCtrlCreateTabItem("")
GUICtrlSetState($tabitemfocused, $GUI_SHOW)

;  Start button
$txtypos = $dlgheight - $btnheight - $txtyoffset
$btn_start = GUICtrlCreateButton("Start", $txtxoffset, $txtypos, $btnwidth, $btnheight)
GUICtrlSetResizing (-1, $GUI_DOCKLEFT + $GUI_DOCKBOTTOM)

;  Exit button
If $gergui Then
  $btn_exit = GUICtrlCreateButton("Ende", $groupwidth - $btnwidth + 3 * $txtxoffset, $txtypos, $btnwidth, $btnheight)
Else
  $btn_exit = GUICtrlCreateButton("Exit", $groupwidth - $btnwidth + 3 * $txtxoffset, $txtypos, $btnwidth, $btnheight)
EndIf
GUICtrlSetResizing (-1, $GUI_DOCKRIGHT + $GUI_DOCKBOTTOM)

; GUI message loop
GUISetState()
If ( (@OSVersion = "WIN_XP") OR (@OSVersion = "WIN_2003") OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2022") OR (@OSVersion = "WIN_11") ) Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Nicht unterstütztes Betriebssystem: " & @OSVersion)
  Else
    MsgBox(0x2010, "Fehler", "Unsupported Operating System: " & @OSVersion)
  EndIf
  Exit(1)
EndIf
If NOT WSHAvailable() Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Der Windows Script Host ist deaktiviert. Bitte prüfen Sie die Registrierungswerte" _
                     & @LF & "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled und" _
                     & @LF & "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled")
  Else
    MsgBox(0x2010, "Error", "Windows Script Host is disabled on this machine. Please check registry values" _
                    & @LF & "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows Script Host\Settings\Enabled and" _
                    & @LF & "HKEY_CURRENT_USER\Software\Microsoft\Windows Script Host\Settings\Enabled")
  EndIf
  Exit(1)
EndIf
If $scriptdir = "" Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Dem Skript-Pfad " & @ScriptDir _
                     & @LF & "konnte kein Laufwerksbuchstabe zugewiesen werden.")
  Else
    MsgBox(0x2010, "Error", "Unable to assign a drive letter" _
                    & @LF & "to the script path " & @ScriptDir)
  EndIf
  Exit(1)
EndIf
If NOT PathValid($scriptdir) Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Der Skript-Pfad darf nicht mehr als " & $path_max_length & " Zeichen lang sein und" _
                     & @LF & "darf keines der folgenden Zeichen enthalten: " & $path_invalid_chars)
  Else
    MsgBox(0x2010, "Error", "The script path must not be more than " & $path_max_length & " characters long and" _
                    & @LF & "must not contain any of the following characters: " & $path_invalid_chars)
  EndIf
  Exit(1)
EndIf
If NOT PathValid(@TempDir) Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Der %TEMP%-Pfad darf nicht mehr als " & $path_max_length & " Zeichen lang sein und" _
                     & @LF & "darf keines der folgenden Zeichen enthalten: " & $path_invalid_chars)
  Else
    MsgBox(0x2010, "Error", "The %TEMP% path must not be more than " & $path_max_length & " characters long and" _
                    & @LF & "must not contain any of the following characters: " & $path_invalid_chars)
  EndIf
  Exit(1)
EndIf
If (StringRight(EnvGet("TEMP"), 1) = "\") OR (StringRight(EnvGet("TEMP"), 1) = ":") Then
  If $gergui Then
    MsgBox(0x2010, "Fehler", "Der %TEMP%-Pfad enthält einen abschließenden Backslash ('\')" _
                     & @LF & "oder einen abschließenden Doppelpunkt (':').")
  Else
    MsgBox(0x2010, "Error", "The %TEMP% path contains a trailing backslash ('\')" _
                    & @LF & "or a trailing colon (':').")
  EndIf
  Exit(1)
EndIf
If ( ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") ) _
 AND FileExists(@ProgramFilesDir & "\Internet Explorer\iexplore.exe") _
 AND ( (IEVersion() = "7") OR (IEVersion() = "8") ) _
 AND (DefaultIniRead($ini_section_installation, $ini_value_skipieinst, $disabled) = $disabled) _
 AND (DefaultIniRead($ini_section_messaging, $ini_value_showieinfo, $enabled) = $enabled) ) Then
  If $gergui Then
     MsgBox(0x2040, "Information", "Auf diesem System wird die neueste Version des Internet Explorers (IE9)" _
                           & @LF & "automatisch installiert, wenn Sie die Aktualisierung starten.")
  Else
     MsgBox(0x2040, "Information", "On this system, the most recent version of Internet Explorer (IE9)" _
                           & @LF & "will be automatically installed, when you start the updating process.")
  EndIf
EndIf
If ( ( (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") OR (@OSVersion = "WIN_2012") ) _
 AND FileExists(@ProgramFilesDir & "\Internet Explorer\iexplore.exe") _
 AND ( (IEVersion() = "8") OR (IEVersion() = "9") OR (IEVersion() = "10") ) _
 AND (DefaultIniRead($ini_section_installation, $ini_value_skipieinst, $disabled) = $disabled) _
 AND (DefaultIniRead($ini_section_messaging, $ini_value_showieinfo, $enabled) = $enabled) ) Then
  If $gergui Then
     MsgBox(0x2040, "Information", "Auf diesem System wird die neueste Version des Internet Explorers (IE11)" _
                           & @LF & "automatisch installiert, wenn Sie die Aktualisierung starten.")
  Else
     MsgBox(0x2040, "Information", "On this system, the most recent version of Internet Explorer (IE11)" _
                           & @LF & "will be automatically installed, when you start the updating process.")
  EndIf
EndIf
Local $accelKeys[2][2] = [["{enter}", $btn_start], ["{escape}", $btn_exit]]
GUISetAccelerators($accelKeys)
While 1
  Switch GUIGetMsg()
    Case $GUI_EVENT_CLOSE    ; Window closed
      If $mapped Then
        DriveMapDel($scriptdir)
      EndIf
      ExitLoop

    Case $btn_exit           ; Exit Button pressed
      If $mapped Then
        DriveMapDel($scriptdir)
      EndIf
      ExitLoop

    Case $dotnet4              ; .NET 4 check box toggled
      If ( ( (IsCheckBoxChecked($dotnet4)) OR (DotNet4MainVersion() = "4.5") OR (DotNet4MainVersion() = "4.6") OR (DotNet4MainVersion() = "4.7") OR (DotNet4MainVersion() = "4.8") ) _
       AND (@OSVersion <> "WIN_VISTA") AND (@OSVersion <> "WIN_10") AND (@OSVersion <> "WIN_2016") _
       AND ( ( (@OSVersion <> "WIN_7") AND (@OSVersion <> "WIN_2008R2") ) OR (WMFMainVersion() <> "3.0") ) _
       AND (WMFMainVersion() <> WMFTargetVersion()) ) Then
        GUICtrlSetState($wmf, $GUI_ENABLE)
      Else
        GUICtrlSetState($wmf, $GUI_UNCHECKED + $GUI_DISABLE)
      EndIf

    Case $msse                 ; Microsoft Security Essentials check box toggled
      If IsCheckBoxChecked($msse) Then
        If $gergui Then
          If MsgBox(0x2134, "Warnung", "Bei der Installation der Microsoft Security Essentials wird eine" _
                               & @LF & "obligate 'Windows Genuine Advantage' (WGA)-Prüfung durchgeführt." _
                               & @LF & "Möchten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($msse, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", "The installation of Microsoft Security Essentials performs" _
                               & @LF & "a mandatory 'Windows Genuine Advantage' (WGA) check." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($msse, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf

    Case $autoreboot         ; Automatic reboot check box toggled
      If ( (IsCheckBoxChecked($autoreboot)) _
       AND ( (@OSVersion = "WIN_VISTA") OR (@OSVersion = "WIN_2008") OR (@OSVersion = "WIN_7") OR (@OSVersion = "WIN_2008R2") _
          OR (@OSVersion = "WIN_8") OR (@OSVersion = "WIN_2012") OR (@OSVersion = "WIN_81") OR (@OSVersion = "WIN_2012R2") _
          OR (@OSVersion = "WIN_10") OR (@OSVersion = "WIN_2016") ) ) Then
        If $gergui Then
          If MsgBox(0x2134, "Warnung", "Die Option 'Automatisch neu starten und fortsetzen' deaktiviert" _
                               & @LF & "temporär die Benutzerkontensteuerung (UAC), falls erforderlich." _
                               & @LF & "Möchten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", "The option 'Automatic reboot and recall' temporarily" _
                               & @LF & "disables the User Account Control (UAC), if required." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf
      If ( (IsCheckBoxChecked($autoreboot)) AND (DriveGetType($scriptdir) = "Network") ) Then
        If $gergui Then
          If MsgBox(0x2134, "Warnung", @ScriptName & " wurde von einer Netzwerkfreigabe gestartet." _
                               & @LF & "Die Option 'Automatisch neu starten und fortsetzen'" _
                               & @LF & "funktioniert nur dann ohne Benutzereingriff," _
                               & @LF & "wenn diese Freigabe anonymen Zugriff erlaubt." _
                               & @LF & "Möchten Sie fortsetzen?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        Else
          If MsgBox(0x2134, "Warning", @ScriptName & " was started from a network share." _
                               & @LF & "The option 'Automatic reboot and recall'" _
                               & @LF & "does only work without user interaction," _
                               & @LF & "if this share permits anonymous access." _
                               & @LF & "Do you wish to proceed?") = 7 Then
            GUICtrlSetState($autoreboot, $GUI_UNCHECKED)
          EndIf
        EndIf
      EndIf

    Case $shutdown           ; Automatic shutdown check box toggled
      If IsCheckBoxChecked($shutdown) Then
        GUICtrlSetState($showlog, $GUI_UNCHECKED + $GUI_DISABLE)
      Else
        GUICtrlSetState($showlog, $GUI_ENABLE)
      EndIf

    Case $msiall             ; Select all check box toggled
      If IsCheckBoxChecked($msiall) Then
        For $i = 0 To $msicount - 1
          GUICtrlSetState($msipacks[$i], $GUI_CHECKED)
        Next
      Else
        For $i = 0 To $msicount - 1
          GUICtrlSetState($msipacks[$i], $GUI_UNCHECKED)
        Next
      EndIf

    Case $msipacks[0] To $msipacks[$msicount - 1]
      For $i = 0 To $msicount - 1
        If NOT IsCheckBoxChecked($msipacks[$i]) Then
          GUICtrlSetState($msiall, $GUI_UNCHECKED)
          ExitLoop
        EndIf
      Next

    Case $btn_start          ; Start Button pressed
      $options = MyIniRead($ini_section_misc, $ini_value_wustatusserver, "")    ; Dummy use of $options
      If $options <> "" Then
        RegWrite($reg_key_windowsupdate, $reg_val_wustatusserver, "REG_SZ", $options)
      EndIf
      $options = ""
      If IsCheckBoxChecked($rcerts) Then
        $options = $options & " /updatercerts"
      EndIf
      If IsCheckBoxChecked($dotnet35) Then
        $options = $options & " /instdotnet35"
      EndIf
      If IsCheckBoxChecked($dotnet4) Then
        $options = $options & " /instdotnet4"
      EndIf
      If IsCheckBoxChecked($wmf) Then
        $options = $options & " /instwmf"
      EndIf
      If IsCheckBoxChecked($cpp) Then
        $options = $options & " /updatecpp"
      EndIf
      If IsCheckBoxChecked($msse) Then
        $options = $options & " /instmsse"
      EndIf
      If IsCheckBoxChecked($tsc) Then
        $options = $options & " /updatetsc"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_skipieinst, $disabled) = $enabled Then
        $options = $options & " /skipieinst"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_skipdefs, $disabled) = $enabled Then
        $options = $options & " /skipdefs"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_skipdynamic, $disabled) = $enabled Then
        $options = $options & " /skipdynamic"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_all, $disabled) = $enabled Then
        $options = $options & " /all"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_excludestatics, $disabled) = $enabled Then
        $options = $options & " /excludestatics"
      EndIf
      If DefaultIniRead($ini_section_installation, $ini_value_seconly, $disabled) = $enabled Then
        $options = $options & " /seconly"
      EndIf
      If IsCheckBoxChecked($verify) Then
        $options = $options & " /verify"
      EndIf
      If ( (BitAND(GUICtrlRead($autoreboot), $GUI_DISABLE) <> $GUI_DISABLE) _
       AND (IsCheckBoxChecked($autoreboot)) ) Then
        $options = $options & " /autoreboot"
      Else
        IniCopy()
      EndIf
      If IsCheckBoxChecked($shutdown) Then
        $options = $options & " /shutdown"
      EndIf
      If IsCheckBoxChecked($showlog) Then
        $options = $options & " /showlog"
      EndIf
      If DefaultIniRead($ini_section_messaging, $ini_value_showdismprogress, $disabled) = $enabled Then
        $options = $options & " /showdismprogress"
      EndIf
      If DefaultIniRead($ini_section_misc, $ini_value_monitoron, $disabled) = $enabled Then
        $options = $options & " /monitoron"
      EndIf
      $msilistfile = FileOpen(@WindowsDir & $path_rel_msi_selected, 10)
      If $msilistfile <> -1 Then
        For $i = 0 To $msicount - 1
          If IsCheckBoxChecked($msipacks[$i]) Then
            FileWriteLine($msilistfile, GUICtrlRead($msipacks[$i], 1))
          EndIf
        Next
        FileClose($msilistfile)
      EndIf
      If FileGetSize(@WindowsDir & $path_rel_msi_selected) = 0 Then
        FileDelete(@WindowsDir & $path_rel_msi_selected)
      EndIf
      If (@OSArch <> "X86") Then
        $pRedirect = DllStructCreate("ptr")
        _WinAPI_SetLastError(0)
        $dllCallResult = DllCall("kernel32.dll", "bool", "Wow64DisableWow64FsRedirection", "ptr*", DllStructGetPtr($pRedirect))
        If (@error <> 0) OR (NOT $dllCallResult[0]) Then
          If $gergui Then
            MsgBox(0x2010, "Fehler", "Fehler #" & @error & " (Rückgabewert: " & $dllCallResult[0] _
                                   & ", API-Fehlercode: " & _WinAPI_GetLastError() & ")" _
                                   & " beim Aufruf von Wow64DisableWow64FsRedirection.")
          Else
            MsgBox(0x2010, "Error", "Error #" & @error & " (Return value: " & $dllCallResult[0] _
                                  & ", API error code: " & _WinAPI_GetLastError() & ")" _
                                  & " when calling Wow64DisableWow64FsRedirection.")
          EndIf
          ExitLoop
        EndIf
      EndIf
      If Run(@ComSpec & " /D /C Update.cmd" & $options, $scriptdir, @SW_HIDE) = 0 Then
        If $gergui Then
          MsgBox(0x2010, "Fehler", "Fehler #" & @error & " beim Aufruf von" _
                           & @LF & @ComSpec & " /D /C Update.cmd" & $options & " in" _
                           & @LF & $scriptdir & ".")
        Else
          MsgBox(0x2010, "Error", "Error #" & @error & " when calling" _
                          & @LF & @ComSpec & " /D /C Update.cmd" & $options & " in" _
                          & @LF & $scriptdir & ".")
        EndIf
      EndIf
      If (@OSArch <> "X86") Then
        _WinAPI_SetLastError(0)
        DllCall("kernel32.dll", "bool", "Wow64RevertWow64FsRedirection", "ptr", $pRedirect)
        If (@error <> 0) OR (_WinAPI_GetLastError() <> 0) Then
          If $gergui Then
            MsgBox(0x2010, "Fehler", "Fehler #" & @error & " (API-Fehlercode: " & _WinAPI_GetLastError() & ")" _
                                   & " beim Aufruf von Wow64RevertWow64FsRedirection.")
          Else
            MsgBox(0x2010, "Error", "Error #" & @error & " (API error code: " & _WinAPI_GetLastError() & ")" _
                                  & " when calling Wow64RevertWow64FsRedirection.")
          EndIf
        EndIf
        $pRedirect = 0
      EndIf
      ExitLoop
  EndSwitch
WEnd
Exit
