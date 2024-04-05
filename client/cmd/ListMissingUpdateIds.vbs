' *** Author: T. Wittrock, Kiel ***

Option Explicit

Private Const strLogFileName  = "wsusofflineupdate.log"
Private Const strHideFileName = "HideList-seconly.txt"

Dim wshShell, objUpdateService, objUpdateSearcher, objSearchResult, objUpdate, objIDFile
Dim strTempFolder, strTextFileName, strArgument, strKBId

Private Sub LogInfo(objShell, strLine)
Dim objLogFile

  On Error Resume Next
  Set objLogFile = CreateObject("Scripting.FileSystemObject").OpenTextFile(objShell.ExpandEnvironmentStrings("%SystemRoot%") & "\" & strLogFileName, 8, True)
  objLogFile.WriteLine(Date & " " & Time & ",00 - Info: " & strLine)
  objLogFile.Close
End Sub

Private Function UpdateShouldBeHidden(objShell, strKBNumber)
Dim objExec

  On Error Resume Next
  If strKBNumber = "" Then
    UpdateShouldBeHidden = False
    Exit Function
  End If
  Set objExec = objShell.Exec(objShell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\find.exe /I """ & strKBNumber & """ ..\exclude\" & strHideFileName & " >nul 2>&1")
  Do While objExec.Status = 0
    WScript.Sleep 10
  Loop
  If objExec.ExitCode = 0 Then
    UpdateShouldBeHidden = True
    Exit Function
  End If
  If CreateObject("Scripting.FileSystemObject").FileExists("..\exclude\custom\" & strHideFileName) Then
    Set objExec = objShell.Exec(objShell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\find.exe /I """ & strKBNumber & """ ..\exclude\custom\" & strHideFileName & " >nul 2>&1")
    Do While objExec.Status = 0
      WScript.Sleep 10
    Loop
    If objExec.ExitCode = 0 Then
      UpdateShouldBeHidden = True
      Exit Function
    End If
  End If
  UpdateShouldBeHidden = False
End Function

Set wshShell = WScript.CreateObject("WScript.Shell")
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strTextFileName = strTempFolder & "\MissingUpdateIds.txt"
If WScript.Arguments.Count = 0 Then
  strArgument = ""
Else
  strArgument = WScript.Arguments(0)
End If

Set objUpdateService = CreateObject("Microsoft.Update.ServiceManager").AddScanPackageService("Offline Sync Service", strTempFolder & "\wsusscn2.cab")
Set objUpdateSearcher = CreateObject("Microsoft.Update.Session").CreateUpdateSearcher()
objUpdateSearcher.ServerSelection = 3 ' ssOthers
objUpdateSearcher.ServiceID = objUpdateService.ServiceID
If LCase(strArgument) = "/all" Then
  Set objSearchResult = objUpdateSearcher.Search("Type='Software'")
Else
  Set objSearchResult = objUpdateSearcher.Search("Type='Software' and IsInstalled=0 and IsHidden=0")
End If

On Error Resume Next
If objSearchResult.Updates.Count > 0 Then
  Set objIDFile = CreateObject("Scripting.FileSystemObject").CreateTextFile(strTextFileName, True)
  For Each objUpdate In objSearchResult.Updates
    If objUpdate.KBArticleIDs.Count > 0 Then
      strKBId = objUpdate.KBArticleIDs.Item(0)
    Else
      strKBId = ""
    End If
    If (LCase(strArgument) = "/seconly") And UpdateShouldBeHidden(wshShell, strKBId) Then
      If objUpdate.IsMandatory Then
        LogInfo wshShell, "Unable to hide mandatory update kb" & strKBId
      Else
        WScript.Echo "Hiding update kb" & strKBId & "..."
        objUpdate.IsHidden = True
        LogInfo wshShell, "Hid update kb" & strKBId
      End If
    Else
      If (LCase(strArgument) = "/all") And UpdateShouldBeHidden(wshShell, strKBId) Then
        WScript.Echo "Revealing update kb" & strKBId & "..."
        objUpdate.IsHidden = False
        LogInfo wshShell, "Revealed update kb" & strKBId
      End If
      objIDFile.WriteLine(strKBId & "," & objUpdate.Identity.UpdateID)
    End If
  Next
  objIDFile.Close
End If
WScript.Quit(0)
