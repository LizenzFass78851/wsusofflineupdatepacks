' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const HKEY_LOCAL_MACHINE      = &H80000002
Private Const strRegKeyUninstall      = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
Private Const strRegKeyUninstallWow64 = "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
Private Const strRegValDisplayName    = "DisplayName"

Private Const strIdStartToken         = "("
Private Const strIdKBToken            = "KB"
Private Const strIdEndToken           = ")"

Dim wshShell, objFileSystem, objWMIService, objQuickFix, objIDFile, arraySubKeys
Dim strTempFolder, strIdFileName, strId, strSubKey, posStartToken, posEndToken

On Error Resume Next
Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strIdFileName = strTempFolder & "\InstalledUpdateIds.txt"
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objIDFile = objFileSystem.CreateTextFile(strIdFileName, True)

' List OS patches
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
For Each objQuickFix in objWMIService.ExecQuery("Select * from Win32_QuickFixEngineering")
  posStartToken = InStr(1, objQuickFix.HotFixID, strIdKBToken, vbTextCompare)
  If posStartToken > 0 Then
    objIDFile.WriteLine(Right(objQuickFix.HotFixID, Len(objQuickFix.HotFixID) - (posStartToken + Len(strIdKBToken) - 1)))
  Else
    objIDFile.WriteLine(objQuickFix.HotFixID)
  End If
Next

' List other patches
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
objWMIService.EnumKey HKEY_LOCAL_MACHINE, strRegKeyUninstall, arraySubKeys
For Each strSubKey In arraySubKeys
	objWMIService.GetStringValue HKEY_LOCAL_MACHINE, strRegKeyUninstall & "\" & strSubKey, strRegValDisplayName, strId
  If IsNull(strId) Or (strId = "") Then
    strId = strSubKey
  End If
  posStartToken = InStr(1, strId, strIdStartToken & strIdKBToken, vbTextCompare)
  If posStartToken > 0 Then
    posEndToken = InStr(posStartToken, strId, strIdEndToken, vbTextCompare)
    If posEndToken > 0 Then
      objIDFile.WriteLine(Mid(strId, posStartToken + Len(strIdStartToken & strIdKBToken), posEndToken - (posStartToken + Len(strIdStartToken & strIdKBToken))))
    End If
  End If
Next

' List other patches from Wow6432Node
objWMIService.EnumKey HKEY_LOCAL_MACHINE, strRegKeyUninstallWow64, arraySubKeys
For Each strSubKey In arraySubKeys
	objWMIService.GetStringValue HKEY_LOCAL_MACHINE, strRegKeyUninstallWow64 & "\" & strSubKey, strRegValDisplayName, strId
  If IsNull(strId) Or (strId = "") Then
    strId = strSubKey
  End If
  posStartToken = InStr(1, strId, strIdStartToken & strIdKBToken, vbTextCompare)
  If posStartToken > 0 Then
    posEndToken = InStr(posStartToken, strId, strIdEndToken, vbTextCompare)
    If posEndToken > 0 Then
      objIDFile.WriteLine(Mid(strId, posStartToken + Len(strIdStartToken & strIdKBToken), posEndToken - (posStartToken + Len(strIdStartToken & strIdKBToken))))
    End If
  End If
Next

objIDFile.Close
' Delete id file if it does not contain valid data
Set objIDFile = objFileSystem.GetFile(strIdFileName)
If objIDFile.Size <= 2 Then
  objIDFile.Delete
End If
WScript.Quit(0)
