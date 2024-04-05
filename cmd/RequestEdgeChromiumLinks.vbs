' ***     Author: aker      ***

Dim strFileName, strURL, strSizeInBytes, strHashesSha1Base64, strHashesSha256Base64
Dim strFileNameX86, strURLX86, strSizeInBytesX86, strHashesSha1Base64X86, strHashesSha256Base64X86, strHashesSha1HexX86, strHashesSha256HexX86
Dim strFileNameX64, strURLX64, strSizeInBytesX64, strHashesSha1Base64X64, strHashesSha256Base64X64, strHashesSha1HexX64, strHashesSha256HexX64
'Dim strFileNameARM64, strURLARM64, strSizeInBytesARM64, strHashesSha1Base64ARM64, strHashesSha256Base64ARM64, strHashesSha1HexARM64, strHashesSha256HexARM64
Dim strFileNameUpdater, strURLUpdater, strSizeInBytesUpdater, strHashesSha1Base64Updater, strHashesSha256Base64Updater, strHashesSha1HexUpdater, strHashesSha256HexUpdater
Dim fso, fDynamicDownloadLinks, fHashes
Dim strPathDynamicDownloadLinks, strPathHashes


If WScript.Arguments.Count < 2 Then
  WScript.Echo("ERROR: Missing argument.")
  WScript.Echo("Usage: " & WScript.ScriptName & " <path to DynamicDownloadLinks-msedge.txt> <path to hashes-msedge.txt>")
  WScript.Quit(1)
End If

strPathDynamicDownloadLinks = WScript.Arguments(0)
strPathHashes = WScript.Arguments(1)

' --- STEP A: get URLs and date from MS ---

GetLatestEdgeDL "Default", "msedge-stable-win-x86"
strFileNameX86 = strFileName
strURLX86 = strURL
strSizeInBytesX86 = strSizeInBytes
strHashesSha1Base64X86 = strHashesSha1Base64
strHashesSha256Base64X86 = strHashesSha256Base64

If strFileNameX86 = "" Then
  WScript.Quit(1)
End If
If strURLX86 = "" Then
  WScript.Quit(1)
End If
If strSizeInBytesX86 = "" Then
  WScript.Quit(1)
End If
If strHashesSha1Base64X86 = "" Then
  WScript.Quit(1)
End If
If strHashesSha256Base64X86 = "" Then
  WScript.Quit(1)
End If

GetLatestEdgeDL "Default", "msedge-stable-win-x64"
strFileNameX64 = strFileName
strURLX64 = strURL
strSizeInBytesX64 = strSizeInBytes
strHashesSha1Base64X64 = strHashesSha1Base64
strHashesSha256Base64X64 = strHashesSha256Base64

If strFileNameX64 = "" Then
  WScript.Quit(1)
End If
If strURLX64 = "" Then
  WScript.Quit(1)
End If
If strSizeInBytesX64 = "" Then
  WScript.Quit(1)
End If
If strHashesSha1Base64X64 = "" Then
  WScript.Quit(1)
End If
If strHashesSha256Base64X64 = "" Then
  WScript.Quit(1)
End If

'GetLatestEdgeDL "Default", "msedge-stable-win-arm64"
'strFileNameARM64 = strFileName
'strURLARM64 = strURL
'strSizeInBytesARM64 = strSizeInBytes
'strHashesSha1Base64ARM64 = strHashesSha1Base64
'strHashesSha256Base64ARM64 = strHashesSha256Base64

'If strFileNameARM64 = "" Then
'  WScript.Quit(1)
'End If
'If strURLARM64 = "" Then
'  WScript.Quit(1)
'End If
'If strSizeInBytesARM64 = "" Then
'  WScript.Quit(1)
'End If
'If strHashesSha1Base64ARM64 = "" Then
'  WScript.Quit(1)
'End If
'If strHashesSha256Base64ARM64 = "" Then
'  WScript.Quit(1)
'End If

GetLatestEdgeDL "Default", "msedgeupdate-stable-win-x86"
strFileNameUpdater = strFileName
strURLUpdater = strURL
strSizeInBytesUpdater = strSizeInBytes
strHashesSha1Base64Updater = strHashesSha1Base64
strHashesSha256Base64Updater = strHashesSha256Base64

