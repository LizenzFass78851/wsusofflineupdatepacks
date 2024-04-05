' *** Author: T. Wittrock, Kiel ***
' ***   - Community Edition -   ***

Option Explicit

Private Const strRegKeyWindowsVersion          = "HKLM\Software\Microsoft\Windows NT\CurrentVersion\"
Private Const strRegKeySHA2Support             = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Servicing\Codesigning\SHA2\"
Private Const strRegKeyIE                      = "HKLM\Software\Microsoft\Internet Explorer\"
Private Const strRegKeyDotNet35                = "HKLM\Software\Microsoft\NET Framework Setup\NDP\v3.5\"
Private Const strRegKeyDotNet4                 = "HKLM\Software\Microsoft\NET Framework Setup\NDP\v4\Full\"
Private Const strRegKeyPowerShell              = "HKLM\Software\Microsoft\PowerShell\1\PowerShellEngine\"
Private Const strRegKeyManagementFramework     = "HKLM\Software\Microsoft\PowerShell\3\PowerShellEngine\"
Private Const strRegKeyMSSE                    = "HKLM\Software\Microsoft\Microsoft Security Client\"
Private Const strRegKeyMSSEUninstall           = "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Security Client\"
Private Const strRegKeyMSSEDefs                = "HKLM\Software\Microsoft\Microsoft Antimalware\Signature Updates\"
Private Const strRegKeyWD                      = "HKLM\Software\Microsoft\Windows Defender\"
Private Const strRegKeyWDPolicy                = "HKLM\Software\Policies\Microsoft\Windows Defender\"
Private Const strRegKeyWDDefs                  = "HKLM\Software\Microsoft\Windows Defender\Signature Updates\"
Private Const strRegKeyQualityCompat           = "HKLM\Software\Microsoft\Windows\CurrentVersion\QualityCompat\cadca5fe-87d3-4b96-b7fb-a231484277cc"
Private Const strRegKeyPowerCfg                = "HKCU\Control Panel\PowerCfg\"

Private Const strRegValVersion                 = "Version"
Private Const strRegValRelease                 = "Release"
Private Const strRegValDisplayVersion          = "DisplayVersion"
Private Const strRegValUBR                     = "UBR"
Private Const strRegValBuildLabEx              = "BuildLabEx"
Private Const strRegValSHA2Support             = "SHA2-Codesigning-Support"
Private Const strRegValSHA2Support2            = "SHA2-Core-Codesigning-Support"
Private Const strRegValInstallationType        = "InstallationType"
Private Const strRegValPShVersion              = "PowerShellVersion"
Private Const strRegValAVSVersion              = "AVSignatureVersion"
Private Const strRegValNISSVersion             = "NISSignatureVersion"
Private Const strRegValASSVersion              = "ASSignatureVersion"
Private Const strRegValDisableAntiSpyware      = "DisableAntiSpyware"
Private Const strRegValCurrentPowerPolicy      = "CurrentPowerPolicy"
Private Const strRegKeyOfficePrefix_Mx86       = "HKLM\Software\Microsoft\Office\"
Private Const strRegKeyOfficePrefix_Mx64       = "HKLM\Software\Wow6432Node\Microsoft\Office\"
Private Const strRegKeyOfficePrefix_User       = "HKCU\Software\Microsoft\Office\"
Private Const strRegKeyOfficeInfixes_Version   = "15.0,16.0"
Private Const strRegKeyOfficeSuffix_FilesPaths = "\Common\FilesPaths\"
Private Const strRegKeyOfficeSuffix_InstRoot   = "\Common\InstallRoot\"
Private Const strRegKeyOfficeSuffix_Language   = "\Common\LanguageResources\"
Private Const strRegKeyOfficeSuffix_Outlook    = "\Outlook\"
Private Const strRegValOfficePath              = "Path"
Private Const strRegValOfficeMSOFilePath       = "mso.dll"
Private Const strRegValOfficeLanguage_Inst     = "SKULanguage"
Private Const strRegValOfficeLanguage_User     = "InstallLanguage"
Private Const strRegValOfficeVersion           = "LastProduct"
Private Const strRegValOfficeArchitecture      = "Bitness"
Private Const strOfficeNames                   = "o2k13,o2k16"
Private Const strBuildNumbers_o2k13            = "4420;4569"
Private Const strBuildNumbers_o2k16            = "4266"
Private Const strVersionSuffixes               = "MAJOR,MINOR,BUILD,REVIS"
Private Const idxBuild                         = 2

