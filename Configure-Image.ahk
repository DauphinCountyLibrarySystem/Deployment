/* 	
	Name: New Computer Deployment		
	Version: 2.3
	Author:	Christopher Roth

	Changelog:
		* Improved interface design.
		* Improved code readability.
		* Uses some code from Lucas Bodnyk's SierraWrapper.
		* Code now uses functions!
		* Added checks for filled fields.
		* Added confirmation window.
*/

; ELEVATE


;   ================================================================================
;   ALL THAT MESSY STUFF THAT DOES CRAZY THINGS. HALF OF THIS IS PROBABLY UNNECCESSARY.
;   ================================================================================
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent ; Keeps a script permanently running (that is, until the user closes it or ExitApp is encountered).

;   ================================================================================
;   INCLUDES, GLOBAL VARIABLES, ONEXIT, ETC...
;   ================================================================================
SplitPath, A_ScriptName, , , , ScriptBasename
StringReplace, AppTitle, ScriptBasename, _, %A_SPACE%, All
OnExit("ExitFunc") ; Register a function to be called on exit
Global aLocation := {1: "ESA", 2: "KL", 3: "MOM", 4: "MRL", 5: "AFL", 6: "JOH", 7: "EV", 8: "ND"} ; Stores list of library locations.
Global aComputerType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog", 5: "Selfcheck" 6: "Kiosk"} ; Stores list of computer types to deploy.
Global vBranchNumber ; Stores the value of the Location array index.
Global vTypeNumber ; Stores the value of the ComputerType array index.
Global vWireless  ; Stores wireless toggle value.
Global vComputerName ; Stores input computer name.
Global vLocation  ; Stores the value extracted from Location array at vBranchNumber index.
Global vComputerType  ; Stores the value extracted from CompType array at vTypeNumber index.
Global vDistiguishedName := "" ; Stores the Distuguished Name for transferring the OU
Global vNumErrors := 0	; Tracks the number of errors, if any.

;   ================================================================================
;	BEGIN INITIALIZATION
;   ================================================================================
Try {
	Log("")
	Log("   ComputerDeployer v2.0 initializing for machine: " A_ComputerName)
} Catch	{
	MsgBox Testing Deployment.log failed! You probably need to check file permissions. I won't run without my log! Dying now.
	ExitApp
}

;   ================================================================================
;	STARTUP
;   ================================================================================
Log("== Starting Up...")
;WinMinimizeAll
createWindow() ; Here is where we construct the GUI 
Return

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	Log("== Main Process...")
	if(vWireless == 1) ; If wireless, install wireless profile and Spiceworks.
	{
		Command("cmd.exe /c netsh wlan add profile filename="""A_ScriptDir . "\WirelessProfile\WirelessProfile.xml"" user=all & pause")
		Sleep 5000 ; Wait for profile to update.
		Command("msiexec.exe /I "A_ScriptDir . "_Spiceworks.msi SPICEWORKS_SERVER=spiceworks.dcls.org SPICEWORKS_AUTH_KEY= ***REMOVED*** SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "spiceworks_install.log")
	}
	
	Command("powershell.exe -NoExit -Command Rename-Computer -NewName "vComputerName) ; Rename computer.
	CreateDistinguishedName()
	Command("powershell.exe -NoExit -Command $pass = cat C:\securestring.txt | convertto-securestring; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist "DomainJoin . ",$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -OUPath "vDistiguishedName) ; Move OU.
	Command("msiexec.exe /I "A_ScriptDir . "_Vipre.MSI /quiet /norestart /log "A_ScriptDir . "vipre_install.log") ; Install VIPRE antivirus. 
	Command("msiexec.exe /I "A_ScriptDir . "_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "logmein_install.log") ; Install LogMeIn.
	RegWrite, Reg_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui /f /v EnableSystray /t REG_DWORD /d 0
	FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk"
	FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk"

	if(vTypeNumber == 1) ; Office staff get printers and Sierra.
		InstallPrinters()
		Command("I:\Sierra\install.exe -D$USER_INSTALL_DIR$="C:\Sierra Desktop App" -D$PARAM_port$=63000 -D$PARAM_ip$=dcls.iii.com")
		
	if(vTypeNumber == 2) ; Frontline computers get printers, Sierra, Offline Circ and remove Office.
	{
		AddAutoLogon()
		InstallPrinters()
		Command("I:\Sierra\install.exe -D$USER_INSTALL_DIR$="C:\Sierra Desktop App" -D$PARAM_port$=63000 -D$PARAM_ip$=dcls.iii.com")
		;Command("I:\Sierra\offline106_02.exe")
		RemoveOffice("all")
	}
	
	if(vTypeNumber == 3) ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		AddAutoLogon()
		Command("I:\Envisionware\Patron\lptone.exe")
		Command("I:\Envisionware\Patron\pcres.exe")
		RemoveOffice("outlook", "skype")
		;AutomateOfficeActivation()
	}
	
	if(vTypeNumber == 4) ; Catalog script is installed.
		AddAutoLogon()
		;Command("")
		
	if(vTypeNumber == 5) ; Self-Checkout terminal software is installed.
		AddAutoLogon()
		Command("I:\Envisionware\OneStop (Self-Checkout)\InstallOneStop_2.0.1.23344_Hotfix.exe")
		
	if(vNumErrors != 0) ; Final Check for errors and closes program.
		{
		Log("==Configuration Incomplete! There were "%vNumErrors% . " errors with this program.")
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
		}
	else
		{
		Log("==Configuration Complete! There were "%vNumErrors% . " errors with this program.")
		MsgBox, 64, Deployment Complete,  New computer deployment complete! Exiting application.
		ExitApp
		}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

ButtonExit: ; Label for the Exit button.
{
	MsgBox, 52, Exiting Deployment, This will end deployment.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Deployment`, dying now.")
	ExitApp
}

ButtonInstall: ; Label that takes user input and prepares to run installers, confirming first.
{
	Gui, Submit, NoHide
	vLocation := aLocation[vBranchNumber]
	vComputerType := aComputerType[vTypeNumber]
	ConfirmationWindow()
	Return
}	

GuiClose: ; Label for default close functions, prompts confirmation screen.
{
	MsgBox, 52, Exiting Deployment, This will end deployment.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Deployment`, dying now.")
	ExitApp
}

AddAutoLogon() ; Adds registry keys for computer types that automatically logon.
{
	RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, AutoAdminLogon, 1
	aAutoLogon := {1: "esalogon0", 2: "kllogon4", 3: "momlogon3", 4: "mrllogon1", 5: "afllogon2", 6:"johlogon6",7: "evlogon5", 8: "ndlogon8" }
	vAutoLogon := aAutoLogon[vBranchNumber]
	If(vTypeNumber == 2) ; Staff
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vAutoLogon%
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, ***REMOVED***
		return
	}
	If(vTypeNumber == 3) ; Patron
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-PATRON
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, ***REMOVED***
		return
	}
	If(vTypeNumber == 4) ; Catalog
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\esacatalog
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, ***REMOVED***
		return
	}
	If(vTypeNumber == 5) ; Self-Checkout
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\%vLocation%-SELFCHECK
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, ***REMOVED***
		return
	}
	If(vTypeNumber == 6) ; Kiosk
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultUserName, dcls\envkiosk
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon, DefaultPassword, ***REMOVED***
		return
	}
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

