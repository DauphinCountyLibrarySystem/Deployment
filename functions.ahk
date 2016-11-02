AddAutoLogon(Location, Computer, LogonPassword) ; Adds registry keys for computer types that automatically logon.
{
	LogonArray := {"ESA": "esalogon0", "KL": "kllogon4", "MOM": "momlogon3", "MRL": "mrllogon1", "AFL": "afllogon2", "JOH":"johlogon6", "EV": "evlogon5", "ND": "ndlogon8" }
	AutoLogon := LogonArray[Location]
	Log("-- configuring autologon registries...")
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, AutoAdminLogon, 1
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultDomainName, dcls.org
	If(Computer == "Frontline")
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%AutoLogon%
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPassword%
		Return
	}
	If(Computer == "Patron")
	{	
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-PATRON
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPassword%
		Return
	}
	If(Computer == "Catalog") 
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\esacatalog
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, %LogonPassword%
		Return
	}
	Log("!! Failure to create auto logon profile!")
	vNumErrors += 1
	Return
}	

ConfirmationWindow(Wireless, Location, Computer, Name) ; Checks that selections are correct before continuing.
{
	Gui +OwnDialogs
	if(Wireless == 1)
		WirelessText := "This is a Wireless computer."
	else
		WirelessText := "This is an Ethernet computer."
		
	if (Computer == "Office")
		TypeText := "This will install:`n- Sierra`n- Office for staff computer`n- Staff printers"
	if (Computer == "Frontline")
		TypeText := "This will install:`n- Sierra`n- Offline Circulation`n- Staff printers`n- PC Reservation Reservation Station`n- Envisionware Print Release station`n- Auto Logon configuration for staff"
	if (Computer == "Patron")
		TypeText := "This will install:`n- Office for patron computer`n- Envisionware PC Reservation client`n- Envisionware LPTOne printer client`n- PatronAdminPanel`n- Auto Logon configuration for patrons"	
	if (Computer == "Catalog")
		TypeText := "This will install:`n- EncoreAlways`n- Auto Logon configuration for catalogs"
		
	if(Name == "")
	{
		SoundPlay *48
		MsgBox, 48, Not Named, Please type in a name for the computer.
		Return
	}
	if(StrLen(Name) > 15)
	{
		SoundPlay *48
		MsgBox, 48, Large Name, The computer name is too long.`nPlease input a name that is fifteen characters or less.
		Return
	}
	if(Location == "Branch...")
	{
		SoundPlay *48
		MsgBox, 48, No Library, Please select a library branch.
		Return
	}
	if(Computer == "Computer...")
	{
		SoundPlay *48	
		MsgBox, 48, No Computer, Please select a computer type.
		Return
	}
	SoundPlay *32
	MsgBox, 36, Confirm, This will rename the computer to %Name%.`nThis is a %Computer% computer at %Location%.`n%WirelessText% `n%TypeText% `nIs this correct?
	IfMsgBox, Yes
	{
		Log("-- " WirelessText " It is at " Location " and named " Name "." TypeText)
		Gosub __main__
	}
	Return
}

CreateOUPath(Wireless, Location, Computer) ; Creates a distiguished name for moving to OU.
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

CreateTaskList(Computer) ; Returns an array of tasks, based on the type of computer being deployed.
{
	TaskList := Object()
	if(Computer == "Office")
	{
		TaskList.insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		TaskList.insert("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml") ; Office 365 for staff.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		; <-|
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;   | 
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*") ;   |- Copy Office shortcuts to Start
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	;   |
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Outlook*")	; <-|
		TaskList.insert(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
	}
	if(Computer == "Frontline")
	{
		TaskList.insert("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s") ;  Offline circ files.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Offline Circ shortcut.	
		TaskList.insert(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
		TaskList.insert(A_ScriptDir . "\Resources\Envisionware\_PCReservationStation.exe /S") ; Install Reservation Station
	}
	if(Computer == "Patron")
	{
		vEwareServer := aLPTServers[vLocation]
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s") ; Copy PatronAdminPanel.
		TaskList.insert("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml") ; Office 365 for patrons.
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")		; <-|
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")		;   |- Copy Office shortcuts to Start
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")	;   |
		TaskList.insert("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")	; <-|
		TaskList.insert("robocopy C:\Users\Public\Desktop C:\ProgramData\Microsoft\Windows\Start Menu /s") ; Update Start menu.
		TaskList.insert(A_ScriptDir . "\Resources\Envisionware\_LPTOneClient.exe /S -jqe.host="%vEwareServer%) ; Patron printers.
		TaskList.insert(A_ScriptDir . "\Resources\Envisionware\_PCReservationClient.exe /S -ip="%vEwareServer% . " -tcpport=9432") ; Envisionware Client.
	}
	if(Computer == "Catalog")
	{
		TaskList.insert("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s")	; EncoreAlways script.
	}
	Return TaskList
}

DoTasks(TaskList) ; Loops through an array of task commands, trying and logging each one.
{
	Loop % TaskList.MaxIndex()
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

Log(msg, Type=3) ; 1 logs to file, 2 logs to console, 3 does both, 10 is just a newline to file.
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

Message(msg) ; For logging to Console window.
{
GuiControlGet, Console, 1:
GuiControl, 1:, Console, %Console%%msg%`r`n
}