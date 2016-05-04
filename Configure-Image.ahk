/* 	
	Name: New Computer Deployment		
	Version: 0.3.0
	Author:	Christopher Roth

	Changelog:
		* Wireless Configuration testing
		* Added Progress Bar
*/
if not A_IsAdmin ; Check for elevation (WORKS)
{
    if A_IsCompiled
		Run *RunAs "%A_ScriptFullPath%"
    else
		Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
    ExitApp
}
;   ================================================================================
;   ALL THAT MESSY STUFF THAT DOES CRAZY THINGS. HALF OF THIS IS PROBABLY UNNECCESSARY.
;   ================================================================================
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent ; Keeps a script permanently running (that is, until the user closes it or ExitApp is encountered).
#SingleInstance FORCE ; automatically replaces an old version of the script - useful when auto-elevating.
;   ================================================================================
;   INCLUDES, GLOBAL VARIABLES, ONEXIT, ETC...
;   ================================================================================
SplitPath, A_ScriptName, , , , ScriptBasename
StringReplace, AppTitle, ScriptBasename, _, %A_SPACE%, All
OnExit("ExitFunc") ; Register a function to be called on exit
Global aLocation := {1: "ESA", 2: "KL", 3: "MOM", 4: "MRL", 5: "AFL", 6: "JOH", 7: "EV", 8: "ND"} ; Stores list of library locations.
Global aComputerType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog", 5: "Selfcheck", 6: "Kiosk"} ; Stores list of computer types to deploy.
Global aLPTServers := {1: 192.168.100.221, 2: 10.14.20.14, 3: 10.13.20.14, 4: 10.11.20.5, 5: 192.168.102.221, 6: 192.168.106.221, 7: 192.168.105.221, 8:  10.18.40.200} ; Stores list of LPTOne server IPs (will need to be updated).
Global vBranchNumber ; Stores the value of the Location array index.
Global vTypeNumber ; Stores the value of the ComputerType array index.
Global vIsWireless  ; Stores wireless toggle value.
Global vIsVerbose ; Stores Verbose logging value.
Global vComputerName ; Stores input computer name.
Global vLocation  ; Stores the value extracted from Location array at vBranchNumber index.
Global vComputerType  ; Stores the value extracted from ComputerType array at vTypeNumber index.
Global vLPTServers ; Stores the value extracted from the LPTServers array ay vBranchNumber index.
Global vDistiguishedName := "" ; Stores the Distuguished Name for transferring the OU.
Global vNumErrors := 0	; Tracks the number of errors, if any.

;   ================================================================================
;	BEGIN INITIALIZATION
;   ================================================================================
Try {
	Gui 1: Font,, Lucida Console
	Gui 1: Add, Edit, Readonly x10 y10 w620 h460 vConsole ; I guess not everything has to be a function...
	Gui 1: Show, x20 y20 w640 h480, Console Window
	Log("   Console window up.",2)
} Catch {
	MsgBox failed to create console window! I can't run without console output! Dying now.
	ExitApp
}
Try {
	Log("")
	Log("   Configure-Image v2.0 initializing for machine: " A_ComputerName)
} Catch	{
	MsgBox Testing Deployment.log failed! You probably need to check file permissions. I won't run without my log! Dying now.
	ExitApp
}