If strFileNameUpdater = "" Then
  WScript.Quit(1)
End If
If strURLUpdater = "" Then
  WScript.Quit(1)
End If
If strSizeInBytesUpdater = "" Then
  WScript.Quit(1)
End If
If strHashesSha1Base64Updater = "" Then
  WScript.Quit(1)
End If
If strHashesSha256Base64Updater = "" Then
  WScript.Quit(1)
End If

' --- STEP B: parse/convert hashes ---

If ValidateBase64(strHashesSha1Base64X86) = True Then
  strHashesSha1HexX86 = LCase(Base64ToHex(strHashesSha1Base64X86))
Else
  WScript.Quit(1)
End If
If ValidateBase64(strHashesSha256Base64X86) = True Then
  strHashesSha256HexX86 = LCase(Base64ToHex(strHashesSha256Base64X86))
Else
  WScript.Quit(1)
End If

If ValidateBase64(strHashesSha1Base64X64) = True Then
  strHashesSha1HexX64 = LCase(Base64ToHex(strHashesSha1Base64X64))
Else
  WScript.Quit(1)
End If
If ValidateBase64(strHashesSha256Base64X64) = True Then
  strHashesSha256HexX64 = LCase(Base64ToHex(strHashesSha256Base64X64))
Else
  WScript.Quit(1)
End If

'If ValidateBase64(strHashesSha1Base64ARM64) = True Then
'  strHashesSha1HexARM64 = LCase(Base64ToHex(strHashesSha1Base64ARM64))
'Else
'  WScript.Quit(1)
'End If
'If ValidateBase64(strHashesSha256Base64ARM64) = True Then
'  strHashesSha256HexARM64 = LCase(Base64ToHex(strHashesSha256Base64ARM64))
'Else
'  WScript.Quit(1)
'End If

If ValidateBase64(strHashesSha1Base64Updater) = True Then
  strHashesSha1HexUpdater = LCase(Base64ToHex(strHashesSha1Base64Updater))
Else
  WScript.Quit(1)
End If
If ValidateBase64(strHashesSha256Base64Updater) = True Then
  strHashesSha256HexUpdater = LCase(Base64ToHex(strHashesSha256Base64Updater))
Else
  WScript.Quit(1)
End If

' --- STEP C: create DynamicDownloadLinks-msedge.txt and hashes-msedge.txt ---

Set fso = CreateObject("Scripting.FileSystemObject")

Set fDynamicDownloadLinks = fso.CreateTextFile(strPathDynamicDownloadLinks, True)
fDynamicDownloadLinks.WriteLine(strURLX86 & "," & strFileNameX86)
fDynamicDownloadLinks.WriteLine(strURLX64 & "," & strFileNameX64)
'fDynamicDownloadLinks.WriteLine(strURLARM64 & "," & strFileNameARM64)
fDynamicDownloadLinks.WriteLine(strURLUpdater & "," & strFileNameUpdater)
fDynamicDownloadLinks.Close

Set fHashes = fso.CreateTextFile(strPathHashes, True)
fHashes.WriteLine("%%%% HASHDEEP-1.0")
fHashes.WriteLine("%%%% size,sha1,sha256,filename")
fHashes.WriteLine(strSizeInBytesX86 & "," & strHashesSha1HexX86 & "," & strHashesSha256HexX86 & "," & strFileNameX86)
fHashes.WriteLine(strSizeInBytesX64 & "," & strHashesSha1HexX64 & "," & strHashesSha256HexX64 & "," & strFileNameX64)
'fHashes.WriteLine(strSizeInBytesARM64 & "," & strHashesSha1HexARM64 & "," & strHashesSha256HexARM64 & "," & strFileNameARM64)
fHashes.WriteLine(strSizeInBytesUpdater & "," & strHashesSha1HexUpdater & "," & strHashesSha256HexUpdater & "," & strFileNameUpdater)
fHashes.Close

