' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strWSUSRootFolder = "Content/"

Dim objFileSystem, inputFile, outputFile, strInputFileName, strWSUSURL, strLine

Private Function IsTextFile(objFS, strFileName)
  IsTextFile = (objFS.FileExists(strFileName)) And (LCase(objFS.GetExtensionName(strFileName)) = "txt")
End Function

Private Function TableFileName(objFS, strFileName)
  TableFileName = objFS.GetParentFolderName(objFS.GetAbsolutePathName(strFileName)) & "\" & objFS.GetBaseName(strFileName) & ".csv"
End Function

Private Function WSUSFileURL(objFS, strURL, strWSUS)
Dim strBase, strChecksum, posUnderline

  WSUSFileURL = ""
  strBase = objFS.GetBaseName(strURL)
  posUnderline = InStrRev(strBase, "_")
  If posUnderline > 0 Then
    strChecksum = Right(strBase, Len(strBase) - posUnderline)
    If Len(strChecksum) >= 31 Then
      WSUSFileURL = strWSUS & UCase(Right(strChecksum, 2)) & "/" & UCase(strChecksum) & "." & objFS.GetExtensionName(strURL)
    End If
  End If
End Function

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <Text file> <WSUS URL>")
  WScript.Quit(1)
End If
strInputFileName = WScript.Arguments(0)
If Not IsTextFile(objFileSystem, strInputFileName) Then
  WScript.Echo("ERROR: Invalid argument '" & strInputFileName & "'")
  WScript.Echo("Usage: " & WScript.ScriptName & " <Text file> <WSUS URL>")
  WScript.Quit(1)
End If
If Right(WScript.Arguments(1), 1) = "/" Then
  strWSUSURL = WScript.Arguments(1) & strWSUSRootFolder
Else
  strWSUSURL = WScript.Arguments(1) & "/" & strWSUSRootFolder
End If

Set inputFile = objFileSystem.OpenTextFile(strInputFileName, 1)
Set outputFile = objFileSystem.CreateTextFile(TableFileName(objFileSystem, strInputFileName), True)
Do While Not inputFile.AtEndOfStream
  strLine = inputFile.ReadLine()
  outputFile.WriteLine(objFileSystem.GetFileName(strLine) & "," & WSUSFileURL(objFileSystem, strLine, strWSUSURL) & "," & strLine)
Loop
inputFile.Close()
outputFile.Close()
WScript.Quit(0)