Dim wshShell, objFileSystem, objCmdFile, objWMIService, objQueryItem, objFolder, arrayOfficeNames, arrayOfficeVersions, MSIProducts
Dim strSystemFolder, strTempFolder, strProfileFolder, strKernelFileName, strWUAFileName, strMSIFileName, strTSCFileName, strCmdFileName
Dim strOSArchitecture, strKernelVersion, strBuildLabEx, strUBR, strInstallationType, strOfficeInstallPath, strMSOFilePath, strOfficeMSOVersion, strMSIProductId, languageCode, i, j
Dim ServicingStack_Major, ServicingStack_Minor, ServicingStack_Build, ServicingStack_Revis, OSVer_Real_Major, OSVer_Real_Minor, OSVer_Real_Build

Private Function RegExists(objShell, strName)
  Dim dummy
  On Error Resume Next
  dummy = objShell.RegRead(strName)
  RegExists = (Err >= 0)
  Err.Clear
End Function

Private Function RegRead(objShell, strName)
  On Error Resume Next
  RegRead = objShell.RegRead(strName)
  If Err <> 0 Then
    RegRead = ""
    Err.Clear
  End If
End Function

Private Function GetFileVersion(objFS, strName)
  On Error Resume Next
  GetFileVersion = objFS.GetFileVersion(strName)
  If Err <> 0 Then
    WScript.Quit(1)
  End If
End Function

Private Sub WriteLanguageToFile(cmdFile, varName, langCode, writeShortLang, writeExtLang)
  Select Case langCode
  ' supported languages
    Case &H0009, &H0409, &H0809, &H0C09, &H1009, &H1409, &H1809, &H1C09, &H2009, &H2409, &H2809, &H2C09, &H3009, &H3409, &H4009, &H4409, &H4809
      cmdFile.WriteLine("set " & varName & "=enu")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=en")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=en-us")
    Case &H000C, &H040C, &H080C, &H0C0C, &H100C, &H140C, &H180C
      cmdFile.WriteLine("set " & varName & "=fra")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=fr")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=fr-fr")
    Case &H000A, &H080A, &H0C0A, &H100A, &H140A, &H180A, &H1C0A, &H200A, &H240A, &H280A, &H2C0A, &H300A, &H340A, &H380A, &H3C0A, &H400A, &H440A, &H480A, &H4C0A, &H500A, &H540A
      cmdFile.WriteLine("set " & varName & "=esn")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=es")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=es-es")
    Case &H0019, &H0419
      cmdFile.WriteLine("set " & varName & "=rus")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=ru")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ru-ru")
    Case &H0816
      cmdFile.WriteLine("set " & varName & "=ptg")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=pt")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=pt-pt")
    Case &H0416
      cmdFile.WriteLine("set " & varName & "=ptb")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=pt")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=pt-br")
    Case &H0007, &H0407, &H0807, &H0C07, &H1007, &H1407
      cmdFile.WriteLine("set " & varName & "=deu")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=de")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=de-de")
    Case &H0013, &H0413, &H0813
      cmdFile.WriteLine("set " & varName & "=nld")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=nl")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=nl-nl")
    Case &H0010, &H0410, &H0810
      cmdFile.WriteLine("set " & varName & "=ita")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=it")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=it-it")
    Case &H0015, &H0415
      cmdFile.WriteLine("set " & varName & "=plk")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=pl")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=pl-pl")
    Case &H000E, &H040E
      cmdFile.WriteLine("set " & varName & "=hun")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=hu")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=hu-hu")
    Case &H0005, &H0405
      cmdFile.WriteLine("set " & varName & "=csy")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=cs")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=cs-cz")
    Case &H001D, &H041D, &H081D
      cmdFile.WriteLine("set " & varName & "=sve")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=sv")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=sv-se")
    Case &H001F, &H041F
      cmdFile.WriteLine("set " & varName & "=trk")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=tr")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=tr-tr")
    Case &H0008, &H0408
      cmdFile.WriteLine("set " & varName & "=ell")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=el")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=el-gr")
    Case &H0006, &H0406
      cmdFile.WriteLine("set " & varName & "=dan")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=da")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=da-dk")
    Case &H0014, &H0414, &H7C14, &H0814, &H7814
      cmdFile.WriteLine("set " & varName & "=nor")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=no")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=nb-no")
    Case &H000B, &H040B
      cmdFile.WriteLine("set " & varName & "=fin")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=fi")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=fi-fi")
    Case &H0004, &H0804, &H1004, &H7804
      cmdFile.WriteLine("set " & varName & "=chs")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=zh")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=zh-cn")
    Case &H0404, &H0C04, &H1404, &H7C04
      cmdFile.WriteLine("set " & varName & "=cht")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=zh")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=zh-tw")
    Case &H0011, &H0411
      cmdFile.WriteLine("set " & varName & "=jpn")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=ja")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ja-jp")
    Case &H0012, &H0412
      cmdFile.WriteLine("set " & varName & "=kor")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=ko")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ko-kr")
    Case &H0001, &H0401, &H0801, &H0C01, &H1001, &H1401, &H1801, &H1C01, &H2001, &H2401, &H2801, &H2C01, &H3001, &H3401, &H3801, &H3C01, &H4001
      cmdFile.WriteLine("set " & varName & "=ara")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=ar")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ar-sa")
    Case &H000D, &H040D
      cmdFile.WriteLine("set " & varName & "=heb")
      If writeShortLang Then cmdFile.WriteLine("set " & varName & "_SHORT=he")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=he-il")

    ' unsupported languages, detection only
    Case &H002B, &H042B
      cmdFile.WriteLine("set " & varName & "=hye")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=hy-am")
    Case &H002D, &H042D
      cmdFile.WriteLine("set " & varName & "=euq")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=eu-es")
    Case &H0023, &H0423
      cmdFile.WriteLine("set " & varName & "=bel")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=be-by")
    Case &H007E, &H047E
      cmdFile.WriteLine("set " & varName & "=bre")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=br-fr")
    Case &H0002, &H0402
      cmdFile.WriteLine("set " & varName & "=bgr")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=bg-bg")
    Case &H0003, &H0403
      cmdFile.WriteLine("set " & varName & "=cat")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ca-es")
    Case &H0083, &H0483
      cmdFile.WriteLine("set " & varName & "=cos")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=co-fr")
    Case &H001A, &H041A, &H101A
      cmdFile.WriteLine("set " & varName & "=hrv")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=hr-hr")
    Case &H0025, &H0425
      cmdFile.WriteLine("set " & varName & "=eti")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=et-ee")
    Case &H0038, &H0438
      cmdFile.WriteLine("set " & varName & "=fos")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=fo-fo")
    Case &H0062, &H0462
      cmdFile.WriteLine("set " & varName & "=fyn")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=fy-nl")
    Case &H0056, &H0456
      cmdFile.WriteLine("set " & varName & "=glc")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=gl-es")
    Case &H0037, &H0437
      cmdFile.WriteLine("set " & varName & "=kat")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ka-ge")
    Case &H006F, &H046F
      cmdFile.WriteLine("set " & varName & "=kal")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=kl-gl")
    Case &H0039, &H0439
      cmdFile.WriteLine("set " & varName & "=hin")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=hi-in")
    Case &H000F, &H040F
      cmdFile.WriteLine("set " & varName & "=isl")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=is-is")
    Case &H003C, &H083C
      cmdFile.WriteLine("set " & varName & "=ire")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ga-ie")
    Case &H0026, &H0426
      cmdFile.WriteLine("set " & varName & "=lvi")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=lv-lv")
    Case &H0027, &H0427
      cmdFile.WriteLine("set " & varName & "=lth")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=lt-lt")
    Case &H0029, &H0429
      cmdFile.WriteLine("set " & varName & "=far")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=fa-ir")
    Case &H0046, &H0446
      cmdFile.WriteLine("set " & varName & "=pan")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=pa-in")
    Case &H0018, &H0418
      cmdFile.WriteLine("set " & varName & "=rom")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=ro-ro")
    Case &H004F, &H044F
      cmdFile.WriteLine("set " & varName & "=san")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=sa-in")
    Case &H001B, &H041B
      cmdFile.WriteLine("set " & varName & "=sky")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=sk-sk")
    Case &H0024, &H0424
      cmdFile.WriteLine("set " & varName & "=slv")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=sl-si")
    Case &H001E, &H041E
      cmdFile.WriteLine("set " & varName & "=tha")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=th-th")
    Case &H0022, &H0422
      cmdFile.WriteLine("set " & varName & "=ukr")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=uk-ua")
    Case &H002A, &H042A
      cmdFile.WriteLine("set " & varName & "=vit")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=vi-vn")
    Case &H0052, &H0452
      cmdFile.WriteLine("set " & varName & "=cym")
      If writeExtLang Then cmdFile.WriteLine("set " & varName & "_EXT=cy-gb")
  End Select