Sub GetLatestEdgeDL(TargetNameSpace, TargetName)
  Dim strRequest, strResponse, strNamespaceBuf, strNameBuf, strVersionBuf
  Dim WebRequest
  Dim oJSON
  
  ' --- STEP 0: prepare output ---
  
  strVersion = ""
  strFileName = ""
  strURL = ""
  strSizeInBytes = ""
  strHashesSha1Base64 = ""
  strHashesSha256Base64 = ""
  
  ' --- STEP 1: NEVER TRUST USER DATA ---
  
  If TargetNameSpace = "" Then
    Exit Sub
  End If
  If TargetName = "" Then
    Exit Sub
  End If
  
  ' --- STEP 2: determine target version ---
  
  strRequest = ""
  Set oJSON = New aspJSON
  oJSON.data.Add "targetingAttributes", oJSON.Collection
  ' -- blank header --
  oJSON.data("targetingAttributes").Add "", ""
  ' -- relevant line from Windows 10 dump --
  'oJSON.data("targetingAttributes").Add "Priority", "10" ' FIXME: relevant for most recent version  (value is "10" for Edge, "0" for EdgeUpdate)
  strRequest = oJSON.JSONoutput
  
  ' Send first request
  strResponse = ""
  Set WebRequest = CreateObject("Msxml2.XMLHTTP")
  WebRequest.open "POST", "https://msedge.api.cdp.microsoft.com/api/v1.1/contents/Browser/namespaces/" & TargetNameSpace & "/names/" & TargetName & "/versions/latest?action=select", False
  WebRequest.setRequestHeader "Content-Length", Len(strRequest)
  WebRequest.setRequestHeader "Content-Type", "application/json"
  WebRequest.send(strRequest)
  strResponse = WebRequest.responseText
  
  If strResponse = "" Then
    Exit Sub
  End If
  
  ' parse result
  strNamespaceBuf = ""
  strNameBuf = ""
  strVersionBuf = ""
  Set oJSON = New aspJSON
  oJSON.loadJSON(strResponse)
  strResponse = ""
  
  strNamespaceBuf = oJSON.data("ContentId").item("Namespace")
  strNameBuf = oJSON.data("ContentId").item("Name")
  strVersionBuf = oJSON.data("ContentId").item("Version")
  
  If strNamespaceBuf = "" Then
    Exit Sub
  End If
  If strNameBuf = "" Then
    Exit Sub
  End If
  If strVersionBuf = "" Then
    Exit Sub
  End If

  ' --- STEP 2: get and return URLs ---
  
  GetEdgeDL strNamespaceBuf, strNameBuf, strVersionBuf
End Sub

