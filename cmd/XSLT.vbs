' *** Author: T. Wittrock, Kiel ***

Option Explicit

Dim objFileSystem, objXML, objXSL, objOutFile, strXMLFileName, strXSLFileName, strOutFileName, strResult

Private Function IsXMLFile(objFS, strFileName)
  IsXMLFile = (objFS.FileExists(strFileName)) And ( (LCase(objFS.GetExtensionName(strFileName)) = "xml") Or (LCase(objFS.GetExtensionName(strFileName)) = "xsl") )
End Function

Set objFileSystem = CreateObject("Scripting.FileSystemObject")
If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <XML file> <XSL file> [Output file]")
  WScript.Quit(1)
End If
strXMLFileName = WScript.Arguments(0)
If Not IsXMLFile(objFileSystem, strXMLFileName) Then
  WScript.Echo("ERROR: Invalid argument '" & strXMLFileName & "'")
  WScript.Echo("Usage: " & WScript.ScriptName & " <XML file> <XSL file> [Output file]")
  WScript.Quit(1)
End If
strXSLFileName = WScript.Arguments(1)
If Not IsXMLFile(objFileSystem, strXSLFileName) Then
  WScript.Echo("ERROR: Invalid argument '" & strXSLFileName & "'")
  WScript.Echo("Usage: " & WScript.ScriptName & " <XML file> <XSL file> [Output file]")
  WScript.Quit(1)
End If
If WScript.Arguments.Count = 3 Then
  strOutFileName = WScript.Arguments(2)
Else
  strOutFileName = ""
End If
On Error Resume Next
Set objXML = CreateObject("MSXML2.DOMDocument.6.0")
If Err.Number = 0 Then
  Set objXSL = CreateObject("MSXML2.DOMDocument.6.0")
  WScript.Echo("XSLT uses MSXML 6.0")
Else
  Set objXML = CreateObject("MSXML.DOMDocument")
  Set objXSL = CreateObject("MSXML.DOMDocument")
  WScript.Echo("XSLT uses MSXML 3.0")
End If
On Error GoTo 0
objXML.async = False
objXML.validateOnParse = False
objXML.load strXMLFileName
If Err.Number <> 0 Then
  WScript.Echo("ERROR: Unable to load XML file '" & strXMLFileName & "'")
  WScript.Quit(1)
End If
objXSL.async = False
objXSL.validateOnParse = False
objXSL.load strXSLFileName
If Err.Number <> 0 Then
  WScript.Echo("ERROR: Unable to load XSL file '" & strXSLFileName & "'")
  WScript.Quit(1)
End If
strResult = objXML.transformNode(objXSL)
If Err.Number <> 0 Then
  WScript.Echo("ERROR: Unable to transform XML file '" & strXMLFileName & "' using XSL file '" & strXSLFileName & "'")
  WScript.Quit(1)
End If
If strOutFileName = "" Then
  WScript.Echo(strResult)
Else
  Set objOutFile = objFileSystem.CreateTextFile(strOutFileName, True)
  objOutFile.Write(strResult)
  objOutFile.Close()
End If
WScript.Quit(0)
