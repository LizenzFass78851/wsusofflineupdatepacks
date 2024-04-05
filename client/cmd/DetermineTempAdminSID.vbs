' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strWOUTempAdminName = "WOUTempAdmin"

Dim wshShell, objFileSystem, objCmdFile, objNetwork, objWMIService, objQueryItem 
Dim strTempFolder, strCmdFileName

Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strCmdFileName = strTempFolder & "\SetTempAdminSID.cmd"

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objCmdFile = objFileSystem.CreateTextFile(strCmdFileName, True)

Set objNetwork = WScript.CreateObject("WScript.Network")
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
' Documentation: http://msdn.microsoft.com/en-us/library/aa394507(VS.85).aspx
For Each objQueryItem in objWMIService.ExecQuery("Select * from Win32_UserAccount Where Domain = '" & objNetwork.ComputerName & "' And Name = '" & strWOUTempAdminName & "'")
  objCmdFile.WriteLine("set TempAdminSID=" & objQueryItem.SID)
Next

objCmdFile.Close
WScript.Quit(0)
