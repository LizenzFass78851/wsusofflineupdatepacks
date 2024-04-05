' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strWOUTempAdminName = "WOUTempAdmin"

Dim objNetwork, objComputer, objUser, found

Set objNetwork = WScript.CreateObject("WScript.Network")
Set objComputer = GetObject("WinNT://" & objNetwork.ComputerName)

objComputer.Filter = Array("user")
found = false
For Each objUser In objComputer
  If LCase(objUser.Name) = LCase(strWOUTempAdminName) Then
    found = true
    Exit For
  End If
Next
If found Then
  objComputer.Delete "user", strWOUTempAdminName
  WScript.Quit(0)
Else
  WScript.Echo("ERROR: User account '" & strWOUTempAdminName & "' not found.")
  WScript.Quit(1)
End If