;   ================================================================================
;	STARTUP
;   ================================================================================
WinMinimizeAll
WinRestore, Console Window
Log("== Starting Up...")
createOptionsWindow() ; Here is where we construct the GUI
Return

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	Log("== Main Process...")
	Progress, 0, Beginning Configuration, Please Wait., Running Configuration
	if(vWireless == 1) ; If wireless, install wireless profile and Spiceworks.
	{
		Log("== Beginning Wireless Configuration...")
		Progress, 5, Adding profile for wireless computer..., Please Wait., Running Configuration
		Log("-- adding wireless profile...")
		Command("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\Installers\WirelessProfile.xml user=all") ; Install Wireless Profile
		Sleep 5000 ; Wait for profile to update.
		
		Progress, 10, Installing Spiceworks mobile app..., Please Wait., Running Configuration
		Log("-- installing Spiceworks mobile app...")
		Command("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY="" eb7e922f71BB336280238a02c02c64ac35941be2b"" SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
	}
	
	Log("== Beginning Default Configuration...")
	Progress, 15, Activating Windows..., Please Wait., Running Configuration
	Log("-- activating Windows...")
	Command("c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ipk HRRBN-GYBYT-44FP9-3TDPY-B4G6B, c:\windows\system32\") ; Activate Windows.
	Command("c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ato, c:\windows\system32\")
	
	Progress, 25, Renaming Computer..., Please Wait., Running Configuration
	Log("-- renaming computer...")
	Command("powershell.exe -Command Rename-Computer -NewName "vComputerName) ; Rename computer. (WORKS)
	
	Progress, 30, Joining Domain and moving OU..., Please Wait., Running Configuration
	Log("-- joining domain...")
	CreateDistinguishedName() ; Creates distinguished name for OU move
	Command("powershell.exe -NoExit -Command $pass = cat "A_ScriptDir . "Resources\Installers\securestring.txt | convertto-securestring; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DomainJoin . ",$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -OUPath "vDistiguishedName) ; Join domain, Move OU.
	
	Progress, 35, Installing VIPRE anti-malware..., Please Wait.., Running Configuration
	Log("-- installing VIPRE antivirus...")
	Command("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. (WORKS) 
	
	Progress, 45, Installing LogMeIn..., Please Wait.., Running Configuration
	Log("-- installing LogMeIn...")
	Command("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn. (WORKS)



	Progress, 50, Cleaning Up installations..., Please Wait.., Running Configuration
	Log("-- editing registries and clearing files...")
	RegWrite, Reg_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui /f /v EnableSystray /t REG_DWORD /d 0
	FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk"
	FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk"
	
	if(vTypeNumber == 1) ; Office staff get LPTOne staff, staff printers, and Sierra.
	{ 
		Log("== Beginning Office Staff Configuration...")
		Progress, 65, Copying staff shortcuts..., Mostly Done., Running Configuration
		Log("-- copying staff shortcuts...")
		Command("robocopy \Deployment\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		Command("robocopy \Deployment\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy \Deployment\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Copy Sierra runner.
		
		Progress, 70, Installing LPTOne staff print release..., Mostly Done., Running Configuration
		Log("-- installing staff LPTOne print release...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe /s") ; Install staff Print Release Terminal.
	}
	
	if(vTypeNumber == 2) ; Frontline computers get LPTOne staff, staff printers, Sierra, Offline Circ and remove Office.
	{
		Log("== Beginning Frontline Staff Configuration...")
		Progress, 55, Configuring Automatic Logon..., Mostly Done., Running Configuration
		Log("-- configuring autologin registries...")
		AddAutoLogon()
		
		Log("== Beginning Office Staff Configuration...")
		Progress, 65, Copying staff shortcuts..., Mostly Done., Running Configuration
		Log("-- copying staff shortcuts...")
		Command("robocopy \Deployment\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		Command("robocopy \Deployment\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy \Deployment\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Copy Sierra runner.
				
		Progress, 70, Installing LPTOne staff print release..., Mostly Done., Running Configuration
		Log("-- installing staff LPTOne print release...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe /s") ; Install staff Print Release Terminal.
		
		Progress, 75, Installing Envisonware Reservation Station..., Mostly Done., Running Configuration.
		Log("-- installing staff Envisionware Reservation Station...")
		Command(A_ScriptDir . "\Resources\Installers\_PCReservationStation.exe /s")


		Progress, 80, Installing Offline circulation..., Almost There!, Running Configuration
		Log("-- installing offline circulation...")
		Command("robocopy \Deployment\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Copy Offline Circ runner.
		;RemoveOffice("all")
	}
	
	if(vTypeNumber == 3) ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		Log("== Beginning Patron Terminal Configuration...")
		Progress, 55, Configuring Automatic Logon..., Mostly Done., Running Configuration
		Log("-- configuring autologin registries...")
		AddAutoLogon()
		
		Progress, 60, Clearing Sierra shortcuts..., Mostly Done., Runnning Configuration
		Log("-- clearing Sierra...")
		Command("robocopy \Deployment\Resources\Empty /mir C:\Sierra Desktop App")
		
		Progress, 85, Installing Patron LPTOne printers..., Almost There!, Running Configuration
		Log("-- installing patron LPTOne printers...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOneClient.exe""/s -jqe.host="%vLPTServers%)
		
		Progress, 90, Installing Envisionware client..., Almost There!, Running Configuration
		Log("-- installing patron Envisionware client...")
		Command(A_ScriptDir . "\Resources\Installers\_PCReservationClient.exe""/s")
		;RemoveOffice("outlook", "skype")
		;AutomateOfficeActivation()
	}
	
	if(vTypeNumber == 4) ; Catalog script is installed.
	{
		Log("== Beginning Catalog Computer Configuration...")
		Progress, 55, Configuring Automatic Logon..., Mostly Done., Running Configuration
		Log("-- configuring autologin registries...")
		AddAutoLogon()
		
		Progress, 95, Loading Catalog Script..., Almost There!, Running Configuration
		Log("-- running catalog script...")
		Command(A_ScriptDir . "\Resources\EncoreAlways\EncoreAlways.ahk")
	}
	
	if(vTypeNumber == 5) ; Self-Checkout terminal software is installed.
	{
	
		AddAutoLogon()
		;Command(Self-Check)
	}

	if(vTypeNumber == 6) ; Kiosk Computer
	{

		;Command(Kiosk)
	}
	Progress, 100, Finalizing Configuration., Last Thing!, Running Configuration
	Sleep 2000
	if(vNumErrors != 0) ; Final Check for errors and closes program.
	{
		Progress, OFF
		Log("!! Configuration Incomplete! There were "%vNumErrors% . " errors with this program.")
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
	}
	else
	{
		Progress, OFF
		Log("== Configuration Complete! There were "%vNumErrors% . " errors with this program.")
		MsgBox, 64, Deployment Complete,  New computer deployment complete! Exiting application.
		ExitApp
	}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

ButtonExit: ; Label for the Exit button. (WORKS)
{
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

ButtonInstall: ; Label that takes user input and prepares to run installers, confirming first. (WORKS)
{
	Gui, Submit, NoHide
	vLocation := aLocation[vBranchNumber]
	vComputerType := aComputerType[vTypeNumber]
	vLPTServers := aLPTServers[vBranchNumber]
	ConfirmationWindow()
	Return
}	

GuiClose: ; Label for default close functions, prompts confirmation screen. (WORKS)
{
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

AddAutoLogon() ; Adds registry keys for computer types that automatically logon. (WORKS)
{
	Progress, 55, Configuring Auto-Login Registry..., Please Wait., Running Configuration
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, AutoAdminLogon, 1
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultDomainName, dcls.org
	aAutoLogon := {1: "esalogon0", 2: "kllogon4", 3: "momlogon3", 4: "mrllogon1", 5: "afllogon2", 6:"johlogon6",7: "evlogon5", 8: "ndlogon8" }
	vAutoLogon := aAutoLogon[vBranchNumber]
	If(vTypeNumber == 2) ; Staff
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vAutoLogon%
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, w0nd3rb!@#$
		return
	}
	If(vTypeNumber == 3) ; Patron
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-PATRON
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, DC4p@tron15
		return
	}
	If(vTypeNumber == 4) ; Catalog
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\esacatalog
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, October21@)!$
		return
	}
	If(vTypeNumber == 5) ; Self-Checkout
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-SELFCHECK
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, DC4p@tron15
		return
	}
	If(vTypeNumber == 6) ; Kiosk
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\envkiosk
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, DC4p@tron15
		return
	}
	Log("...Auto logon registries updated")
}	

Command(vCommand, vHide := "") ; Runs a configuration command.
{
	If(vIsVerbose == 1)
	{
		Try {
		Log("-- Executing: "vCommand)
		RunWait %vCommand%%vHide%
		} Catch {
		vNumErrors += 1
		Log("!! Error executing "vCommand . "!")
		}
	}
	else
	{
		Try {
		Log("-- Executing: "vCommand, 1)
		RunWait %vCommand%%vHide%
		} Catch {
		vNumErrors += 1
		Log("!! Error executing "vCommand . "!")
		}
	}
	Return
}

ConfirmationWindow() ; Checks that selections are correct before continuing. (WORKS)
{
	Gui +OwnDialogs
	if(vWireless = 1)
		vIsWireless := "This is a Wireless computer."
	else
		vIsWireless := "This is an Ethernet computer."
	if(vComputerName == "")
	{
	MsgBox, 48, Not Named, Please type in a name for the computer.
	Return
	}
	if(StrLen(vComputerName) > 15)
	{
	MsgBox, 48, Large Name, The computer name is too long.`nPlease input a name that fifteen characters or less.
	Return
	}
	if(vLocation == "")
	{
	MsgBox, 48, No Library, Please select a library branch.
	Return
	}
	if(vComputerType == "")
	{
	MsgBox, 48, No Computer, Please select a computer type.
	Return
	}
	MsgBox, 36, Confirm, This will rename the computer to %vComputerName%.`nThis is a %vComputerType% computer at %vLocation%.`n%vIsWireless% `nIs this correct?
	IfMsgBox, Yes
		Gosub __main__
	Return
}

CreateDistinguishedName() ; Creates a distiguished name for moving to OU. (WORKS)
{
	If(vTypeNumber == 1) ; Office
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Offices,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 2) ;Frontline PC
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Frontline,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}		
	If(vTypeNumber == 2 and vWireless == 1) ;Staff Laptop
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Laptops,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 3) ;Patron PC
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=" . vLocation . ",OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 3 and vWireless == 1) ;Patron Laptop
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}		
	If(vTypeNumber == 4)	;Catalog
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Catalog,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 5) ;Self Check
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 6)	;Kiosk
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}		
	Log("Failure to create distinguished name!")
	vNumErrors += 1
}

