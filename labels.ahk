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
  Gui 2: Add, DDL, vstrLocation, Branch...||ESA|MRL|MOM|KL|AFL|EV|JOH|ND|VAN
  Gui 2: Font, Bold s10
  Gui 2: Add, Text, ys, Select computer type:
  Gui 2: Font, Norm
  Gui 2: Add, DDL, vstrComputerRole, Computer...||Office|Frontline|Patron|Catalog|Self-Check
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

  If ((strComputerRole != "Patron") And (strLocation == "VAN"))
  {
    SoundPlay *48
    MsgBox, 48, Wrong Van, Only Patron computers can go on the Van!
    Return
  } 
  If (strComputerName == "")
  {
    SoundPlay *48
    MsgBox, 48, No Name, Please type in a name for this computer.
    Return
  }
  If (RegExMatch(strComputerName, ValidHostnameRegex) == 0)
  {
    SoundPlay *48
    MsgBox, 48, Bad Name, The computer name failed NETBIOS compatibility check.`nIt is either longer than 15 characters, or contains disallowed characters.`nTry a different name.
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
  If (bIsWireless == 1)
    WirelessText := "This is a Wireless computer."
  else
    WirelessText := "This is an Ethernet computer."
  If (strComputerRole == "Office")
    TypeText := "This will install:`n- Sierra`n- Office for staff computer`n- Staff printers"
  If (strComputerRole == "Frontline")
    TypeText := "This will install:`n- Sierra`n- Offline Circulation`n- Staff printers`n- PC Reservation Reservation Station`n- Envisionware Print Release station`n- Auto Logon configuration for staff"
  If ((strComputerRole == "Patron") And (strLocation != "VAN"))
    TypeText := "This will install:`n- Office for patron computer`n- Envisionware PC Reservation client`n- Envisionware LPTOne printer client`n- PatronAdminPanel`n- Auto Logon configuration for patrons"  
  If ((strComputerRole == "Patron") And (strLocation == "VAN"))
    TypeText := "This will install:`n- Office for patron computer`n- PatronAdminPanel`n- Auto Logon configuration for patrons"  
  If (strComputerRole == "Catalog")
    TypeText := "This will install:`n- EncoreAlways`n- Auto Logon configuration for catalogs"
  SoundPlay *32
  MsgBox, 36, Confirm, Please confirm the following:`nName: %strComputerName%`nLocation: %strLocation%`nRole: %strComputerRole%`n%WirelessText% `n%TypeText% `nIs this correct?
  IfMsgBox, Yes
  {
    GuiControl 2: Disable, strComputerName
    GuiControl 2: Disable, strLocation
    GuiControl 2: Disable, strComputerRole
    GuiControl 2: Disable, bIsWireless
    GuiControl 2: Disable, bIsVerbose
    GuiControl 2: Disable, Start
    DoLogging("--   User has selected:")
    DoLogging("--")
    DoLogging("--                Name: " strComputerName)
    DoLogging("--            Location: " strLocation)
    DoLogging("--                Role: " strComputerRole)
    DoLogging("--             Network: " WirelessText)
    GoSub __subWriteXML__
    Gosub __main__
    MsgBox Cthuhlu! ; This should never run!
  }
  Return
}
MsgBox Cthuhlu! ; This should never run!


__subWriteXML__:
{
  ;This takes the user input and saves it to an XML document so we can save it
  data := new KeyValStore("DeploymentInfo.xml")
  data.Set("ComputerName", strComputerName)
  data.Set("ComputerLocation", strLocation)
  data.Set("ComputerRole", strcomputerRole)
  data.Set("WirelessState", bIsWireless)
  data.Set("VerboseState", bIsVerbose)
  return
}

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


__subWirelessTasks__:
{
  DoLogging(" ")
  DoLogging("__ __subWirelessTasks__")
  DoLogging("ii import wireless profile, install Spiceworks agent, then wait for a connection...")
  arrWirelessTaskList := []
  arrWirelessTaskList.Insert("netsh wlan add profile filename`="A_ScriptDir . "\Resources\WirelessProfile-dclsstaff.xml user`=all") ; Install wireless profile
  arrWirelessTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_Spiceworks.msi SPICEWORKS_SERVER`=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY`=""" strSpiceworksKey """ SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile Agent
  iTotalErrors += DoExternalTasks(arrWirelessTaskList, bIsVerbose)
  DoLogging("ii sleep for 3 seconds before testing wireless")
  Sleep 3000 ; for some odd reason, WaitForPing(30) seems to fail after only 15 pings. Here's a minimum time to wait to possibly allow the adapter to "catch up".
  WaitForPing(30) ; up to 30 seconds, which is a long time I know, but it's not like we're staring at the console. It should only take like 5 seconds anyways.
  Return
}
MsgBox Cthuhlu! ; This should never run!


