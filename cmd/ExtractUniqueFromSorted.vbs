' *** Author: T. Wittrock, Kiel ***

Option Explicit

Dim objFileSystem, inputFile, outputFile, strInputFileName, strOutputFileName, strLastLine, strCurrentLine

Private Function IsTextFile(objFS, strFileName)
  IsTextFile = (objFS.FileExists(strFileName)) And ( (LCase(objFS.GetExtensionName(strFileName)) = "txt") Or (LCase(objFS.GetExtensionName(strFileName)) = "csv") )
End Function

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <Input file> <Output file>")
  WScript.Quit(1)
End If
strInputFileName = WScript.Arguments(0)
If Not IsTextFile(objFileSystem, strInputFileName) Then
  WScript.Echo("ERROR: Invalid argument '" & strInputFileName & "'")
  WScript.Echo("Usage: " & WScript.ScriptName & " <Input file> <Output file>")
  WScript.Quit(1)
End If
strOutputFileName = WScript.Arguments(1)

Set inputFile = objFileSystem.OpenTextFile(strInputFileName, 1)
Set outputFile = objFileSystem.CreateTextFile(strOutputFileName, True)
strLastLine = ""
Do While Not inputFile.AtEndOfStream
  strCurrentLine = inputFile.ReadLine()
  If strCurrentLine <> strLastLine Then
    outputFile.WriteLine(strCurrentLine)
  End If
  strLastLine = strCurrentLine
Loop
inputFile.Close()
outputFile.Close()
WScript.Quit(0)