Sub GetEdgeDL(TargetNameSpace, TargetName, TargetVersion)
  Dim strRequest, strResponse, strFileNameBuf, strURLBuf, strSizeInBytesBuf, strHashesSha1Base64Buf, strHashesSha256Base64Buf
  Dim WebRequest
  Dim oJSON
  Dim i
  
  ' --- STEP 0: prepare output ---
  
  strFileName = ""
  strURL = ""
  strSizeInBytes = ""
  strHashesSha1Base64 = ""
  strHashesSha256Base64 = ""
  
  ' --- STEP 1: NEVER TRUST USER DATA ---
  
  If TargetNameSpace = "" Then
    Exit Sub
  End If
  If TargetName = "" Then
    Exit Sub
  End If
  If TargetVersion = "" Then
    Exit Sub
  End If
  
  ' --- STEP 2: get URLs ---
  
  strRequest = ""
  Set oJSON = New aspJSON
  strRequest = oJSON.JSONoutput
  
  ' Send first request
  Set WebRequest = CreateObject("MSXML2.XMLHTTP")
  WebRequest.open "POST", "https://msedge.api.cdp.microsoft.com/api/v1.1/internal/contents/Browser/namespaces/" & TargetNameSpace & "/names/" & TargetName & "/versions/" & TargetVersion & "/files?action=GenerateDownloadInfo&foregroundPriority=true", False
  WebRequest.setRequestHeader "Content-Length", Len(strRequest)
  WebRequest.setRequestHeader "Content-Type", "application/json"
  WebRequest.send(strRequest)
  strResponse = WebRequest.responseText
  
  If strResponse = "" Then
    Exit Sub
  End If
  
  ' parse result
  Set oJSON = New aspJSON
  oJSON.loadJSON(strResponse)
  strResponse = ""
  
  strFileNameBuf = ""
  strURLBuf = ""
  strSizeInBytesBuf = ""
  strHashesSha1Base64Buf = ""
  strHashesSha256Base64Buf = ""
  
  For Each i In oJSON.data
    If ((oJSON.data(i).item("FileId") = "MicrosoftEdge_X86_" & TargetVersion & ".exe") Or (oJSON.data(i).item("FileId") = "MicrosoftEdge_X64_" & TargetVersion & ".exe") Or (oJSON.data(i).item("FileId") = "MicrosoftEdge_ARM64_" & TargetVersion & ".exe") Or (oJSON.data(i).item("FileId") = "MicrosoftEdgeUpdateSetup_X86_" & TargetVersion & ".exe")) Then
      strFileNameBuf = oJSON.data(i).item("FileId")
      strURLBuf = oJSON.data(i).item("Url")
      strSizeInBytesBuf = oJSON.data(i).item("SizeInBytes")
      strHashesSha1Base64Buf = oJSON.data(i).item("Hashes").item("Sha1")
      strHashesSha256Base64Buf = oJSON.data(i).item("Hashes").item("Sha256")
    End If
  Next
  
  If strFileNameBuf = "" Then
    Exit Sub
  End If
  If strURLBuf = "" Then
    Exit Sub
  End If
  If strSizeInBytesBuf = "" Then
    Exit Sub
  End If
  If strHashesSha1Base64Buf = "" Then
    Exit Sub
  End If
  If strHashesSha256Base64Buf = "" Then
    Exit Sub
  End If

  ' --- STEP 3: return result ---
  
  strFileName = strFileNameBuf
  strURL = strURLBuf
  strSizeInBytes = strSizeInBytesBuf
  strHashesSha1Base64 = strHashesSha1Base64Buf
  strHashesSha256Base64 = strHashesSha256Base64Buf
End Sub

' ----------------------------------------------------------------------------------------------------

' Quelle: http://www.rlmueller.net/Programs/Base64ToHex.txt
' modifiziert durch aker

' Base64ToHex.vbs
' VBScript program to convert a base64 encoded string into a hex string.
'
' ----------------------------------------------------------------------
' Copyright (c) 2010 Richard L. Mueller
' Hilltop Lab web site - http://www.rlmueller.net
' Version 1.0 - January 7, 2010
'
' Syntax:
'     cscript //nologo Base64ToHex.vbs <Base64 string>
' where:
'     <Base64 string> is a Base64 encoded string.
' If no parameter is supplied, the program will prompt.
'
' You have a royalty-free right to use, modify, reproduce, and
' distribute this script file in any way you find useful, provided that
' you agree that the copyright owner above has no warranty, obligations,
' or liability for such use.

Function ValidateBase64(strValue)
    ' Validate string.
    Dim objRE : Set objRE = New RegExp
    objRE.Pattern = "[A-Za-z0-9\+/]+[=]?[=]?"
    objRE.Global = True
    Dim objMatches : Set objMatches = objRE.Execute(strValue)
    If (objMatches.Count <> 1) Then
        ValidateBase64 = False
        Exit Function
    End If
	Dim objMatch
    For Each objMatch In objMatches
        If (objMatch.Length <> Len(strValue)) Then
            ValidateBase64 = False
			Exit Function
        End If
    Next
    
    If (Len(strValue) Mod 4 <> 0) Then
        ValidateBase64 = False
        Exit Function
    End If
	
    ValidateBase64 = True
End Function

