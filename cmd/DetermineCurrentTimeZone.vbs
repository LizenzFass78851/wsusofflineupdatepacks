' *** Author: aker ***

Option Explicit

Dim objWMIService, objQueryItem
Dim wshShell, strTempFolder, objFileSystem, objOutFile
Dim intTZ, intTZHour, intTZMinute, boolNegativeBias, strTZHour, strTZMinute

Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
For Each objQueryItem in objWMIService.ExecQuery("Select CurrentTimeZone from Win32_OperatingSystem")
  intTZ = objQueryItem.CurrentTimeZone
Next

If intTZ < 0 Then
  boolNegativeBias = False
  intTZ = intTZ * (-1)
Else
  boolNegativeBias = True
End If

intTZHour = intTZ \ 60
If (intTZHour * 60) > intTZ Then
  intTZHour = intTZHour - 1
End If
intTZMinute = intTZ Mod 60

strTZHour = CStr(intTZHour)
If intTZMinute < 10 Then
  strTZMinute = "0" + CStr(intTZMinute)
Else
  strTZMinute = CStr(intTZMinute)
End If

Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objOutFile = objFileSystem.CreateTextFile(strTempFolder + "\SetTZVariable.cmd", True)

If boolNegativeBias = True Then
  objOutFile.Write("set TZ=LOC-" + strTZHour + ":" + strTZMinute)
Else
  objOutFile.Write("set TZ=LOC" + strTZHour + ":" + strTZMinute)
End If

objOutFile.Close()

WScript.Quit(0)
