' *** Author: T. Wittrock, Kiel ***

Option Explicit

Dim objWMIService, objQueryItem

If WScript.Arguments.Count < 1 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <service name>")
  WScript.Quit(1)
End If

Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
' Documentation: https://msdn.microsoft.com/en-us/library/aa394418(v=vs.85).aspx
For Each objQueryItem in objWMIService.ExecQuery("Select State from Win32_Service Where Name = '" & WScript.Arguments(0) & "'")
  WScript.Echo objQueryItem.State
Next
WScript.Quit(0)
