' ***     Author: aker      ***

Option Explicit

Dim strURL, arrURL, strFileName

If WScript.Arguments.Count = 0 Then
  WScript.Quit(1)
End If
strURL = WScript.Arguments(0)
If strURL = "" Then
  WScript.Quit(1)
End If
On Error Resume Next
arrURL = Split(strURL, "/")
strFileName = Split(arrURL(UBound(arrURL)), "?")(0)
On Error GoTo 0
WScript.Echo(strFileName)
WScript.Quit(0)