__subDefaultTasks__:
{
  DoLogging(" ")
  DoLogging("__ __subDefaultTasks__")
  arrDefaultTaskList := []
  ; TRUST ME, THIS IS THE ONLY WAY
  DoLogging("Renaming the computer.")
  arrDefaultTaskList.Insert("powershell.exe -Command ""& { `$pass `= ConvertTo-SecureString -String "strDomainPassword . " -AsPlainText -Force; `$mycred `= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList unattend,`$pass; Rename-Computer -NewName '"strComputerName . "' -DomainCredential `$mycred -Force -PassThru }""")
  
  
  
  ;DCLS no longer Viper and it should no longer be installed on our new computers
  ;arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus.
  
  DoLogging("Copy links to staff printers.")
  arrDefaultTaskList.Insert("powershell.exe -Command ""& {Register-ScheduledTask -Xml (get-content '"A_ScriptDir . "\Configure-ImageTask.xml' | out-string) -Taskname RestartConfigureImage}""")
  arrDefaultTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Icons C:\Icons /s /UNILOG+:C:\Deployment\robocopy_Icons.log") ; Copy links to staff printers.
  iTotalErrors += DoExternalTasks(arrDefaultTaskList, bIsVerbose)
  Return
}
MsgBox Cthuhlu! ; This should never run!