Function Base64ToHex(strValue)
    ' Function to convert a base64 encoded string into a hex string.
    Dim lngValue, lngTemp, lngChar, k, j, intTerm, strHex

    ' Setup dictionary object used to convert Base64 characters into
    ' base 64 index integers.
    Dim objChars: Set objChars = CreateObject("Scripting.Dictionary")
    objChars.CompareMode = vbBinaryCompare

    objChars.Add "A", 0
    objChars.Add "B", 1
    objChars.Add "C", 2
    objChars.Add "D", 3
    objChars.Add "E", 4
    objChars.Add "F", 5
    objChars.Add "G", 6
    objChars.Add "H", 7
    objChars.Add "I", 8
    objChars.Add "J", 9
    objChars.Add "K", 10
    objChars.Add "L", 11
    objChars.Add "M", 12
    objChars.Add "N", 13
    objChars.Add "O", 14
    objChars.Add "P", 15
    objChars.Add "Q", 16
    objChars.Add "R", 17
    objChars.Add "S", 18
    objChars.Add "T", 19
    objChars.Add "U", 20
    objChars.Add "V", 21
    objChars.Add "W", 22
    objChars.Add "X", 23
    objChars.Add "Y", 24
    objChars.Add "Z", 25
    objChars.Add "a", 26
    objChars.Add "b", 27
    objChars.Add "c", 28
    objChars.Add "d", 29
    objChars.Add "e", 30
    objChars.Add "f", 31
    objChars.Add "g", 32
    objChars.Add "h", 33
    objChars.Add "i", 34
    objChars.Add "j", 35
    objChars.Add "k", 36
    objChars.Add "l", 37
    objChars.Add "m", 38
    objChars.Add "n", 39
    objChars.Add "o", 40
    objChars.Add "p", 41
    objChars.Add "q", 42
    objChars.Add "r", 43
    objChars.Add "s", 44
    objChars.Add "t", 45
    objChars.Add "u", 46
    objChars.Add "v", 47
    objChars.Add "w", 48
    objChars.Add "x", 49
    objChars.Add "y", 50
    objChars.Add "z", 51
    objChars.Add "0", 52
    objChars.Add "1", 53
    objChars.Add "2", 54
    objChars.Add "3", 55
    objChars.Add "4", 56
    objChars.Add "5", 57
    objChars.Add "6", 58
    objChars.Add "7", 59
    objChars.Add "8", 60
    objChars.Add "9", 61
    objChars.Add "+", 62
    objChars.Add "/", 63

    ' Check padding.
    intTerm = 0
    If (Right(strValue, 1) = "=") Then
        intTerm = 1
    End If
    If (Right(strValue, 2) = "==") Then
        intTerm = 2
    End If

    ' Parse into groups of 4 6-bit characters.
    j = 0
    lngValue = 0
    Base64ToHex = ""
    For k = 1 To Len(strValue)
        j = j + 1
        ' Calculate 24-bit integer.
        lngValue = (lngValue * 64) + objChars(Mid(strValue, k, 1))
        If (j = 4) Then
            ' Convert 24-bit integer into 3 8-bit bytes.
            lngTemp = Fix(lngValue / 256)
            lngChar = lngValue - (256 * lngTemp)
            strHex = Right("00" & Hex(lngChar), 2)
            lngValue = lngTemp

            lngTemp = Fix(lngValue / 256)
            lngChar = lngValue - (256 * lngTemp)
            strHex = Right("00" & Hex(lngChar), 2) & strHex
            lngValue = lngTemp

            lngTemp = Fix(lngValue / 256)
            lngChar = lngValue - (256 * lngTemp)
            strHex = Right("00" & Hex(lngChar), 2) & strHex

            Base64ToHex = Base64ToHex & strHex
            j = 0
            lngValue = 0
        End If
    Next
    ' Account for padding.
    Base64ToHex = Left(Base64ToHex, Len(Base64ToHex) - (intTerm * 2))

End Function

' ----------------------------------------------------------------------------------------------------

