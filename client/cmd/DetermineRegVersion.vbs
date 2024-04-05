' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strVersionSuffixes  = "MAJOR,MINOR,BUILD,REVIS"

Dim wshShell, objFileSystem, objCmdFile
Dim strRegVal, strPrefix, strTempFolder, strCmdFileName

Private Function RegRead(objShell, strName)
  On Error Resume Next
  RegRead = objShell.RegRead(strName)
  If Err <> 0 Then
    RegRead = ""
    Err.Clear
  End If
End Function

Private Sub WriteVersionToFile(cmdFile, prefix, strVersion)
Dim arraySuffixes, arrayVersion, i

  arraySuffixes = Split(strVersionSuffixes, ",")
  If Len(strVersion) > 0 Then
    i = InStrRev(strVersion, " ")
    If i > 0 Then
      arrayVersion = Split(Left(strVersion, i - 1), ".")
    Else
      arrayVersion = Split(strVersion, ".")
    End If
  Else
    arrayVersion = Split("0", ".")
  End If
  For i = 0 To UBound(arraySuffixes)
    If i > UBound(arrayVersion) Then
      cmdFile.WriteLine("set " & prefix & "_" & arraySuffixes(i) & "=0")
    Else
      cmdFile.WriteLine("set " & prefix & "_" & arraySuffixes(i) & "=" & arrayVersion(i))
    End If
  Next
End Sub

If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <registry key> <variable prefix>")
  WScript.Quit(1)
End If

Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strCmdFileName = strTempFolder & "\SetRegVersion.cmd"
strRegVal = WScript.Arguments(0)
strPrefix = WScript.Arguments(1)

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objCmdFile = objFileSystem.CreateTextFile(strCmdFileName, True)

WriteVersionToFile objCmdFile, strPrefix, RegRead(wshShell, strRegVal)

objCmdFile.Close
WScript.Quit(0)
