MsgBox Cthuhlu! ; This should never run!
__subMainGUI__: ; Label which creates the main GUI.
{
  DoLogging("-- Creating GUI...")
  Gui 2: New, ,Computer Deployment
 ;----This Section contains the Computer Name label and field.----
  Gui 2: Font, Bold s10
  Gui 2: Add, Text,, Type in Computer Name:
  Gui 2: Font, Norm
  Gui 2: Add, Edit, Uppercase vstrComputerName,
 ;----This section contains a Drop Down Lists for Library locations and computer types.----
  Gui 2: Font, Bold s10
  Gui 2: Add, Text, Section, Select Branch:
  Gui 2: Font, Norm
  Gui 2: Add, DDL, vstrLocation, Branch...||ESA|MRL|MOM|KL|AFL|EV|JOH|ND
  Gui 2: Font, Bold s10
  Gui 2: Add, Text, ys, Select computer type:
  Gui 2: Font, Norm
  Gui 2: Add, DDL, vstrComputerRole, Computer...||Office|Frontline|Patron|Catalog
 ;----This section contains Checkbox toggles.----
  Gui 2: Font, Bold s10
  Gui 2: Add, Checkbox, Section xm vbIsWireless, This is a Wireless computer. ; Wireless check toggle.
  Gui 2: Add, Checkbox, vbIsVerbose, Use Verbose logging. ; Verbose logging toggle.
  Gui 2: Font, Norm
 ;----This Section contains Submit and Exit Buttons.----
  Gui 2: Add, Button, Section xm+50 gButtonStart w100 Default, Start
  Gui 2: Add, Button, yp xp+110 gButtonExit w100, Exit
  Gui 2: Show
  Return
}
MsgBox Cthuhlu! ; This should never run!
ButtonStart: ; Label for Install button. Takes user input and prepares to run installers, confirming first. (WORKS)
{
  Gui, Submit, NoHide
  Gosub __subConfirmGUI__
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subConfirmGUI__: ; confirms that selections are correct before continuing. 
{
  Gui +OwnDialogs
  If (bIsWireless == 1)
    WirelessText := "This is a Wireless computer."
  else
    WirelessText := "This is an Ethernet computer."
    
  If (strComputerRole == "Office")
    TypeText := "This will install:`n- Sierra`n- Office for staff computer`n- Staff printers"
  If (strComputerRole == "Frontline")
    TypeText := "This will install:`n- Sierra`n- Offline Circulation`n- Staff printers`n- PC Reservation Reservation Station`n- Envisionware Print Release station`n- Auto Logon configuration for staff"
  If (strComputerRole == "Patron")
    TypeText := "This will install:`n- Office for patron computer`n- Envisionware PC Reservation client`n- Envisionware LPTOne printer client`n- PatronAdminPanel`n- Auto Logon configuration for patrons"  
  If (strComputerRole == "Catalog")
    TypeText := "This will install:`n- EncoreAlways`n- Auto Logon configuration for catalogs"
    
  If (strComputerName == "")
  {
    SoundPlay *48
    MsgBox, 48, No Named, Please type in a name for this computer.
    Return
  }
  If (StrLen(strComputerName) > 15)
  {
    SoundPlay *48
    MsgBox, 48, Long Name, The computer name is too long for NETBIOS compatibility.`nPlease input a name that is fifteen characters or less.
    Return
  }
  If (strLocation == "Location...")
  {
    SoundPlay *48
    MsgBox, 48, No Location, Please select a location for this computer.
    Return
  }
  If (strComputerRole == "Role...")
  {
    SoundPlay *48  
    MsgBox, 48, No Role, Please select a role for this computer.
    Return
  }
  SoundPlay *32
  MsgBox, 36, Confirm, Please confirm the following:`nName: %strComputerName%`nLocation: %strLocation%`nRole: %strComputerRole%`n%WirelessText% `n%TypeText% `nIs this correct?
  IfMsgBox, Yes
  {
    DoLogging("--   User has selected:")
    DoLogging("--")
    DoLogging("--                Name: " strComputerName)
    DoLogging("--            Location: " strLocation)
    DoLogging("--                Role: " strComputerRole)
    DoLogging("--             Network: " WirelessText)
    Gosub __main__
    MsgBox Cthuhlu! ; This should never run!
  }
  MsgBox Cthuhlu! ; This should never run!
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subCreateOUPath__:
{
  DoLogging("ii Creating distinguished name for domain join...")
  Try {
    If (strComputerRole == "Office")
      strFinalOUPath := "OU=Offices,OU=Systems,OU=" . strLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
    If (strComputerRole == "Frontline")
      strFinalOUPath := "OU=Frontline,OU=Systems,OU=" . strLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
    If (strComputerRole == "Frontline" and bIsWireless == 1) ;Staff Laptop
      strFinalOUPath := "OU=Laptops,OU=Systems,OU=" . strLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
    If (strComputerRole == "Patron")
      strFinalOUPath := "OU=" . strLocation . ",OU=Patron,OU=DCLS,DC=dcls,DC=org"  
    If (strComputerRole == "Patron" and bIsWireless == 1) ;Patron Laptop
      strFinalOUPath := "OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
    If (strComputerRole == "Catalog")
      strFinalOUPath := "OU=Catalog,OU=Patron,OU=DCLS,DC=dcls,DC=org"
    If (strComputerRole == "Self Checkout")
      strFinalOUPath := "OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
    If (strComputerRole == "LPT Kiosk")
      strFinalOUPath := "OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
    DoLogging("ii Distinguished Name: "strFinalOUPath)
  } Catch {
    DoLogging("!! Failure to create distinguished name!")
    vNumErrors += 1
  }
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subDefaultTasks__:
{
  DoLogging(" ")
  DoLogging("__ __subDefaultTasks__")
  DoLogging("ii wireless profile (optional) and Spiceworks agent, activation, domain join, Vipre install, LogMeIn...")
  arrDefaultTaskList := []
  If (bIsWireless == 1)
  {
    arrDefaultTaskList.Insert("""netsh wlan add profile filename="A_ScriptDir . "\Resources\WirelessProfile-dclsstaff.xml user=all""") ; Install wireless profile
    arrDefaultTaskList.Insert("PING -n 4 -w 4000 8.8.8.8") ; Wait between 4 and 16 seconds for the network.
    arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY=""" strSpiceworksKey """ SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile Agent
  }
  ; ================================================================================
  ; WE DON'T KNOW IF WE NEED THIS YET
  ;arrDefaultTaskList.Insert("%ComSpec% /c cscript //B c:\windows\system32\slmgr.vbs /ipk " strActivationKey) ; Install activation key.
  ;arrDefaultTaskList.Insert("cscript //B c:\windows\system32\slmgr.vbs /ato") ; Activate Windows.
  ; ================================================================================
  arrDefaultTaskList.Insert("powershell.exe -Command $pass = ConvertTo-SecureString -String \"""strDomainPassword . "\"" -AsPlainText -Force; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -OUPath '" strFinalOUPath "'" -NewName """ strComputerName """) ; Join domain, Move OU.
  arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. 
  arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn.
  iTotalErrors += DoExternalTasks(arrDefaultTaskList, bIsVerbose)
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subSpecificTasks__:
{
  DoLogging(" ")
  DoLogging("__ __subSpecificTasks__")
  DoLogging("ii Role-Specific Configuration for: " . strComputerRole . "...")
  strEwareServer := arrLPTOneServers[strLocation]
  arrSpecificTaskList := []
  If (strComputerRole == "Office")
  {
    arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s /UNILOG+:C:\Deployment\robocopy_Sierra.log") ; Install Sierra
    arrSpecificTaskList.Insert(""A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml") ; Install Office 365
    ;arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal. not necessary for office?
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s /UNILOG+:C:\Deployment\robocopy_Printers.log") ; Copy links to staff printers.
    FileCreateShortcut, \\Contentserver\bucket, C:\Users\Public\Desktop\Bucket.lnk,  , , , C:\Windows\system32\imageres.dll, , 138
    FileCreateShortcut, https://portal.adp.com/public/index.htm, C:\Users\Public\Desktop\ADP.lnk,  , , , I:\Deployment\Resources\Shortcuts\adp.ico, , 1
    FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe, C:\Users\Public\Desktop\Sierra Desktop App.lnk, C:\Sierra Desktop App, , , I:\Deployment\Resources\Shortcuts\sierra.ico, , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE, C:\Users\Default\Desktop\Word 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE, C:\Users\Default\Desktop\Excel 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\POWERPNT.EXE, C:\Users\Default\Desktop\PowerPoint 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\MSPUB.EXE, C:\Users\Default\Desktop\Publisher 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE, C:\Users\Default\Desktop\Outlook 2016.lnk, , , , , , 1
    
  }
  If (strComputerRole == "Frontline")
  {
    arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s /UNILOG+:C:\Deployment\robocopy_Sierra.log") ; Sierra files.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s /UNILOG+:C:\Deployment\robocopy_Millennium.log") ;  Offline circ files.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s /UNILOG+:C:\Deployment\robocopy_Shortcuts.log") ; Copy links to staff printers.
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_PCReservationStation.exe /S") ; Install Reservation Station
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources ""C:\Program Files (x86)\EnvisionWare"" envisionware.lic /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")
    FileCreateShortcut, \\Contentserver\bucket, C:\Users\Public\Desktop\Bucket.lnk,  , , , C:\Windows\system32\imageres.dll, , 138
    FileCreateShortcut, https://portal.adp.com/public/index.htm, C:\Users\Public\Desktop\ADP.lnk,  , , , I:\Deployment\Resources\Shortcuts\adp.ico, , 1
    FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe, C:\Users\Public\Desktop\Sierra Desktop App.lnk, C:\Sierra Desktop App, , , I:\Deployment\Resources\Shortcuts\sierra.ico, , 1
    FileCreateShortcut, C:\Millennium\Offline\offlinecirc.exe, C:\Users\Public\Desktop\Offline Circulation.lnk, C:\Millenium\Offline, , , C:\Millennium\Offline\offlinecirc.ico, , 1
    FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\lptone\lptprt\lptPRT.exe, C:\Users\Public\Desktop\LPTOne Print Release Terminal.lnk, C:\Program Files (x86)\EnvisionWare\lptone\lptprt,  -host:%strEwareServer% -runmode:staff, , C:\Program Files (x86)\EnvisionWare\lptone\lptprt\lptPRT.exe, , 1
    FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\PC Reservation\Reservation Station\PCRes_RS.exe, C:\Users\Public\Desktop\PCRes Reservation Station.lnk, C:\Program Files (x86)\EnvisionWare\PC Reservation\Reservation Station, -host:%strEwareServer%, , , , 1
  }
  If (strComputerRole == "Patron")
  {
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s /UNILOG+:C:\Deployment\robocopy_PatronAdminPanel.log") ; Copy PatronAdminPanel.
    arrSpecificTaskList.Insert(""A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml") ; Office 365 for patrons.
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\_LPTOneClient.exe /S -jqe.host="strEwareServer) ; Patron printers.
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\_PCReservationClient.exe /S -ip="strEwareServer . " -tcpport=9432") ; Envisionware Client.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources ""C:\Program Files (x86)\EnvisionWare"" envisionware.lic /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE, C:\Users\Default\Desktop\Word 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE, C:\Users\Default\Desktop\Excel 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\POWERPNT.EXE, C:\Users\Default\Desktop\PowerPoint 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\MSPUB.EXE, C:\Users\Default\Desktop\Publisher 2016.lnk, , , , , , 1
  }
  If (strComputerRole == "Catalog")
  {
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s /UNILOG+:C:\Deployment\robocopy.log")  ; EncoreAlways script.
  }
  iTotalErrors += DoExternalTasks(arrSpecificTaskList, bIsVerbose)
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subAddAutoLogon__:
{
  DoLogging(" ")
  DoLogging("__ __subAddAutoLogon__")
  DoLogging("ii create AutoLogon profile for certain roles...")
  arrAddAutoLogonList := []
  If (strComputerRole == "Office") ; because Office machines don't auto-logon
  {
    Return
  }
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "1"])
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultDomainName", "dcls.org"])
  If (strComputerRole == "Frontline")
  {
    strAutoLogonUser := arrAutoLogonUser[strLocation]
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "dcls\" . strAutoLogonUser])
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strALPWStaff])
  }
  If (strComputerRole == "Patron")
  {  
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "dcls\" . %strLocation% . "-PATRON"])
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strALPWPatron])
  }
  If (strComputerRole == "Catalog") 
  {
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "dcls\esacatalog"])
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strALPWCatalog])
  }
  iTotalErrors += DoInternalTasks(arrAddAutoLogonList, bIsVerbose)
  Return
}
MsgBox Cthuhlu! ; This should never run!
__subCleanupJobs__:
{  
  DoLogging(" ")
  DoLogging("__ __subCleanupJobs__")
  DoLogging("ii Registry and file cleanup...")
  arrCleanupJobsList := []
  arrCleanupJobsList.Insert(["RegWrite", "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui", "EnableSystray", "0"])
  arrCleanupJobsList.Insert(["FileDelete", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk"])
  arrCleanupJobsList.Insert(["FileDelete", "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk"])
  If (strComputerRole == "Patron")
  {
    arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run", "PatronAdminPanel", """C:\PatronAdminPanel\PatronAdminPanel.exe"""])
    iTotalErrors += ClosePCReservation(5)
  }
  If (strComputerRole == "Catalog")
  {
    arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run", "EncoreAways", """C:\EncoreAlways\EncoreAlways.exe"""])
  }
  arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete", "%comspec% /c RD /S /Q C:\IT\Deployment"])
  iTotalErrors += DoInternalTasks(arrCleanupJobsList, bIsVerbose)
  Return
} 
MsgBox Cthuhlu! ; This should never run!
__subFinishAndExit__:
{
  If (iTotalErrors > 0) ; Final check for errors and closes program.
  {
    DoLogging("!! Configuration INCOMPLETE! There were " iTotalErrors . " errors with this run.")
    SoundPlay *16
    MsgBox, 16, Configuration INCOMPLETE,  There were %iTotalErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
    ExitApp, 2 ; indicates errors
  } Else {
    DoLogging("== Configuration Successful! There were " iTotalErrors . " errors with this program.")
    SoundPlay *64
    MsgBox, 64, Configuration Successful,  Configuration completed successfully! The computer will now reboot., 10 ; MsgBox times out after 10 seconds.
    Shutdown, 2 ; Reboots computer.
    ExitApp, 0 ; indicates success
  }
}
MsgBox Cthuhlu! ; This should never run!
GuiClose: 
2GuiClose: ; I am annoyed by the lack of ExitReasons
ButtonExit:
{
  ExitApp, 1
}
MsgBox Cthuhlu! ; This should never run!