' Quelle: https://github.com/gerritvankuipers/aspjson
' VBScript-adjustments by aker
' January 2021 - Version 1.19 by Gerrit van Kuipers
Class aspJSON
	Public data
	Private p_JSONstring
	Private aj_in_string, aj_in_escape, aj_i_tmp, aj_char_tmp, aj_s_tmp, aj_line_tmp, aj_line, aj_lines, aj_currentlevel, aj_currentkey, aj_currentvalue, aj_newlabel, aj_XmlHttp, aj_RegExp, aj_colonfound

	Private Sub Class_Initialize()
		Set data = Collection()

	    Set aj_RegExp = New regexp
	    aj_RegExp.Pattern = "\s{0,}(\S{1}[\s,\S]*\S{1})\s{0,}"
	    aj_RegExp.Global = False
	    aj_RegExp.IgnoreCase = True
	    aj_RegExp.Multiline = True
	End Sub

	Private Sub Class_Terminate()
		Set data = Nothing
	    Set aj_RegExp = Nothing
	End Sub

	Public Sub loadJSON(inputsource)
		inputsource = aj_MultilineTrim(inputsource)
		If Len(inputsource) = 0 Then Err.Raise 1, "loadJSON Error", "No data to load."
		
		Select Case Left(inputsource, 1)
			Case "{", "["
			Case Else
'				Set aj_XmlHttp = Server.CreateObject("Msxml2.ServerXMLHTTP")
				Set aj_XmlHttp = CreateObject("Msxml2.XMLHTTP") ' VBScript-adjustment by aker
				aj_XmlHttp.open "POST", inputsource, False
				aj_XmlHttp.setRequestHeader "Content-Type", "text/json"
				aj_XmlHttp.setRequestHeader "CharSet", "UTF-8"
				aj_XmlHttp.Send
				inputsource = aj_XmlHttp.responseText
				Set aj_XmlHttp = Nothing
		End Select

		p_JSONstring = CleanUpJSONstring(inputsource)
		aj_lines = Split(p_JSONstring, Chr(13) & Chr(10))

		Dim level(99)
		aj_currentlevel = 1
		Set level(aj_currentlevel) = data
		For Each aj_line In aj_lines
			aj_currentkey = ""
			aj_currentvalue = ""
			If Instr(aj_line, ":") > 0 Then
				aj_in_string = False
				aj_in_escape = False
				aj_colonfound = False
				For aj_i_tmp = 1 To Len(aj_line)
					If aj_in_escape Then
						aj_in_escape = False
					Else
						Select Case Mid(aj_line, aj_i_tmp, 1)
							Case """"
								aj_in_string = Not aj_in_string
							Case ":"
								If Not aj_in_escape And Not aj_in_string Then
									aj_currentkey = Left(aj_line, aj_i_tmp - 1)
									aj_currentvalue = Mid(aj_line, aj_i_tmp + 1)
									aj_colonfound = True
									Exit For
								End If
							Case "\"
								aj_in_escape = True
						End Select
					End If
				Next
				if aj_colonfound then
					aj_currentkey = aj_Strip(aj_JSONDecode(aj_currentkey), """")
					If Not level(aj_currentlevel).exists(aj_currentkey) Then level(aj_currentlevel).Add aj_currentkey, ""
				end if
			End If
			If right(aj_line,1) = "{" Or right(aj_line,1) = "[" Then
				If Len(aj_currentkey) = 0 Then aj_currentkey = level(aj_currentlevel).Count
				Set level(aj_currentlevel).Item(aj_currentkey) = Collection()
				Set level(aj_currentlevel + 1) = level(aj_currentlevel).Item(aj_currentkey)
				aj_currentlevel = aj_currentlevel + 1
				aj_currentkey = ""
			ElseIf right(aj_line,1) = "}" Or right(aj_line,1) = "]" or right(aj_line,2) = "}," Or right(aj_line,2) = "]," Then
				aj_currentlevel = aj_currentlevel - 1
			ElseIf Len(Trim(aj_line)) > 0 Then
				If Len(aj_currentvalue) = 0 Then aj_currentvalue = aj_line
				aj_currentvalue = getJSONValue(aj_currentvalue)

				If Len(aj_currentkey) = 0 Then aj_currentkey = level(aj_currentlevel).Count
				level(aj_currentlevel).Item(aj_currentkey) = aj_currentvalue
			End If
		Next
	End Sub

	Public Function Collection()
