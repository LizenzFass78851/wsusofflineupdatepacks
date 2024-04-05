' *** Author: T. Wittrock, Kiel ***

Option Explicit

Dim objFileSystem, inputFile, outputFile, strInputFileName, strOutputFileName, strBuffer, bFirstOnly, bSecondOnly, bNoIds

Private Function IsTextFile(objFS, strFileName)
  IsTextFile = (objFS.FileExists(strFileName)) And ( (LCase(objFS.GetExtensionName(strFileName)) = "txt") Or (LCase(objFS.GetExtensionName(strFileName)) = "csv") )
End Function

Private Function ExtractFirstId(strLine)
  On Error Resume Next
  ExtractFirstId = Left(strLine, InStr(strLine, ",") - 1)
End Function

Private Function ExtractSecondId(strLine)
  On Error Resume Next
  ExtractSecondId = Mid(strLine, InStr(strLine, ",") + 1, InStr(strLine, ";") - InStr(strLine, ",") - 1)
End Function

Private Function ExtractFileName(strLine)
  On Error Resume Next
  ExtractFileName = Right(strLine, Len(strLine) - InStrRev(strLine, "/"))
End Function

Private Function ExtractFirstIdAndFileName(strLine)
  ExtractFirstIdAndFileName = ExtractFirstId(strLine) & "," & ExtractFileName(strLine)
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
If WScript.Arguments.Count > 2 Then
  bFirstOnly = LCase(WScript.Arguments(2)) = "/firstonly"
  bSecondOnly = LCase(WScript.Arguments(2)) = "/secondonly"
  bNoIds = LCase(WScript.Arguments(2)) = "/noids"
Else
  bFirstOnly = False
  bSecondOnly = False
  bNoIds = False
End If

Set inputFile = objFileSystem.OpenTextFile(strInputFileName, 1)
Set outputFile = objFileSystem.CreateTextFile(strOutputFileName, True)
Do While Not inputFile.AtEndOfStream
  If bFirstOnly Then
    outputFile.WriteLine(ExtractFirstId(inputFile.ReadLine()))
  Else
    If bSecondOnly Then
      strBuffer = ExtractSecondId(inputFile.ReadLine())
      If strBuffer <> "" Then
        outputFile.WriteLine(strBuffer)
      End If
    Else
      If bNoIds Then
        outputFile.WriteLine(ExtractFileName(inputFile.ReadLine()))
      Else
        outputFile.WriteLine(ExtractFirstIdAndFileName(inputFile.ReadLine()))
      End If
    End If
  End If
Loop
inputFile.Close()
outputFile.Close()
WScript.Quit(0)