__subSpecificTasks__:
{
  DoLogging(" ")
  DoLogging("__ __subSpecificTasks__")
  DoLogging("ii Role-Specific Configuration for: " . strComputerRole . "...")
  IniRead, strEwareServer , %A_WorkingDir%\Resources\Servers.ini, Servers, %strLocation%
  DoLogging("Targetting Eware Server " strEwareServer)
  arrSpecificTaskList := []
  If (strComputerRole == "Office")
  {
    arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s /UNILOG+:C:\Deployment\robocopy_Sierra.log") ; Install Sierra
    arrSpecificTaskList.Insert(""A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml") ; Install Office 365
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Printers C:\Users\Default\Desktop\Printers /s /UNILOG+:C:\Deployment\robocopy_Printers.log") ; Copy links to staff printers.
    FileCreateShortcut, \\contentserver\bucket, C:\Users\Public\Desktop\Bucket.lnk,  , , , C:\Windows\system32\imageres.dll, , 138
    FileCreateShortcut, https://portal.adp.com/public/index.htm, C:\Users\Public\Desktop\ADP.lnk,  , , , C:\Icons\adp.ico, , 1
    FileCreateShortcut, https://spiceworks.dcls.org/portal, C:\Users\Public\Desktop\Helpdesk Portal.lnk,  , , , C:\Icons\helpdeskportal.ico, , 1
    FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe, C:\Users\Public\Desktop\Sierra Desktop App.lnk, C:\Sierra Desktop App, , , C:\Icons\sierra.ico, , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE, C:\Users\Default\Desktop\Word 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE, C:\Users\Default\Desktop\Excel 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\POWERPNT.EXE, C:\Users\Default\Desktop\PowerPoint 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\MSPUB.EXE, C:\Users\Default\Desktop\Publisher 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE, C:\Users\Default\Desktop\Outlook 2016.lnk, , , , , , 1
    FileCreateShortcut, c:\windows\explorer.exe, :\Users\Default\Desktop\File Explorer.lnk, , , , , , 1
    
  }
  If (strComputerRole == "Frontline")
  {
    arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s /UNILOG+:C:\Deployment\robocopy_Sierra.log") ; Sierra files.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s /UNILOG+:C:\Deployment\robocopy_Millennium.log") ;  Offline circ files.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Printers C:\Users\Default\Desktop\Printers /s /UNILOG+:C:\Deployment\robocopy_Shortcuts.log") ; Copy links to staff printers.
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_PCReservationStation.exe /S") ; Install Reservation Station
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\EnvisionWareConfigs\"strLocation . "\ ""C:\ProgramData\EnvisionWare\PC Reservation\Client Module\config"" /mov") ;specifies ip and port of eware server
    arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources ""C:\Program Files (x86)\EnvisionWare"" envisionware.lic /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")
    FileCreateShortcut, \\Contentserver\bucket, C:\Users\Public\Desktop\Bucket.lnk,  , , , C:\Windows\system32\imageres.dll, , 138
    FileCreateShortcut, https://portal.adp.com/public/index.htm, C:\Users\Public\Desktop\ADP.lnk,  , , , C:\Icons\adp.ico, , 1
    FileCreateShortcut, https://spiceworks.dcls.org/portal, C:\Users\Public\Desktop\Helpdesk Portal.lnk,  , , , C:\Icons\helpdeskportal.ico, , 1
    FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe, C:\Users\Public\Desktop\Sierra Desktop App.lnk, C:\Sierra Desktop App, , , C:\Icons\sierra.ico, , 1
    FileCreateShortcut, C:\Millennium\Offline\offlinecirc.exe, C:\Users\Public\Desktop\Offline Circulation.lnk, C:\Millenium\Offline, , , C:\Millennium\Offline\offlinecirc.ico, , 1
    ;I Don't think either or these lines are needed because the install seems to be adding its own icon creating double icons.
    ;FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\lptone\lptprt\lptPRT.exe, C:\Users\Public\Desktop\LPTOne Print Release Terminal.lnk, C:\Program Files (x86)\EnvisionWare\lptone\lptprt,  -host:%strEwareServer% -runmode:staff, , C:\Program Files (x86)\EnvisionWare\lptone\lptprt\lptPRT.exe, , 1
    ;FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\PC Reservation\Reservation Station\PCRes_RS.exe, C:\Users\Public\Desktop\PCRes Reservation Station.lnk, C:\Program Files (x86)\EnvisionWare\PC Reservation\Reservation Station, -host:%strEwareServer%, , , , 1
    FileCreateShortcut, c:\windows\explorer.exe, :\Users\Default\Desktop\File Explorer.lnk, , , , , , 1
  }
  If (strComputerRole == "Patron")
  {
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s /UNILOG+:C:\Deployment\robocopy_PatronAdminPanel.log") ; Copy PatronAdminPanel.
    ;GITHUB ISSUE #22; Patrons should not be installing 365 they should be installing Office 2016
    arrSpecificTaskList.Insert(""A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml") ; Office 365 for patrons.
    If (strLocation != "VAN")
    {
      arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_PCReservationClient.exe /S") ; Envisionware Client.
      ;This is the actual command that specifies the IP and port
      arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\EnvisionWareConfigs\"strLocation . "\ ""C:\ProgramData\EnvisionWare\PC Reservation\Client Module\config"" /mov")
      arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Installers\_LPTOneClient.exe /S -jqe.host`="strEwareServer) ; Patron printers.
    }
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources ""C:\Program Files (x86)\EnvisionWare"" envisionware.lic /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.EXE, C:\Users\Public\Desktop\Word 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\EXCEL.EXE, C:\Users\Public\Desktop\Excel 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\POWERPNT.EXE, C:\Users\Public\Desktop\PowerPoint 2016.lnk, , , , , , 1
    FileCreateShortcut, C:\Program Files (x86)\Microsoft Office\root\Office16\MSPUB.EXE, C:\Users\Public\Desktop\Publisher 2016.lnk, , , , , , 1
  }
  If (strComputerRole == "Catalog")
  {
    arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s /UNILOG+:C:\Deployment\robocopy.log")  ; EncoreAlways script.
  }
  iTotalErrors += DoExternalTasks(arrSpecificTaskList, bIsVerbose)
  ;Envisionware does not actually install until this point so after it isntalls we can go ahead and move the config file
  ;FileMove, \Resources\EnvisionwareConfigs\%strLocation%\pcrClient.ewp, C:\ProgramData\EnvisionWare\PC Reservation\Client Module\config , 1
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
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "dcls\" . strLocation . "-PATRON"])
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strALPWPatron])
  }
  If (strComputerRole == "Catalog") 
  {
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName", "dcls\esacatalog"])
    arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strALPWCatalog])
  }
  arrAddAutoLogonList.Insert(["RegDelete", "HKEY_LOCAL_MACHINE", "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoLogonCount"])
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
  ;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete1", "cmd.exe /c RD /S /Q C:\Deployment"])
  ;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete2", "cmd.exe /c RD /S /Q C:\Deployment > c:\00_runonce.log"])
  arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete", "cmd.exe /c Robocopy.exe C:\Deployment\Resources\Empty C:\Deployment /MIR /XF *.log /UNILOG+:c:\Deployment\robocopy_selfdelete.log"])
  ;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete4", "cmd.exe /c RD /S /Q C:\Deployment > c:\02_runonce_on_empty.log"])
  ;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete5", "powershell.exe -Command ""& { Remove-Item -Path C:\Deployment -Recurse -Force | Out-File C:\03_powershell_remove-item.log }"" "])
  ;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete6", "cmd.exe /c c:\selfdelete.cmd > c:\selfdelete.log"])
  iTotalErrors += DoInternalTasks(arrCleanupJobsList, bIsVerbose)

  ;Deleting tasks from Windows task scheduler is an external task
  arrExternalCleanupJobs := []
  arrExternalCleanupJobs.insert("powershell.exe -Command ""& { Unregister-ScheduledTask -TaskName RestartConfigureImage -Confirm:$false }""")
  iTotalErrors += DoExternalTasks(arrExternalCleanupJobs, bIsVerbose)

  Return
} 


__subReboot__:
{
  ;We have the user's input saved to DeploymentInfo.xml and will use that after
  ; the reboot to continue running this with the same configuration
  ; but first we need to create an autologon key with admin credentials
  ; to ensure it logs back in after reboot
  arrAddAutoLogonList := []
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "1"])
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultDomainName",  ".\"])
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultUserName",  strAdminUsername])
  arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultPassword", strAdminPassword])
  arrAddAutoLogonList.Insert(["RegWrite", "REG_DWORD", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoLogonCount", 0x00000001])
  iTotalErrors += DoInternalTasks(arrAddAutoLogonList, bIsVerbose)

  ;We will use an exported task to import a task to the windows task scheduler
  arrDefaultTaskList.Insert("powershell.exe -Command ""& { `$pass `= ConvertTo-SecureString -String "strDomainPassword . " -AsPlainText -Force; `$mycred `= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList unattend,`$pass; Rename-Computer -NewName '"strComputerName . "' -DomainCredential `$mycred -Force -PassThru }""")
  Run %comspec% /c "shutdown.exe /r /t 3" ;Restarts after 3 seconds
  Return
}
MsgBox Cthuhlu! ; This should never run!

__subLoadUserInput__:
{
  ;We need to load the data from the xml document that was created before the
  ;reboot in order to maintain the user's input.
  DoLogging(" Loading Saved input from the User.")
  data := new KeyValStore("DeploymentInfo.xml")
  strComputerName := data.Get("ComputerName")
  DoLogging("strComputerName loaded to " strComputerName)
  strLocation := data.Get("ComputerLocation")
  DoLogging("strComputerLocation loaded to " strLocation)
  strComputerRole := data.Get("ComputerRole")
  DoLogging("strComputerRole loaded to " strComputerRole)
  bIsWireless := data.Get("WirelessState")
  DoLogging("bIsWireless loaded to " bIsWireless)
  bIsVerbose := data.Get("VerboseState")
  DoLogging("bIsVerbose loaded to " bIsVerbose)
  return
}

__subDefaultAfterReboot__:
{
  DoLogging("Installing LogMeIn")
  arrDefaultTaskListAR := []
  DoLogging("Joining the Domain.")
  arrDefaultTaskListAR.Insert("powershell.exe -Command ""& { Start-Sleep -s 3; `$pass `= ConvertTo-SecureString -String "strDomainPassword . " -AsPlainText -Force; `$mycred `= New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList unattend,`$pass; Add-Computer  -DomainName dcls.org -Credential `$mycred -OUPath '"strFinalOUPath . "' -Force -PassThru }""")
  arrDefaultTaskListAR.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn.
  iTotalErrors += DoExternalTasks(arrDefaultTaskListAR, bIsVerbose)
  Return
}
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
    MsgBox, 1, Configuration Successful,  Configuration completed successfully!`nRebooting in 10 seconds unless cancelled..., 10 ; MsgBox times out after 10 seconds.
    IfMsgBox, Cancel
      ExitApp, 0
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