'		Set Collection = Server.CreateObject("Scripting.Dictionary")
		Set Collection = CreateObject("Scripting.Dictionary") ' VBScript-adjustment by aker
	End Function

	Public Function AddToCollection(dictobj)
		If TypeName(dictobj) <> "Dictionary" Then Err.Raise 1, "AddToCollection Error", "Not a collection."
		aj_newlabel = dictobj.Count
		dictobj.Add aj_newlabel, Collection()
		Set AddToCollection = dictobj.item(aj_newlabel)
	end function

	Private Function CleanUpJSONstring(aj_originalstring)
		aj_originalstring = Replace(aj_originalstring, Chr(13) & Chr(10), "")
		aj_originalstring = Mid(aj_originalstring, 2, Len(aj_originalstring) - 2)
		aj_in_string = False : aj_in_escape = False : aj_s_tmp = ""
		For aj_i_tmp = 1 To Len(aj_originalstring)
			aj_char_tmp = Mid(aj_originalstring, aj_i_tmp, 1)
			If aj_in_escape Then
				aj_in_escape = False
				aj_s_tmp = aj_s_tmp & aj_char_tmp
			Else
				Select Case aj_char_tmp
					Case "\" : aj_s_tmp = aj_s_tmp & aj_char_tmp : aj_in_escape = True
					Case """" : aj_s_tmp = aj_s_tmp & aj_char_tmp : aj_in_string = Not aj_in_string
					Case "{", "["
						aj_s_tmp = aj_s_tmp & aj_char_tmp & aj_InlineIf(aj_in_string, "", Chr(13) & Chr(10))
					Case "}", "]"
						aj_s_tmp = aj_s_tmp & aj_InlineIf(aj_in_string, "", Chr(13) & Chr(10)) & aj_char_tmp
					Case "," : aj_s_tmp = aj_s_tmp & aj_char_tmp & aj_InlineIf(aj_in_string, "", Chr(13) & Chr(10))
					Case Else : aj_s_tmp = aj_s_tmp & aj_char_tmp
				End Select
			End If
		Next

		CleanUpJSONstring = ""
		aj_s_tmp = Split(aj_s_tmp, Chr(13) & Chr(10))
		For Each aj_line_tmp In aj_s_tmp
			aj_line_tmp = Replace(Replace(aj_line_tmp, Chr(10), ""), Chr(13), "")
			CleanUpJSONstring = CleanUpJSONstring & aj_Trim(aj_line_tmp) & Chr(13) & Chr(10)
		Next
	End Function

	Private Function getJSONValue(ByVal val)
		val = Trim(val)
		If Left(val,1) = ":"  Then val = Mid(val, 2)
		If Right(val,1) = "," Then val = Left(val, Len(val) - 1)
		val = Trim(val)

		Select Case val
			Case "true"  : getJSONValue = True
			Case "false" : getJSONValue = False
			Case "null" : getJSONValue = Null
			Case Else
				If (Instr(val, """") = 0) Then
					If IsNumeric(val) Then
						getJSONValue = aj_ReadNumericValue(val)
					Else
						getJSONValue = val
					End If
				Else
					If Left(val,1) = """" Then val = Mid(val, 2)
					If Right(val,1) = """" Then val = Left(val, Len(val) - 1)
					getJSONValue = aj_JSONDecode(Trim(val))
				End If
		End Select
	End Function

	Private JSONoutput_level
	Public Function JSONoutput()
		Dim wrap_dicttype, aj_label
		JSONoutput_level = 1
		wrap_dicttype = "[]"
		For Each aj_label In data
			If Not aj_IsInt(aj_label) Then wrap_dicttype = "{}"
		Next
		JSONoutput = Left(wrap_dicttype, 1) & Chr(13) & Chr(10) & GetDict(data) & Right(wrap_dicttype, 1)
	End Function

	Private Function GetDict(objDict)
		Dim aj_item, aj_keyvals, aj_label, aj_dicttype
		For Each aj_item In objDict
			Select Case TypeName(objDict.Item(aj_item))
				Case "Dictionary"
					GetDict = GetDict & Space(JSONoutput_level * 4)
					
					aj_dicttype = "[]"
					For Each aj_label In objDict.Item(aj_item).Keys
						 If Not aj_IsInt(aj_label) Then aj_dicttype = "{}"
					Next
					If aj_IsInt(aj_item) Then
						GetDict = GetDict & (Left(aj_dicttype,1) & Chr(13) & Chr(10))
					Else
						GetDict = GetDict & ("""" & aj_JSONEncode(aj_item) & """" & ": " & Left(aj_dicttype,1) & Chr(13) & Chr(10))
					End If
					JSONoutput_level = JSONoutput_level + 1
					
					aj_keyvals = objDict.Keys
					GetDict = GetDict & (GetSubDict(objDict.Item(aj_item)) & Space(JSONoutput_level * 4) & Right(aj_dicttype,1) & aj_InlineIf(aj_item = aj_keyvals(objDict.Count - 1),"" , ",") & Chr(13) & Chr(10))
				Case Else
					aj_keyvals =  objDict.Keys
					GetDict = GetDict & (Space(JSONoutput_level * 4) & aj_InlineIf(aj_IsInt(aj_item), "", """" & aj_JSONEncode(aj_item) & """: ") & WriteValue(objDict.Item(aj_item)) & aj_InlineIf(aj_item = aj_keyvals(objDict.Count - 1),"" , ",") & Chr(13) & Chr(10))
			End Select
		Next
	End Function

	Private Function aj_IsInt(val)
		aj_IsInt = (TypeName(val) = "Integer" Or TypeName(val) = "Long")
	End Function

	Private Function GetSubDict(objSubDict)
		GetSubDict = GetDict(objSubDict)
		JSONoutput_level= JSONoutput_level -1
	End Function

	Private Function WriteValue(ByVal val)
		Select Case TypeName(val)
			Case "Double", "Integer", "Long": WriteValue = replace(val, ",", ".")
			Case "Null"						: WriteValue = "null"
			Case "Boolean"					: WriteValue = aj_InlineIf(val, "true", "false")
			Case Else						: WriteValue = """" & aj_JSONEncode(val) & """"
		End Select
	End Function

	Private Function aj_JSONEncode(ByVal val)
		val = Replace(val, "\", "\\")
		val = Replace(val, """", "\""")
		'val = Replace(val, "/", "\/")
		val = Replace(val, Chr(8), "\b")
		val = Replace(val, Chr(12), "\f")
		val = Replace(val, Chr(10), "\n")
		val = Replace(val, Chr(13), "\r")
		val = Replace(val, Chr(9), "\t")
		aj_JSONEncode = Trim(val)
	End Function

	Private Function aj_JSONDecode(ByVal val)
		val = Replace(val, "\""", """")
		val = Replace(val, "\\", "\")
		val = Replace(val, "\/", "/")
		val = Replace(val, "\b", Chr(8))
		val = Replace(val, "\f", Chr(12))
		val = Replace(val, "\n", Chr(10))
		val = Replace(val, "\r", Chr(13))
		val = Replace(val, "\t", Chr(9))
		aj_JSONDecode = Trim(val)
	End Function

	Private Function aj_InlineIf(condition, returntrue, returnfalse)
		If condition Then aj_InlineIf = returntrue Else aj_InlineIf = returnfalse
	End Function

	Private Function aj_Strip(ByVal val, stripper)
		If Left(val, 1) = stripper Then val = Mid(val, 2)
		If Right(val, 1) = stripper Then val = Left(val, Len(val) - 1)
		aj_Strip = val
	End Function

	Private Function aj_MultilineTrim(TextData)
		aj_MultilineTrim = aj_RegExp.Replace(TextData, "$1")
	End Function

	Private Function aj_Trim(val)
		aj_Trim = Trim(val)
		Do While Left(aj_Trim, 1) = Chr(9) : aj_Trim = Mid(aj_Trim, 2) : Loop
		Do While Right(aj_Trim, 1) = Chr(9) : aj_Trim = Left(aj_Trim, Len(aj_Trim) - 1) : Loop
		aj_Trim = Trim(aj_Trim)
	End Function

	Private Function aj_ReadNumericValue(ByVal val)
		If Instr(val, ".") > 0 Then
			numdecimals = Len(val) - Instr(val, ".")
			val = Clng(Replace(val, ".", ""))
			val = val / (10 ^ numdecimals)
			aj_ReadNumericValue = val
		Else
			aj_ReadNumericValue = Clng(val)
		End If
	End Function
End Class