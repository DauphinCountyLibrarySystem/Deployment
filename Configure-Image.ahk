/* 	
	Name: New Computer Deployment		
	Version: 0.1.0
	Authors: Christopher Roth, Lucas Bodnyk

	Changelog:
		* Removed progress bar
		* Moved functions to seperate file
		* Resolved issues with OU move
		* Cleaned up file paths
		* Added Eware closing function
*/

;   ================================================================================
;	CONFIGURATION
;   ================================================================================
Global aLPTServers := {"ESA": 192.168.100.221, "MRL": 10.11.20.5, "MOM": 10.13.20.14, "KL": 10.14.20.14, "AFL": 192.168.102.221, "JOH": 192.168.106.221, "EV": 192.168.105.221, "ND":  10.18.40.200} ; Stores list of LPTOne server IPs.
Global vActivationKey := ***REMOVED*** ; Windows activation key.
Global vSpiceworksKey := ***REMOVED*** ; Spiceworks authentication key.

;   ================================================================================
;	AUTO-ELEVATE
;   ================================================================================
if not A_IsAdmin
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
Global aLocation := {1: "ESA", 2: "MRL", 3: "MOM", 4: "KL", 5: "AFL", 6: "EV", 7: "JOH", 8: "ND"} ; Stores list of library locations.
Global aComputerType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog"};, 5: "Selfcheck", 6: "Kiosk"} ; Stores list of computer types to deploy.
Global vLocationNumber ; Stores the value of the Location radio button.
Global vTypeNumber ; Stores the value of the ComputerType radio button.
Global vIsWireless  ; Stores wireless checkbox value.
Global vIsVerbose ; Stores Verbose logging checkbox value.
Global vComputerName ; Stores input computer name.
Global vLocation  ; Stores the value extracted from Location array at vLocationNumber index.
Global vComputerType  ; Stores the value extracted from ComputerType array at vTypeNumber index.
Global vEwareServer ; Stores the value extracted from the LPTServers array ay vLocationNumber index.
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
Gosub CreateOptionsWindow ; Here is where we construct the GUI
Return

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	if(vIsWireless == 1) ; If wireless, install wireless profile and Spiceworks.
	{
		Log("== Wireless Configuration...")
		Log("-- adding wireless profile...")
		RunLog("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\WirelessProfile.xml user=all") ; Install Wireless Profile
		Sleep 5000 ; Wait for profile to update.	
		Log("-- installing Spiceworks mobile app...")
		RunLog("msiexec.exe /i "A_ScriptDir . "\Resources\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY=""" %vSpiceworksKey% """ SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
	}	
	
	Log("== Default Configuration...")	
	Log("-- activating Windows...")
	RunLog("cscript //B c:\windows\system32\slmgr.vbs /ipk " %vActivationKey%) ; Copy activation key.
	RunLog("cscript //B c:\windows\system32\slmgr.vbs /ato") ; Activate Windows.
	
	Log("-- joining domain with new name...")
	vOUPath := CreateOUPath(vTypeNumber, vLocation, vIsWireless) ; Creates distinguished name for OU move
	RunLog("powershell.exe -NoExit -Command $pass = ConvertTo-SecureString -String \""***REMOVED***\"" -AsPlainText -Force; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -NewName """ vComputerName """ -OUPath '" vOUPath "'") ; Join domain, Move OU.
	
	Log("-- installing VIPRE antivirus...")
	RunLog("msiexec.exe /i "A_ScriptDir . "\Resources\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. (WORKS) 
	
	Log("-- installing LogMeIn...")
	RunLog("msiexec.exe /i "A_ScriptDir . "\Resources\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn. (WORKS)
	
	Log("-- editing registries and clearing files...")
	RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui, EnableSystray, 0
	FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk
	FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk
	
	if(vComputerType == "Office") ; Office staff get Office365, staff printers, and Sierra.
	{ 
		Log("== Office Staff Configuration...")	
		Log("-- installing Sierra files...")
		RunLog("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s",",,Hide") ; Sierra files.	
		
		Log("-- configuring Office for staff...")
		RunLog("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml")
		
		Log("-- updating Desktop shortcuts...")
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut.
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Outlook*")
		
		Log("-- installing staff LPTOne print release...")
		RunLog(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
	}
	
	if(vComputerType == "Frontline") ; Frontline computers get LPTOne staff, staff printers, Sierra, Offline Circ and remove Office.
	{
		Log("== Frontline Staff Configuration...")
		Log("-- configuring automatic logon...")
		AddAutoLogon(vLocation, vTypeNumber)
		
		Log("-- installing Sierra files...")
		RunLog("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		RunLog("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s") ;  Offline circ files.
		
		Log("-- copying staff shortcuts...")
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*") ; Sierra shortcut.
		RunLog("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Offline Circ shortcut.		
		
		Log("-- installing staff LPTOne print release...")
		RunLog(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
		
		Log("-- installing staff Envisionware Reservation Station...")
		RunLog(A_ScriptDir . "\Resources\Envisionware\_PCReservationStation.exe /S") ; Install Reservation Station
	}
	
	if(vComputerType == "Patron") ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		Log("== Patron Terminal Configuration...")
		vEwareServer := aLPTServers[vLocation]
			
		Log("-- configuring automatic logon...")
		AddAutoLogon(vLocation, vTypeNumber)
		
		Log("-- installing PatronAdminPanel...")
		RunLog("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s") ; PatronAdminPanel script files.
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, PatronAdminPanel, ""C:\PatronAdminPanel\PatronAdminPanel.exe"" ; Set PatronAdminPanel auto-start.
		
		Log("-- configuring Office for patrons...")
		RunLog("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml")
		
		Log("-- updating Desktop shortcuts...")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")
		RunLog("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")
		
		Log("-- updating Start menu...")
		RunLog("robocopy C:\Users\Public\Desktop C:\ProgramData\Microsoft\Windows\Start Menu /s")
		
		Log("-- installing patron LPTOne printers...")
		RunLog(A_ScriptDir . "\Resources\Envisionware\_LPTOneClient.exe /S -jqe.host="%vEwareServer%) ; Patron printers.
		
		Log("-- installing patron Envisionware client...")
		RunLog(A_ScriptDir . "\Resources\Envisionware\_PCReservationClient.exe /S -ip="%vEwareServer% . " -tcpport=9432") ; Envisionware Client.
		Sleep 15000
		Gosub ClosePCReservation
	}
	
	if(vComputerType == "Catalog") ; Catalog script is installed.
	{
		Log("== Catalog Computer Configuration...")
		Log("-- configuring automatic logon...")
		AddAutoLogon(vLocation, vTypeNumber)		
		
		Log("-- installing EncoreAlways script...")
		RunLog("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s")	; EncoreAlways script files.
		
		Log("-- configuring catalog registries...")
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, EncoreAways, ""C:\EncoreAlways\EncoreAlways.exe""
	}
	
	;if(vTypeNumber == 5) ; Self-Checkout terminal software is installed.
	;{
		;AddAutoLogon()
		;RunLog(Self-Check)
	;}
	
	;if(vTypeNumber == 6) ; Kiosk Computer
	;{
		;RunLog(Kiosk)
	;}
	
	if(vNumErrors != 0) ; Final Check for errors and closes program.
	{
		Log("!! Configuration Incomplete! There were " vNumErrors . " errors with this program.")
		SoundPlay *16
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
	}
	else
	{
		Log("== Configuration Complete! There were " vNumErrors . " errors with this program.")
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce, SelfDelete, %comspec% /c RD /S /Q C:\IT\Deployment ; Deletes configuration package on reboot
		SoundPlay *64
		MsgBox, 64, Deployment Complete,  New computer deployment complete! The computer will now reboot., 10 ; MsgBox times out after 10 seconds.
		Shutdown, 2 ; Reboots computer.
		ExitApp
	}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

#Include, labels.ahk