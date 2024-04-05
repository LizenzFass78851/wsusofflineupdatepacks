' *** Author: aker@wsusoffline ***

Option Explicit

Dim strVersion1, strVersion2, arrayVersion1, arrayVersion2, intMaxIndex
Dim i

If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <version 1> <version 2>")
  WScript.Echo("       errorlevel 0: versions are equal")
  WScript.Echo("       errorlevel 1: parser error")
  WScript.Echo("       errorlevel 2: version 1 > version 2")
  WScript.Echo("       errorlevel 3: version 1 < version 2")
  WScript.Quit(1)
End If

strVersion1 = WScript.Arguments(0)
strVersion2 = WScript.Arguments(1)

If strVersion1 = "" Then
  WScript.Echo("ERROR: Invalid first argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <version 1> <version 2>")
  WScript.Quit(1)
End If
If strVersion2 = "" Then
  WScript.Echo("ERROR: Invalid second argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <version 1> <version 2>")
  WScript.Quit(1)
End If

arrayVersion1 = Split(strVersion1, ".")
arrayVersion2 = Split(strVersion2, ".")

For i = 0 To UBound(arrayVersion1)
  If IsNumeric(arrayVersion1(i)) = False Then
    WScript.Echo("ERROR: Invalid first argument.")
    WScript.Echo("Usage: " & WScript.ScriptName & " <version 1> <version 2>")
    WScript.Quit(1)
  End If
Next

For i = 0 To UBound(arrayVersion2)
  If IsNumeric(arrayVersion2(i)) = False Then
    WScript.Echo("ERROR: Invalid second argument.")
    WScript.Echo("Usage: " & WScript.ScriptName & " <version 1> <version 2>")
    WScript.Quit(1)
  End If
Next

If UBound(arrayVersion2) > UBound(arrayVersion1) Then
  intMaxIndex = UBound(arrayVersion1)
Else
  intMaxIndex = UBound(arrayVersion2)
End If

For i = 0 To intMaxIndex
  If CInt(arrayVersion1(i)) > CInt(arrayVersion2(i)) Then
    WScript.Quit(2)
  ElseIf CInt(arrayVersion1(i)) < CInt(arrayVersion2(i)) Then
    WScript.Quit(3)
  End If
Next


If UBound(arrayVersion1) > intMaxIndex Then
  For i = intMaxIndex To UBound(arrayVersion1)
    If CInt(arrayVersion1(i)) > 0 Then
      WScript.Quit(2)
    End If
  Next
ElseIf UBound(arrayVersion2) > intMaxIndex Then
  For i = intMaxIndex To UBound(arrayVersion2)
    If CInt(arrayVersion2(i)) > 0 Then
      WScript.Quit(3)
    End If
  Next
End If

WScript.Quit(0)