Command(vCommand, vParameter1 :="", vParameter2 :="") ; Runs a configuration command.
{
	Try {
		Log("Executing: "vCommand)
		RunWait %vCommand%%vParameter1%%vParameter2%
		} Catch {
		vNumErrors += 1
		Log("Error executing "vCommand . "!")
		}
	Return
}

ConfirmationWindow() ; Checks that selections are correct before continuing.
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

CreateDistinguishedName() ; Creates a distiguished name for moving to OU.
{
	If(vTypeNumber == 2 and vWireless == 1) ;Staff Laptop
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Laptops,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 2 and vWireless != 1) ;Frontline PC
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Frontline,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 1) ; Office
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Offices,OU=Systems,OU=" . vLocation . ",OU=Staff,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 3) ;Patron PC
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=" . vLocation . ",OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}
	If(vTypeNumber == 6)	;Kiosk
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"
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
	If(vTypeNumber == 4 and vWireless == 1) ;Patron Laptop
		{
		vDistiguishedName := "CN=" . vComputerName . ",OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		return
		}
	Log("Failure to create distinguished name!")
	vNumErrors += 1
}

CreateWindow() ; Create the main GUI. 
{
	Gui, New, , Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui, Font, Bold s10
	Gui, Add, Text,, Type in new computer name:
	Gui, Font, Norm
	Gui, Add, Edit, Uppercase vvComputerName,
;----This section contains a Radio toggle for Library locations.----
	Gui, Font, Bold s10
	Gui, Add, GroupBox, Section r8, Select Branch:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvBranchNumber xp+10 yp+20, East Shore
	Gui, Add, Radio, altsubmit, Kline Library
	Gui, Add, Radio, altsubmit, Madeline Olewine
	Gui, Add, Radio, altsubmit, McCormick Riverfront
	Gui, Add, Radio, altsubmit, Alexander Family
	Gui, Add, Radio, altsubmit, Johnson Memorial
	Gui, Add, Radio, altsubmit, Elizabethville
	Gui, Add, Radio, altsubmit, Northern Dauphin
;----This Section contains a Radio toggle for computer type.----
	Gui, Font, Bold s10
	Gui, Add, GroupBox, Section r5 ys, Select computer type:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvTypeNumber xp+10 yp+20, Office Staff
	Gui, Add, Radio, altsubmit, Frontline Staff
	Gui, Add, Radio, altsubmit, Patron Computer
	Gui, Add, Radio, altsubmit, Catalog Computer
	Gui, Add, Radio, altsubmit, Self-Checkout Station
	Gui, Add, Radio, altsubmit, Print Kiosk
	Gui, Font, Bold s10
	Gui, Add, Checkbox, xs vvWireless, Check if a wireless computer. ; Wireless check toggle.
	Gui, Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui, Add, Button, Section gButtonInstall w100, Install
	Gui, Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui, Show
	Return
}

InstallPrinters()
{
	if(vBranchNumber >= 2 or <= 4)
	{
		RunWait %vLocation%"-Print"
		return
	}
	else
	{
		RunWait %vLocation%"-IT-APP01"
		return
	}
}

Log(Message, Type="1") ; Type=1 shows an info icon, Type=2 a warning one, and Type=3 an error one ; I'm not implementing this right now, since I already have custom markers everywhere.
{
	global ScriptBasename, AppTitle
	IfEqual, Type, 2
		Message = WW: %Message%
	IfEqual, Type, 3
		Message = EE: %Message%
	IfEqual, Message, 
		FileAppend, `n, %ScriptBasename%.log
	Else
		FileAppend, %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%%A_Tab%%Message%`n, %ScriptBasename%.log
	Sleep 50 ; Hopefully gives the filesystem time to write the file before logging again
	Type += 16
	;TrayTip, %AppTitle%, %Message%, , %Type% ; Useful for testing, but in production this will confuse my users.
	;SetTimer, HideTrayTip, 1000
	Return
	HideTrayTip:
	SetTimer, HideTrayTip, Off
	TrayTip
	Return
}
