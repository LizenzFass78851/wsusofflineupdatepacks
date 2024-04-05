' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strVersionSuffixes  = "MAJOR,MINOR,BUILD,REVIS"

Dim wshShell, objFileSystem, objCmdFile
Dim strFileName, strPrefix, strTempFolder, strCmdFileName

Private Sub WriteVersionToFile(cmdFile, prefix, strVersion)
Dim arraySuffixes, arrayVersion, i

  arraySuffixes = Split(strVersionSuffixes, ",")
  If Len(strVersion) > 0 Then
    arrayVersion = Split(strVersion, ".")
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
  WScript.Echo("Usage: " & WScript.ScriptName & " <file name> <variable prefix>")
  WScript.Quit(1)
End If

Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strCmdFileName = strTempFolder & "\SetFileVersion.cmd"
strFileName = WScript.Arguments(0)
strPrefix = WScript.Arguments(1)

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objCmdFile = objFileSystem.CreateTextFile(strCmdFileName, True)

WriteVersionToFile objCmdFile, strPrefix, objFileSystem.GetFileVersion(strFileName)

objCmdFile.Close
WScript.Quit(0)