End Sub

Private Sub WriteVersionToFile(cmdFile, strPrefix, strVersion)
  Dim arraySuffixes, arrayVersion, i
  
  arraySuffixes = Split(strVersionSuffixes, ",")
  If Len(strVersion) > 0 Then
    arrayVersion = Split(strVersion, ".")
  Else
    arrayVersion = Split("0", ".")
  End If
  For i = 0 To UBound(arraySuffixes)
    If i > UBound(arrayVersion) Then
      cmdFile.WriteLine("set " & strPrefix & "_" & arraySuffixes(i) & "=0")
    Else
      cmdFile.WriteLine("set " & strPrefix & "_" & arraySuffixes(i) & "=" & arrayVersion(i))
    End If
  Next
End Sub

Private Function OfficeInstallPath(objShell, strVersionInfix)
  Dim strRegVal
  
  OfficeInstallPath = ""
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_InstRoot & strRegValOfficePath)
  If strRegVal <> "" Then
    OfficeInstallPath = strRegVal
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx64 & strVersionInfix & strRegKeyOfficeSuffix_InstRoot & strRegValOfficePath)
  If strRegVal <> "" Then
    OfficeInstallPath = strRegVal
    Exit Function
  End If
End Function

Private Function OfficeMSOFilePath(objShell, strVersionInfix)
  Dim strRegVal
  
  OfficeMSOFilePath = ""
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_FilesPaths & strRegValOfficeMSOFilePath)
  If strRegVal <> "" Then
    OfficeMSOFilePath = strRegVal
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx64 & strVersionInfix & strRegKeyOfficeSuffix_FilesPaths & strRegValOfficeMSOFilePath)
  If strRegVal <> "" Then
    OfficeMSOFilePath = strRegVal
    Exit Function
  End If