createOptionsWindow() ; Create the main GUI. 
{
	Gui 2: New, , Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text,, Type in new computer name:
	Gui 2: Font, Norm
	Gui 2: Add, Edit, Uppercase vvComputerName,
;----This section contains a Radio toggle for Library locations.----
	Gui 2: Font, Bold s10
	Gui 2: Add, GroupBox, Section r8, Select Branch:
	Gui 2: Font, Norm
	Gui 2: Add, Radio, altsubmit vvBranchNumber xp+10 yp+20, East Shore
	Gui 2: Add, Radio, altsubmit, Kline Library
	Gui 2: Add, Radio, altsubmit, Madeline Olewine
	Gui 2: Add, Radio, altsubmit, McCormick Riverfront
	Gui 2: Add, Radio, altsubmit, Alexander Family
	Gui 2: Add, Radio, altsubmit, Johnson Memorial
	Gui 2: Add, Radio, altsubmit, Elizabethville
	Gui 2: Add, Radio, altsubmit, Northern Dauphin
;----This Section contains a Radio toggle for computer type.----
	Gui 2: Font, Bold s10
	Gui 2: Add, GroupBox, Section r4 ys, Select computer type:
	Gui 2: Font, Norm
	Gui 2: Add, Radio, altsubmit vvTypeNumber xp+10 yp+20, Office Staff
	Gui 2: Add, Radio, altsubmit, Frontline Staff
	Gui 2: Add, Radio, altsubmit, Patron Computer
	Gui 2: Add, Radio, altsubmit, Catalog Computer			
	;Gui 2: Add, Radio, altsubmit, Self-Checkout Station		<- To Be Implimented
	;Gui 2: Add, Radio, altsubmit, Print Kiosk				<- To Be Implimented
;----This section contains Checkbox toggles.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Checkbox, Section xs vvWireless, This is a Wireless computer. ; Wireless check toggle.
	Gui 2: Add, Checkbox, vvIsVerbose, Use Verbose logging. ; Verbose logging toggle.
	Gui 2: Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui 2: Add, Button, Section gButtonInstall w100, Install
	Gui 2: Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui 2: Show
	Return
}

ExitFunc(ExitReason, ExitCode) ; Checks and logs various unusual program closures.
{
	Gui +OwnDialogs
	if ExitReason in Menu,
    {
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
	;Type += 16
	Return
}

Message(msg)
{
GuiControlGet, Console, 1:
GuiControl, 1:, Console, %Console%%msg%`r`n
}
