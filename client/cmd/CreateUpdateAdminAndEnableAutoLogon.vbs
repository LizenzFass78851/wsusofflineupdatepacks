' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strWOUTempAdminName   = "WOUTempAdmin"
Private Const strKeySystemPolicies  = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\"
Private Const strValAdminPrompt     = "ConsentPromptBehaviorAdmin"
Private Const strValEnableLUA       = "EnableLUA"
Private Const strKeyAutologon30     = "HKCU\Software\Sysinternals\A\"
Private Const strKeyAutologon31     = "HKCU\Software\Sysinternals\Autologon\"
Private Const strValAcceptEula      = "EulaAccepted"

Dim wshShell, strComputerName, objComputer, objUser, found

Private Function CreateUpdateAdmin(objComp)
Dim objWMIService, objWOUTempAdmin, objGroup, objItem, strResult

  On Error Resume Next
  Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
  Set objWOUTempAdmin = objComp.Create("user", strWOUTempAdminName)
  Randomize
  strResult = "!Wou_" & Int(90000 * Rnd) + 10000
  objWOUTempAdmin.SetPassword strResult
  objWOUTempAdmin.SetInfo
  For Each objItem in objWMIService.ExecQuery("Select * from Win32_Group Where SID = 'S-1-5-32-544'")
    objComp.Filter = Array("group")
    For Each objGroup In objComp
      If objGroup.Name = objItem.Name Then
        objGroup.Add(objWOUTempAdmin.ADsPath)
      End If
    Next
  Next
  ' Clear objects memory
  Set objWOUTempAdmin = Nothing
  Set objWMIService = Nothing
  CreateUpdateAdmin = strResult
End Function

Private Sub EnableAutoLogonAndDisableUAC(shell, strUserName, strDomain, strPassword)
  On Error Resume Next
  shell.RegWrite strKeyAutologon30 & strValAcceptEula, 1, "REG_DWORD"
  shell.RegWrite strKeyAutologon31 & strValAcceptEula, 1, "REG_DWORD"
  shell.Run shell.ExpandEnvironmentStrings("%SystemRoot%") & "\Temp\WOURecall\Autologon.exe " & strUserName & " " & strDomain & " " & strPassword, 0, True
  shell.RegWrite strKeySystemPolicies & strValAdminPrompt, 0, "REG_DWORD"
  shell.RegWrite strKeySystemPolicies & strValEnableLUA, 0, "REG_DWORD"
End Sub

Set wshShell = WScript.CreateObject("WScript.Shell")
strComputerName = WScript.CreateObject("WScript.Network").ComputerName
Set objComputer = GetObject("WinNT://" & strComputerName)

objComputer.Filter = Array("user")
found = false
For Each objUser In objComputer
  If LCase(objUser.Name) = LCase(strWOUTempAdminName) Then
    found = true
    Exit For
  End If
Next
If found Then
  WScript.Echo("ERROR: User account '" & strWOUTempAdminName & "' already exists.")
  WScript.Quit(1)
End If
EnableAutoLogonAndDisableUAC wshShell, strWOUTempAdminName, strComputerName, CreateUpdateAdmin(objComputer)
WScript.Quit(0)