End Function

Private Function OfficeLanguageCode(objShell, strVersionInfix)
  Dim strRegVal
  
  OfficeLanguageCode = 0
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_Inst)
  If strRegVal <> "" Then
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx64 & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_Inst)
  If strRegVal <> "" Then
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_User & strVersionInfix & strRegKeyOfficeSuffix_Language & strRegValOfficeLanguage_User)
  If strRegVal <> "" Then
    OfficeLanguageCode = CInt(strRegVal)
    Exit Function
  End If
End Function

Private Function OfficeArchitecture(objShell, strOSArch, strVersionInfix, strOfficeInstPath)
  Dim strRegVal
  
  OfficeArchitecture = strOSArch
  If strOSArch = "x86" Then
    Exit Function
  End If
  strRegVal = RegRead(objShell, strRegKeyOfficePrefix_Mx86 & strVersionInfix & strRegKeyOfficeSuffix_Outlook & strRegValOfficeArchitecture)
  If strRegVal <> "" Then
    OfficeArchitecture = strRegVal
    Exit Function
  End If
  If InStr(strOfficeInstPath, "x86") > 0 Then
    OfficeArchitecture = "x86"
    Exit Function
  End If
End Function

Private Function OfficeSPVersion(strExeVersion)
  Dim arrayVersion, arraySPs, i
  
  OfficeSPVersion = 65535 ' use this for "error" (e.g. build lower than first RTM build)
  arrayVersion = Split(strExeVersion, ".")
  Select Case CInt(arrayVersion(0))
    Case 15
      arraySPs = Split(strBuildNumbers_o2k13, ";")
    Case 16
      arraySPs = Split(strBuildNumbers_o2k16, ";")
    Case Else
      Exit Function
  End Select
  If UBound(arrayVersion) < idxBuild Then
    Exit Function
  End If
  For i = 0 To UBound(arraySPs)
    If CInt(arrayVersion(idxBuild)) >= CInt(arraySPs(i)) Then
      OfficeSPVersion = i
    End If
  Next
End Function

