__subDefaultTasks__:
{
  Log("__ __subDefaultTasks__")
  Gosub __subCreateOUPath__
  arrDefaultTaskList := []
  If(bIsWireless == 1)
  {
    arrDefaultTaskList.Insert("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\WirelessProfile.xml user=all") ; Install Wireless Profile
    arrDefaultTaskList.Insert("cmd.exe /c timeout 6") ; Wait for profile to update.
    arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY=""" strSpiceworksKey """ SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
  }
  arrDefaultTaskList.Insert("cscript //B c:\windows\system32\slmgr.vbs /ipk " strActivationKey) ; Copy activation key.
  arrDefaultTaskList.Insert("cscript //B c:\windows\system32\slmgr.vbs /ato") ; Activate Windows.
  arrDefaultTaskList.Insert("powershell.exe -NoExit -Command $pass = ConvertTo-SecureString -String \"""strDomainPassword . "\"" -AsPlainText -Force; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -NewName """ vComputerName """ -OUPath '" vOUPath "'") ; Join domain, Move OU.
  arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. (WORKS) 
  arrDefaultTaskList.Insert("msiexec.exe /i "A_ScriptDir . "\Resources\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn. (WORKS)
  DoTasks(arrDefaultTaskList)
  Return
}

__subSpecificTasks__:
{
  Log("__ __subSpecificTasks__")
  ;Log("-- Role-Specific Configuration for: " . strComputerType . "")
	arrSpecificTaskList := []
	If(strComputerType == "Office")
	{
		arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		arrSpecificTaskList.Insert("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml") ; Office 365 for staff.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		;     <-|
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;     | 
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*") ;   |- Copy Office shortcuts to Start
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	;   |
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Outlook*")	;   <-|
		arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
	}
	If(strComputerType == "Frontline")
	{
		arrSpecificTaskList.Insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s") ;  Offline circ files.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Offline Circ shortcut.	
		arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
		arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Envisionware\_PCReservationStation.exe /S") ; Install Reservation Station
	}
	If(strComputerType == "Patron")
	{
		vEwareServer := arrLPTOneServers[strLocation]
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s") ; Copy PatronAdminPanel.
		arrSpecificTaskList.Insert("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml") ; Office 365 for patrons.
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		; <-|
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;   |- Copy Office shortcuts to Start
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")	;   |
		arrSpecificTaskList.Insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	; <-|
		arrSpecificTaskList.Insert("robocopy C:\Users\Public\Desktop C:\ProgramData\Microsoft\Windows\Start Menu /s") ; Update Start menu.
		arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Envisionware\_LPTOneClient.exe /S -jqe.host="vEwareServer) ; Patron printers.
		arrSpecificTaskList.Insert(A_ScriptDir . "\Resources\Envisionware\_PCReservationClient.exe /S -ip="vEwareServer . " -tcpport=9432") ; Envisionware Client.
	}
	If(strComputerType == "Catalog")
	{
		arrSpecificTaskList.Insert("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s")	; EncoreAlways script.
	}
  DoTasks(arrSpecificTaskList)
  Return
}

__subAddAutoLogon__:
{
  Log("__ __subAddAutoLogon__")
  If(strComputerType == "Office") ; because Office machines don't auto-logon
  {
    Return
  }
  ;Log("-- Configuring Auto-Logon")
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, AutoAdminLogon, 1
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultDomainName, dcls.org
	If(Computer == "Frontline")
	{
		strAutoLogonUser := arrAutoLogonUser[strLocation]
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%strAutoLogon%
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %strALPWStaff%
    Return
	}
	If(Computer == "Patron")
	{	
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%strLocation%-PATRON
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %strALPWPatron%
		Return
	}
	If(Computer == "Catalog") 
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\esacatalog
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %strALPWCatalog%
		Return
	}
	Log("!! Failure to create auto logon profile!")
	iTotalErrors += 1
	Return
}
  
__subCleanupJobs__:
{  
  Log("__ __subCleanupJobs__")
  Log("-- Registry and file cleanup...")
  Try {
  RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui, EnableSystray, 0
  FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk
  FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk
  } Catch {
    iTotalErrors += 1
    Log("!! Error attempting LogMeIn cleanup!")
  }
  If(strComputerType == "Patron")
  {
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, PatronAdminPanel, ""C:\PatronAdminPanel\PatronAdminPanel.exe"" ; Set PatronAdminPanel auto-start.
    Sleep 15000
    Gosub ClosePCReservation
  }
  If(strComputerType == "Catalog")
  {
    RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, EncoreAways, ""C:\EncoreAlways\EncoreAlways.exe"" ; Set EncoreAways auto-start
  }
} 
  
;CreateOUPath(Wireless, Location, Computer) ; Creates a distiguished name for moving to OU.
__subCreateOUPath__:
{
	If(Computer == "Office")
		Return "OU=Offices,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(Computer == "Frontline")
		Return "OU=Frontline,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(Computer == "Frontline" and Wireless == 1) ;Staff Laptop
		Return "OU=Laptops,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(Computer == "Patron")
		Return "OU=" . Location . ",OU=Patron,OU=DCLS,DC=dcls,DC=org"	
	If(Computer == "Patron" and Wireless == 1) ;Patron Laptop
		Return "OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	If(Computer == "Catalog")
		Return "OU=Catalog,OU=Patron,OU=DCLS,DC=dcls,DC=org"
	If(Computer == "Self Checkout")
		Return "OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	If(Computer == "LPT Kiosk")
		Return "OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	Log("!! Failure to create distinguished name!")
	vNumErrors += 1
	Return
}
  
ButtonExit: ; Label for Exit button. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

ButtonStart: ; Label for Install button. Takes user input and prepares to run installers, confirming first. (WORKS)
{
	Gui, Submit, NoHide
	ConfirmationWindow(bIsWireless, strLocation, strComputerType, vComputerName)
	Return
}	

ClosePCReservation: ; Label that closes Envisionware window after its installation.
{
	CoordMode, Mouse, Screen
	MouseMove, (20), (A_ScreenHeight - 20)
	Sleep, 250
	Send, {Ctrl Down}{Click}{Ctrl up}
	Sleep, 250
	Send envisionware{enter}{enter}
	Return
}

CreateOptionsWindow: ; Label which creates the main GUI.
{
	Log("-- Creating GUI...")
  Gui 2: New, ,Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text,, Type in Computer Name:
	Gui 2: Font, Norm
	Gui 2: Add, Edit, Uppercase vvComputerName,
;----This section contains a Drop Down Lists for Library locations and computer types.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text, Section, Select Branch:
	Gui 2: Font, Norm
	Gui 2: Add, DDL, vstrLocation, Branch...||ESA|MRL|MOM|KL|AFL|EV|JOH|ND
	Gui 2: Font, Bold s10
	Gui 2: Add, Text, ys, Select computer type:
	Gui 2: Font, Norm
	Gui 2: Add, DDL, vstrComputerType, Computer...||Office|Frontline|Patron|Catalog
;----This section contains Checkbox toggles.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Checkbox, Section xm vbIsWireless, This is a Wireless computer. ; Wireless check toggle.
	Gui 2: Add, Checkbox, vvIsVerbose, Use Verbose logging. ; Verbose logging toggle.
	Gui 2: Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui 2: Add, Button, Section xm+50 gButtonStart w100 Default, Start
	Gui 2: Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui 2: Show
	Return
}

GuiClose: ; Label for default close functions, prompts confirmation screen. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

2GuiClose: ; Label for default close functions in second GUI, prompts confirmation screen. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}