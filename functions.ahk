AddAutoLogon(BranchNumber, TypeNumber, LogonPass) ; Adds registry keys for computer types that automatically logon. (WORKS)
{
	LogonArray := {1: "esalogon0", 2: "kllogon4", 3: "momlogon3", 4: "mrllogon1", 5: "afllogon2", 6:"johlogon6",7: "evlogon5", 8: "ndlogon8" }
	AutoLogon := LogonArray[BranchNumber]
	Log("-- configuring autologon registries...")
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, AutoAdminLogon, 1
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultDomainName, dcls.org
	If(TypeNumber == 2) ; Staff
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%AutoLogon%
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPass%
		Return
	}
	If(TypeNumber == 3) ; Patron
	{	
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-PATRON
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPass%
		Return
	}
	If(TypeNumber == 4) ; Catalog
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\esacatalog
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPass%
		Return
	}
	If(TypeNumber == 5) ; Self-Checkout
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-SELFCHECK
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPass%
		Return
	}
	If(TypeNumber == 6) ; Kiosk
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\envkiosk
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPass%
		Return
	}
	Log("!! Failure to create auto logon profile!")
	vNumErrors += 1
	Return
}	

ConfirmationWindow(Wireless, Location, ComputerType, ComputerName) ; Checks that selections are correct before continuing. (WORKS)
{
	Gui +OwnDialogs
	if(Wireless == 1)
		WirelessText := "This is a Wireless computer."
	else
		WirelessText := "This is an Ethernet computer."
		
	if (ComputerType == "Office")
		TypeText := "This will install:`n- Sierra`n- Office for staff computer`n- Staff printers"
	if (ComputerType == "Frontline")
		TypeText := "This will install:`n- Sierra`n- Offline Circulation`n- Staff printers`n- PC Reservation Reservation Station`n- Envisionware Print Release station`n- Auto Logon configuration for staff"
	if (ComputerType == "Patron")
		TypeText := "This will install:`n- Office for patron computer`n- Envisionware PC Reservation client`n- Envisionware LPTOne printer client`n- PatronAdminPanel`n- Auto Logon configuration for patrons"	
	if (ComputerType == "Catalog")
		TypeText := "This will install:`n- EncoreAlways`n- Auto Logon configuration for catalogs"
		
	if(ComputerName == "")
	{
		SoundPlay *48
		MsgBox, 48, Not Named, Please type in a name for the computer.
		Return
	}
	if(StrLen(ComputerName) > 15)
	{
		SoundPlay *48
		MsgBox, 48, Large Name, The computer name is too long.`nPlease input a name that is fifteen characters or less.
		Return
	}
	if(Location == "")
	{
		SoundPlay *48
		MsgBox, 48, No Library, Please select a library branch.
		Return
	}
	if(ComputerType == "")
	{
		SoundPlay *48	
		MsgBox, 48, No Computer, Please select a computer type.
		Return
	}
	SoundPlay *32
	MsgBox, 36, Confirm, This will rename the computer to %ComputerName%.`nThis is a %ComputerType% computer at %Location%.`n%WirelessText% `n%TypeText% `nIs this correct?
	IfMsgBox, Yes
	{
		Log("-- " WirelessText " It is at " Location " and named " ComputerName "." TypeText)
		Gosub __main__
	}
	Return
}

CreateOUPath(TypeNumber, Location, IsWireless) ; Creates a distiguished name for moving to OU. (WORKS)
{
	If(TypeNumber == 1) ; Office
		Return "OU=Offices,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(TypeNumber == 2) ;Frontline PC
		Return "OU=Frontline,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(TypeNumber == 2 and IsWireless == 1) ;Staff Laptop
		Return "OU=Laptops,OU=Systems,OU=" . Location . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"	
	If(TypeNumber == 3) ;Patron PC
		Return "OU=" . Location . ",OU=Patron,OU=DCLS,DC=dcls,DC=org"	
	If(TypeNumber == 3 and IsWireless == 1) ;Patron Laptop
		Return "OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	If(TypeNumber == 4)	;Catalog
		Return "OU=Catalog,OU=Patron,OU=DCLS,DC=dcls,DC=org"
	If(TypeNumber == 5) ;Self Check
		Return "OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	If(TypeNumber == 6)	;Kiosk
		Return "OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"		
	Log("!! Failure to create distinguished name!")
	vNumErrors += 1
	Return
}

CreateTaskList(Computer)
{
	TaskList := Array
	if(Computer == "Office")
	{
		TaskList.append("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		TaskList.append("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml") ; Office 365 for staff.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		; <-|
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;   | 
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*") ;   |- Copy Office shortcuts to Start
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	;   |
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Outlook*")	; <-|
		TaskList.append(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
	}
	if(Computer == "Frontline")
	{
		TaskList.append("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s") ;  Offline circ files.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		TaskList.append("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Offline Circ shortcut.	
		TaskList.append(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
		TaskList.append(A_ScriptDir . "\Resources\Envisionware\_PCReservationStation.exe /S") ; Install Reservation Station
	}
	if(Computer == "Patron")
	{
		vEwareServer := aLPTServers[vLocation]
		TaskList.append("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s") ; Copy PatronAdminPanel.
		TaskList.append("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml") ; Office 365 for patrons.
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		; <-|
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;   |- Copy Office shortcuts to Start
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")	;   |
		TaskList.append("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	; <-|
		TaskList.append("robocopy C:\Users\Public\Desktop C:\ProgramData\Microsoft\Windows\Start Menu /s") ; Update Start menu.
		TaskList.append(A_ScriptDir . "\Resources\Envisionware\_LPTOneClient.exe /S -jqe.host="%vEwareServer%) ; Patron printers.
		TaskList.append(A_ScriptDir . "\Resources\Envisionware\_PCReservationClient.exe /S -ip="%vEwareServer% . " -tcpport=9432") ; Envisionware Client.
	}
	if(Computer == "Catalog")
	{
		TaskList.append("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s")	; EncoreAlways script.
	}
	Return TaskList
}

DefaultTasks(OUPassword, Wireless)
{
	DefaultList := Array
	If(Wireless == 1)
	{
		DefaultList.append("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\WirelessProfile.xml user=all") ; Install Wireless Profile
		Sleep 5000 ; Wait for profile to update.
		DefaultList.append("msiexec.exe /i "A_ScriptDir . "\Resources\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY=""" %vSpiceworksKey% """ SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
	}
	DefaultList.append("cscript //B c:\windows\system32\slmgr.vbs /ipk " %vActivationKey%) ; Copy activation key.
	DefaultList.append("cscript //B c:\windows\system32\slmgr.vbs /ato") ; Activate Windows.
	DefaultList.append("powershell.exe -NoExit -Command $pass = ConvertTo-SecureString -String \"""OUPassword . "\"" -AsPlainText -Force; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -NewName """ vComputerName """ -OUPath '" vOUPath "'") ; Join domain, Move OU.
	DefaultList.append("msiexec.exe /i "A_ScriptDir . "\Resources\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. (WORKS) 
	DefaultList.append("msiexec.exe /i "A_ScriptDir . "\Resources\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn. (WORKS)
	Return DefaultList
}

DoTasks(TaskList)
{
	Loop % TaskList.len()
	Task := TaskList[A_Index]
	Try {
		If(vIsVerbose == 1)
		{
			Log("** Executing: " Task)
		} else {
			Log("** Executing: " Task, 1)
		}
	RunWait, Task
	} Catch {
	vNumErrors += 1
	Log("!! Error attempting "Task . "!")
}

ExitFunc(ExitReason, ExitCode) ; Checks and logs various unusual program closures.
{
	Gui +OwnDialogs
	if ExitReason in Menu,
    {
		SoundPlay *48
        MsgBox, 52, Exiting Deployment, This will end deployment.`nAre you sure you want to exit?
        IfMsgBox, No
            return 1  ; OnExit functions must return non-zero to prevent exit.
		Log("-- User is exiting Deployment`, dying now.")
    }
	if ExitReason in Logoff,Shutdown
	{
		Log("-- System logoff or shutdown in process`, dying now.")
	}
		if ExitReason in Close
	{
		Log("!! The system issued a WM_CLOSE or WM_QUIT`, or some other unusual termination is taking place`, dying now.")
	}
		if ExitReason not in Close,Exit,Logoff,Menu,Shutdown
	{
		Log("!! I am closing unusually`, with ExitReason: " ExitReason ", dying now.")
	}
    ; Do not call ExitApp -- that would prevent other OnExit functions from being called.
}

Log(msg, Type=3) ; 1 logs to file, 2 logs to console, 3 does both, 10 is just a newline to file
{
	global ScriptBasename, AppTitle
	If(Type == 1) {
		FileAppend, %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%%A_Tab%%msg%`n, %ScriptBasename%.log
		}
	If(Type == 2) {
		Message(msg)
		}
	If(Type == 3) {
		FileAppend, %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%%A_Tab%%msg%`n, %ScriptBasename%.log
		Message(msg)
		}
	If(Type == 10) {
		FileAppend, `n, %ScriptBasename%.log
		}	
	Sleep 50 ; Hopefully gives the filesystem time to write the file before logging again
	Return
}

Message(msg)
{
GuiControlGet, Console, 1:
GuiControl, 1:, Console, %Console%%msg%`r`n
}