' Quelle: https://stackoverflow.com/questions/854975/how-to-read-from-a-text-file-using-vbscript
Private Function ReadStaticFile(strRelFileName)
  Dim dict, file, line, row
  
  Set dict = CreateObject("Scripting.Dictionary")
  
  If ((Not objFileSystem Is Nothing) And (objFileSystem.FileExists("..\static\" & strRelFileName) = True)) Then
    Set file = objFileSystem.OpenTextFile ("..\static\" & strRelFileName)
    row = 0
    Do Until file.AtEndOfStream
      line = file.Readline
      dict.Add row, line
      row = row + 1
    Loop
    
    file.Close
  End If
  
  Set ReadStaticFile = dict
End Function

Private Function CheckMSIProduct(strProductName)
  ' CheckMSIProduct(strProductName):
  ' cpp2005_x86, cpp2005_x64
  ' cpp2008_x86, cpp2008_x64
  ' cpp2010_x86, cpp2010_x64
  ' cpp2012_x86, cpp2012_x64
  ' cpp2013_x86, cpp2013_x64
  ' cpp2015_x86, cpp2015_x64
  
  Dim objInstaller
  Dim MSIProduct_old, MSIProduct_new
  Dim MSIProduct_old_ids, MSIProduct_new_ids
  Dim strMSIProductProductBuffer, strMSIProductPatchBuffer, strMSIProductStaticId, strMSIProductStaticIdProductBuffer, strMSIProductStaticIdPatchBuffer
  
  Set MSIProduct_old_ids = ReadStaticFile("StaticUpdateIds-MSIProducts-" & strProductName & "_old.txt")
  Set MSIProduct_new_ids = ReadStaticFile("StaticUpdateIds-MSIProducts-" & strProductName & "_new.txt")
  
  Set objInstaller = CreateObject("WindowsInstaller.Installer")
  
  MSIProduct_old = False
  MSIProduct_new = False
  
  For Each strMSIProductProductBuffer In objInstaller.Products
    For Each strMSIProductStaticId in MSIProduct_old_ids.Items
      If InStr(1, strMSIProductStaticId, ",", vbTextCompare) > 0 Then
        strMSIProductStaticIdProductBuffer = Split(strMSIProductStaticId, ",")(0)
        strMSIProductStaticIdPatchBuffer = Split(strMSIProductStaticId, ",")(1)
      Else
        strMSIProductStaticIdProductBuffer = strMSIProductStaticId
        strMSIProductStaticIdPatchBuffer = ""
      End If
      If UCase(strMSIProductProductBuffer) = UCase(strMSIProductStaticIdProductBuffer) Then
        If strMSIProductStaticIdPatchBuffer = "" Then
          MSIProduct_old = True
        Else
          For Each strMSIProductPatchBuffer In objInstaller.Patches(strMSIProductProductBuffer)
            If UCase(strMSIProductPatchBuffer) = UCase(strMSIProductStaticIdPatchBuffer) Then
              MSIProduct_old = True
            End If
          Next
        End If
      End If
    Next
    For Each strMSIProductStaticId in MSIProduct_new_ids.Items
      If InStr(1, strMSIProductStaticId, ",", vbTextCompare) > 0 Then
        strMSIProductStaticIdProductBuffer = Split(strMSIProductStaticId, ",")(0)
        strMSIProductStaticIdPatchBuffer = Split(strMSIProductStaticId, ",")(1)
      Else
        strMSIProductStaticIdProductBuffer = strMSIProductStaticId
        strMSIProductStaticIdPatchBuffer = ""
      End If
      If UCase(strMSIProductProductBuffer) = UCase(strMSIProductStaticIdProductBuffer) Then
        If strMSIProductStaticIdPatchBuffer = "" Then
          MSIProduct_new = True
        Else
          For Each strMSIProductPatchBuffer In objInstaller.Patches(strMSIProductProductBuffer)
            If UCase(strMSIProductPatchBuffer) = UCase(strMSIProductStaticIdPatchBuffer) Then
              MSIProduct_new = True
            End If
          Next
        End If
      End If
    Next
  Next
  
  'WScript.Echo "CheckMSIProduct: " & strProductName & " -> old=" & CStr(MSIProduct_old) & " & new=" & CStr(MSIProduct_new)
  
  If ((MSIProduct_old = True) And (MSIProduct_new = False)) Then
    CheckMSIProduct = True
  Else
    CheckMSIProduct = False
  End If
End Function

' Main
Set wshShell = WScript.CreateObject("WScript.Shell")
strSystemFolder = wshShell.ExpandEnvironmentStrings("%SystemRoot%") & "\system32"
strTempFolder = wshShell.ExpandEnvironmentStrings("%TEMP%")
strProfileFolder = wshShell.ExpandEnvironmentStrings("%USERPROFILE%")
strKernelFileName = strSystemFolder & "\ntoskrnl.exe"
strWUAFileName = strSystemFolder & "\wuaueng.dll"
strMSIFileName = strSystemFolder & "\msi.dll"
strTSCFileName = strSystemFolder & "\mstsc.exe"
If WScript.Arguments.Count = 0 Then
  strCmdFileName = strProfileFolder & "\Desktop\WOUSystemProperties.txt"
Else
  If LCase(WScript.Arguments(0)) = "/nodebug" Then
    strCmdFileName = strTempFolder & "\SetSystemEnvVars.cmd"
  Else
    strCmdFileName = strProfileFolder & "\Desktop\WOUSystemProperties.txt"
  End If
End If
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objCmdFile = objFileSystem.CreateTextFile(strCmdFileName, True)

' Determine basic system properties

strKernelVersion = GetFileVersion(objFileSystem, strKernelFileName)

Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")
' Documentation: http://msdn.microsoft.com/en-us/library/aa394239(VS.85).aspx
For Each objQueryItem in objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
  If RegExists(wshShell, strRegKeyWindowsVersion & strRegValUBR) Then
    strUBR = RegRead(wshShell, strRegKeyWindowsVersion & strRegValUBR)
    WriteVersionToFile objCmdFile, "OS_VER", objQueryItem.Version & "." & strUBR
  Else
    strBuildLabEx = RegRead(wshShell, strRegKeyWindowsVersion & strRegValBuildLabEx)
    If strBuildLabEx = "" Then
      WriteVersionToFile objCmdFile, "OS_VER", objQueryItem.Version
    Else
      WriteVersionToFile objCmdFile, "OS_VER", objQueryItem.Version & Mid(strBuildLabEx, InStr(strBuildLabEx, "."), InStr(InStr(strBuildLabEx, ".") + 1, strBuildLabEx, ".") - InStr(strBuildLabEx, "."))
    End If
  End If
  OSVer_Real_Major = CInt(Split(objQueryItem.Version, ".")(0))
  OSVer_Real_Minor = CInt(Split(objQueryItem.Version, ".")(1))
  OSVer_Real_Build = CInt(Split(strKernelVersion, ".")(2))
  objCmdFile.WriteLine("set OS_VER_BUILD_INTERNAL=" & strKernelVersion)
  objCmdFile.WriteLine("set OS_SP_VER_MAJOR=" & objQueryItem.ServicePackMajorVersion)
  objCmdFile.WriteLine("set OS_SP_VER_MINOR=" & objQueryItem.ServicePackMinorVersion)
  objCmdFile.WriteLine("set OS_LANG_CODE=0x" & Hex(objQueryItem.OSLanguage))
  WriteLanguageToFile objCmdFile, "OS_LANG", objQueryItem.OSLanguage, True, True
  strInstallationType = RegRead(wshShell, strRegKeyWindowsVersion & strRegValInstallationType)
  If InStr(1, strInstallationType, "Core", vbTextCompare) > 0 Then
    objCmdFile.WriteLine("set OS_SRV_CORE=1")
  End If
  If CInt(Split(objQueryItem.Version, ".")(0)) < 6 Then
    ' Windows 2000, Windows XP, Windows Server 2003 never got SHA2-support
    objCmdFile.WriteLine("set OS_SHA2_SUPPORT=0")
  ElseIf CInt(Split(objQueryItem.Version, ".")(0)) = 6 Then
    If CInt(Split(objQueryItem.Version, ".")(1)) = 0 Then
      ' Windows Vista never got SHA2-support
      ' Windows Server 2008 needs an update for SHA2-support
      If RegExists(wshShell, strRegKeySHA2Support & strRegValSHA2Support) And RegExists(wshShell, strRegKeySHA2Support & strRegValSHA2Support2) Then
        If (CInt(RegRead(wshShell, strRegKeySHA2Support & strRegValSHA2Support)) > 0) And (CInt(RegRead(wshShell, strRegKeySHA2Support & strRegValSHA2Support2)) > 0) Then
          objCmdFile.WriteLine("set OS_SHA2_SUPPORT=1")
        Else
          objCmdFile.WriteLine("set OS_SHA2_SUPPORT=0")
        End If
      Else
        objCmdFile.WriteLine("set OS_SHA2_SUPPORT=0")
      End If
    ElseIf CInt(Split(objQueryItem.Version, ".")(1)) = 1 Then
      ' Windows 7 / Windows Server 2008 R2 needs an update for SHA2-support
      If RegExists(wshShell, strRegKeySHA2Support & strRegValSHA2Support) And RegExists(wshShell, strRegKeySHA2Support & strRegValSHA2Support2) Then
        If (CInt(RegRead(wshShell, strRegKeySHA2Support & strRegValSHA2Support)) > 0) And (CInt(RegRead(wshShell, strRegKeySHA2Support & strRegValSHA2Support2)) > 0) Then
          objCmdFile.WriteLine("set OS_SHA2_SUPPORT=1")
        Else
          objCmdFile.WriteLine("set OS_SHA2_SUPPORT=0")
        End If
      Else
        objCmdFile.WriteLine("set OS_SHA2_SUPPORT=0")
      End If
    ElseIf CInt(Split(objQueryItem.Version, ".")(1)) >= 2 Then
      ' Windows 8 / Windows Server 2012, Windows 8.1 / Windows Server 2012 R2 have native SHA2-support
      objCmdFile.WriteLine("set OS_SHA2_SUPPORT=1")
	End If
  ElseIf CInt(Split(objQueryItem.Version, ".")(0)) > 6 Then
    ' Windows 10 / Windows Server 2016 / Windows Server 2019 have native SHA2-support
    objCmdFile.WriteLine("set OS_SHA2_SUPPORT=1")
  End If
  objCmdFile.WriteLine("set SystemDirectory=" & objQueryItem.SystemDirectory)
Next
' Documentation: http://msdn.microsoft.com/en-us/library/aa394102(VS.85).aspx
For Each objQueryItem in objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
  strOSArchitecture = LCase(Left(objQueryItem.SystemType, 3))
  objCmdFile.WriteLine("set OS_ARCH=" & strOSArchitecture)
  objCmdFile.WriteLine("set OS_DOMAIN_ROLE=" & objQueryItem.DomainRole)
  objCmdFile.WriteLine("set OS_RAM_GB=" & CInt(CDbl(objQueryItem.TotalPhysicalMemory) / 1073741824))
Next
' Documentation: https://msdn.microsoft.com/en-us/library/aa394418(v=vs.85).aspx
For Each objQueryItem in objWMIService.ExecQuery("Select * from Win32_Service Where Name = 'wuauserv'")
  objCmdFile.WriteLine("set WU_START_MODE=" & objQueryItem.StartMode)
Next
' Documentation: http://msdn.microsoft.com/en-us/library/hww8txat(v=VS.85).aspx
objCmdFile.WriteLine("set FS_TYPE=" & objFileSystem.GetDrive(objFileSystem.GetDriveName(wshShell.CurrentDirectory)).FileSystem)

' Determine Servicing Stack version
If OSVer_Real_Major >= 6 Then
  ServicingStack_Major = 0
  ServicingStack_Minor = 0
  ServicingStack_Build = 0
  ServicingStack_Revis = 0
  For Each objFolder In objFileSystem.GetFolder(wshShell.ExpandEnvironmentStrings("%SystemRoot%") & "\servicing\Version").SubFolders
    If (CInt(Split(objFolder.Name, ".")(0)) = OSVer_Real_Major) And (CInt(Split(objFolder.Name, ".")(1)) = OSVer_Real_Minor) And ((OSVer_Real_Major = 6) Or (CInt(Split(objFolder.Name, ".")(2)) = OSVer_Real_Build)) Then
      If CInt(Split(objFolder.Name, ".")(0)) > ServicingStack_Major Then
        ServicingStack_Major = CInt(Split(objFolder.Name, ".")(0))
        ServicingStack_Minor = CInt(Split(objFolder.Name, ".")(1))
        ServicingStack_Build = CInt(Split(objFolder.Name, ".")(2))
        ServicingStack_Revis = CInt(Split(objFolder.Name, ".")(3))
      ElseIf (CInt(Split(objFolder.Name, ".")(0)) = ServicingStack_Major) And (CInt(Split(objFolder.Name, ".")(1)) > ServicingStack_Minor) Then
        ServicingStack_Major = CInt(Split(objFolder.Name, ".")(0))
        ServicingStack_Minor = CInt(Split(objFolder.Name, ".")(1))
        ServicingStack_Build = CInt(Split(objFolder.Name, ".")(2))
        ServicingStack_Revis = CInt(Split(objFolder.Name, ".")(3))
      ElseIf (CInt(Split(objFolder.Name, ".")(0)) = ServicingStack_Major) And (CInt(Split(objFolder.Name, ".")(1)) = ServicingStack_Minor) And (CInt(Split(objFolder.Name, ".")(2)) > ServicingStack_Build) Then
        ServicingStack_Major = CInt(Split(objFolder.Name, ".")(0))
        ServicingStack_Minor = CInt(Split(objFolder.Name, ".")(1))
        ServicingStack_Build = CInt(Split(objFolder.Name, ".")(2))
        ServicingStack_Revis = CInt(Split(objFolder.Name, ".")(3))
      ElseIf (CInt(Split(objFolder.Name, ".")(0)) = ServicingStack_Major) And (CInt(Split(objFolder.Name, ".")(1)) = ServicingStack_Minor) And (CInt(Split(objFolder.Name, ".")(2)) = ServicingStack_Build) And (CInt(Split(objFolder.Name, ".")(3)) > ServicingStack_Revis) Then
        ServicingStack_Major = CInt(Split(objFolder.Name, ".")(0))
        ServicingStack_Minor = CInt(Split(objFolder.Name, ".")(1))
        ServicingStack_Build = CInt(Split(objFolder.Name, ".")(2))
        ServicingStack_Revis = CInt(Split(objFolder.Name, ".")(3))
      End If
    End If
  Next
  objCmdFile.WriteLine("set SERVICING_VER_MAJOR=" & ServicingStack_Major)
  objCmdFile.WriteLine("set SERVICING_VER_MINOR=" & ServicingStack_Minor)
  objCmdFile.WriteLine("set SERVICING_VER_BUILD=" & ServicingStack_Build)
  objCmdFile.WriteLine("set SERVICING_VER_REVIS=" & ServicingStack_Revis)
End If

' Determine Windows Update Agent version
If objFileSystem.FileExists(strWUAFileName) Then
  WriteVersionToFile objCmdFile, "WUA_VER", GetFileVersion(objFileSystem, strWUAFileName)
Else
  WriteVersionToFile objCmdFile, "WUA_VER", ""
End If

' Determine Microsoft Installer version
If objFileSystem.FileExists(strMSIFileName) Then
  WriteVersionToFile objCmdFile, "MSI_VER", GetFileVersion(objFileSystem, strMSIFileName)
Else
  WriteVersionToFile objCmdFile, "MSI_VER", ""
End If

' Determine Internet Explorer version
WriteVersionToFile objCmdFile, "IE_VER", RegRead(wshShell, strRegKeyIE & strRegValVersion)

' Determine Microsoft .NET Framework 3.5 SP1 installation state
WriteVersionToFile objCmdFile, "DOTNET35_VER", RegRead(wshShell, strRegKeyDotNet35 & strRegValVersion)
WriteVersionToFile objCmdFile, "DOTNET4_VER", RegRead(wshShell, strRegKeyDotNet4 & strRegValVersion)
objCmdFile.WriteLine("set DOTNET4_RELEASE=" & RegRead(wshShell, strRegKeyDotNet4 & strRegValRelease))

' Determine Windows Management Framework version
If RegExists(wshShell, strRegKeyManagementFramework & strRegValPShVersion) Then
  WriteVersionToFile objCmdFile, "WMF_VER", RegRead(wshShell, strRegKeyManagementFramework & strRegValPShVersion)
Else
  WriteVersionToFile objCmdFile, "WMF_VER", RegRead(wshShell, strRegKeyPowerShell & strRegValPShVersion)
End If

' Determine Microsoft Security Essentials installation state
If RegExists(wshShell, strRegKeyMSSE) Then
  objCmdFile.WriteLine("set MSSE_INSTALLED=1")
Else
  objCmdFile.WriteLine("set MSSE_INSTALLED=0")
End If

' Determine Microsoft Security Essentials' version
WriteVersionToFile objCmdFile, "MSSE_VER", RegRead(wshShell, strRegKeyMSSEUninstall & strRegValDisplayVersion)

' Determine Microsoft Antimalware signatures' version
WriteVersionToFile objCmdFile, "MSSEDEFS_VER", RegRead(wshShell, strRegKeyMSSEDefs & strRegValAVSVersion)

' Determine Network Inspection System definitions' version
WriteVersionToFile objCmdFile, "NISDEFS_VER", RegRead(wshShell, strRegKeyMSSEDefs & strRegValNISSVersion)

' Determine Windows Defender installation state
If RegExists(wshShell, strRegKeyWD) Then
  objCmdFile.WriteLine("set WD_INSTALLED=1")
Else
  objCmdFile.WriteLine("set WD_INSTALLED=0")
End If

' Determine Windows Defender state
If ( (RegRead(wshShell, strRegKeyWD & strRegValDisableAntiSpyware) = "1") _
  Or (RegRead(wshShell, strRegKeyWDPolicy & strRegValDisableAntiSpyware) = "1") ) Then
  objCmdFile.WriteLine("set WD_DISABLED=1")
Else
  objCmdFile.WriteLine("set WD_DISABLED=0")
End If

' Determine Microsoft Antispyware signatures' version
WriteVersionToFile objCmdFile, "WDDEFS_VER", RegRead(wshShell, strRegKeyWDDefs & strRegValASSVersion)

' Determine Remote Desktop Connection (Terminal Services Client) version
If objFileSystem.FileExists(strTSCFileName) Then
  WriteVersionToFile objCmdFile, "TSC_VER", GetFileVersion(objFileSystem, strTSCFileName)
Else
  WriteVersionToFile objCmdFile, "TSC_VER", ""
End If

' Check quality compatibility registry value
If RegExists(wshShell, strRegKeyQualityCompat) Then
  objCmdFile.WriteLine("set QC_SET=1")
Else
  objCmdFile.WriteLine("set QC_SET=0")
End If

' Determine Office version
arrayOfficeNames = Split(strOfficeNames, ",")
arrayOfficeVersions = Split(strRegKeyOfficeInfixes_Version, ",")
For i = 0 To UBound(arrayOfficeNames)
  strOfficeInstallPath = OfficeInstallPath(wshShell, arrayOfficeVersions(i))
  If strOfficeInstallPath <> "" Then
    strMSOFilePath = OfficeMSOFilePath(wshShell, arrayOfficeVersions(i))
    If strMSOFilePath <> "" Then
      If objFileSystem.FileExists(strMSOFilePath) Then
        strOfficeMSOVersion = GetFileVersion(objFileSystem, OfficeMSOFilePath(wshShell, arrayOfficeVersions(i)))
        WriteVersionToFile objCmdFile, UCase(arrayOfficeNames(i)) & "_VER", strOfficeMSOVersion
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_SP_VER=" & OfficeSPVersion(strOfficeMSOVersion))
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_ARCH=" & OfficeArchitecture(wshShell, strOSArchitecture, arrayOfficeVersions(i), strOfficeInstallPath))
        languageCode = OfficeLanguageCode(wshShell, arrayOfficeVersions(i))
        objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_LANG_CODE=0x" & Hex(languageCode))
        If languageCode = 0 Then
          objCmdFile.WriteLine("set " & UCase(arrayOfficeNames(i)) & "_LANG=%OS_LANG%")
        Else
          WriteLanguageToFile objCmdFile, UCase(arrayOfficeNames(i)) & "_LANG", languageCode, False, False
        End If
      End If
    End If
  End If
Next

' Determine installed products (for C++)
Set MSIProducts = ReadStaticFile("StaticUpdateIds-MSIProducts.txt")
For Each strMSIProductId in MSIProducts.Items
  If CheckMSIProduct(Split(strMSIProductId, ",")(0)) = True Then objCmdFile.WriteLine("set " & UCase(Split(strMSIProductId, ",")(0)) & "=1")
Next

objCmdFile.Close

WScript.Quit(0)
