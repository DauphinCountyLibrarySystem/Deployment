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
#Include, functions.ahk
SplitPath, A_ScriptName, , , , ScriptBasename
StringReplace, AppTitle, ScriptBasename, _, %A_SPACE%, All
OnExit("ExitFunc") ; Register a function to be called on exit
Global aLocation := {1: "ESA", 2: "KL", 3: "MOM", 4: "MRL", 5: "AFL", 6: "JOH", 7: "EV", 8: "ND"} ; Stores list of library locations.
Global aComputerType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog", 5: "Selfcheck", 6: "Kiosk"} ; Stores list of computer types to deploy.
Global aLPTServers := {1: 192.168.100.221, 2: 10.14.20.14, 3: 10.13.20.14, 4: 10.11.20.5, 5: 192.168.102.221, 6: 192.168.106.221, 7: 192.168.105.221, 8:  10.18.40.200} ; Stores list of LPTOne server IPs (will need to be updated).
Global vBranchNumber ; Stores the value of the Location array index.
Global vTypeNumber ; Stores the value of the ComputerType array index.
Global vWireless  ; Stores wireless toggle value.
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
	Progress, M, Configuration, Please Wait., Running Configuration
	Progress, 0, Configuration, Please Wait., Running Configuration
	if(vWireless == 1) ; If wireless, install wireless profile and Spiceworks.
	{
		Log("== Wireless Configuration...")
		Progress, 5, Adding profile for wireless computer..., Please Wait., Running Configuration
		Log("-- adding wireless profile...")
		Command("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\Installers\WirelessProfile.xml user=all") ; Install Wireless Profile
		Sleep 5000 ; Wait for profile to update.
		
		Progress, 10, Installing Spiceworks mobile app..., Please Wait., Running Configuration
		Log("-- installing Spiceworks mobile app...")
		Command("msiexec.exe /i "A_ScriptDir . "\Resources\Installers\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY="" ***REMOVED***"" SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
	}
	
	Log("== Default Configuration...")
	Progress, 15, Activating Windows..., Please Wait., Running Configuration
	Log("-- activating Windows...")
	Command("cscript //b c:\windows\system32\slmgr.vbs ""/ipk ***REMOVED***"", c:\windows\system32\") ; Activate Windows.
	Command("cscript //b c:\windows\system32\slmgr.vbs ""/ato"", c:\windows\system32\")
	
	Progress, 25, Renaming Computer..., Please Wait., Running Configuration
	Log("-- renaming computer...")
	Command("powershell.exe -Command Rename-Computer -NewName "vComputerName) ; Rename computer. (WORKS)
	
	Progress, 30, Joining Domain and moving OU..., Please Wait., Running Configuration
	Log("-- joining domain...")
	CreateDistinguishedName() ; Creates distinguished name for OU move
	Command("powershell.exe -NoExit -Command $pass = cat "A_ScriptDir . "Resources\Installers\securestring.txt | convertto-securestring; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -OUPath """vDistiguishedName"") ; Join domain, Move OU.
	
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
		Log("== Office Staff Configuration...")
		Progress, 65, Copying staff shortcuts..., Mostly Done., Running Configuration
		Log("-- copying staff shortcuts...")
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Copy Sierra runner.
		
		Progress, 70, Installing LPTOne staff print release..., Mostly Done., Running Configuration
		Log("-- installing staff LPTOne print release...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe""/S") ; Install staff Print Release Terminal.
	}
	
	if(vTypeNumber == 2) ; Frontline computers get LPTOne staff, staff printers, Sierra, Offline Circ and remove Office.
	{
		Log("== Frontline Staff Configuration...")
		AddAutoLogon()
		
		Progress, 65, Copying staff shortcuts..., Mostly Done., Running Configuration
		Log("-- copying staff shortcuts...")
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Copy Sierra runner.
				
		Progress, 70, Installing LPTOne staff print release..., Mostly Done., Running Configuration
		Log("-- installing staff LPTOne print release...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOnePrintRelease.exe""/S") ; Install staff Print Release Terminal.
		
		Progress, 75, Installing Envisonware Reservation Station..., Mostly Done., Running Configuration.
		Log("-- installing staff Envisionware Reservation Station...")
		Command(A_ScriptDir . "\Resources\Installers\_PCReservationStation.exe""/S")


		Progress, 80, Installing Offline circulation..., Almost There!, Running Configuration
		Log("-- installing offline circulation...")
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Copy Offline Circ runner.
		;RemoveOffice("all")
	}
	
	if(vTypeNumber == 3) ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		Log("== Patron Terminal Configuration...")
		AddAutoLogon()
		
		Progress, 60, Clearing Sierra shortcuts..., Mostly Done., Runnning Configuration
		Log("-- clearing Sierra...")
		Command("robocopy "A_ScriptDir . "\Resources\Empty /mir C:\Sierra Desktop App")
		
		Progress, 85, Installing Patron LPTOne printers..., Almost There!, Running Configuration
		Log("-- installing patron LPTOne printers...")
		Command(A_ScriptDir . "\Resources\Installers\_LPTOneClient.exe""/S -jqe.host="%vLPTServers%)
		
		Progress, 90, Installing Envisionware client..., Almost There!, Running Configuration
		Log("-- installing patron Envisionware client...")
		Command(A_ScriptDir . "\Resources\Installers\_PCReservationClient.exe""/S -ip="%vLPTServers% . " -tcpport=9432")
		;RemoveOffice("outlook", "skype")
		;AutomateOfficeActivation()
	}
	
	if(vTypeNumber == 4) ; Catalog script is installed.
	{
		Log("== Catalog Computer Configuration...")
		AddAutoLogon()
		
		Progress, 95, Confiuring Catalog Registries..., Almost There!, Running Configuration
		Log("-- configuring catalog registries...")
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, EncoreAways, "C:\IT\Deployment\Resources\EncoreAlways\EncoreAlways.exe"
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
		SoundPlay *16
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
	}
	else
	{
		Progress, OFF
		Log("== Configuration Complete! There were "%vNumErrors% . " errors with this program.")
		SoundPlay *64
		MsgBox, 64, Deployment Complete,  New computer deployment complete! Exiting application.
		ExitApp
	}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

#Include, labels.ahk