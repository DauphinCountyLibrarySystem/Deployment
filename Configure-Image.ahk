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
Global vEwareServers ; Stores the value extracted from the LPTServers array ay vBranchNumber index.
Global vOUPath := "" ; Stores the Distinguished Name for transferring the OU.
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
	if(vWireless == 1) ; If wireless, install wireless profile and Spiceworks.
	{
		Log("== Wireless Configuration...")
		Log("-- adding wireless profile...")
		;Command("cmd.exe /c netsh wlan add profile filename="A_ScriptDir . "\Resources\WirelessProfile.xml user=all") ; Install Wireless Profile
		Sleep 5000 ; Wait for profile to update.	
		Log("-- installing Spiceworks mobile app...")
		;Command("msiexec.exe /i "A_ScriptDir . "\Resources\_Spiceworks.msi SPICEWORKS_SERVER=""spiceworks.dcls.org"" SPICEWORKS_AUTH_KEY="" eb7e922f71BB336280238a02c02c64ac35941be2b"" SPICEWORKS_PORT=443 /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") ; Install Spiceworks Mobile
	}	
	
	Log("== Default Configuration...")	
	Log("-- activating Windows...")
	;Command("cscript //B c:\windows\system32\slmgr.vbs /ipk HRRBN-GYBYT-44FP9-3TDPY-B4G6B") ; Copy activation key.
	;Command("cscript //B c:\windows\system32\slmgr.vbs /ato") ; Activate Windows.
	
	Log("-- joining domain with new name...")
	CreateOUPath() ; Creates distinguished name for OU move
	;Command("powershell.exe -NoExit -Command $pass = ConvertTo-SecureString -String \""0Bg17GCkCjtOYg03NOVU\"" -AsPlainText -Force; $mycred = new-object -typename System.Management.Automation.PSCredential -argumentlist unattend,$pass; Add-Computer -DomainName dcls.org -Credential $mycred -Force -NewName """ vComputerName """ -OUPath '" vOUPath "'") ; Join domain, Move OU.
	
	Log("-- installing VIPRE antivirus...")
	;Command("msiexec.exe /i "A_ScriptDir . "\Resources\_VIPRE.MSI /quiet /norestart /log "A_ScriptDir . "\vipre_install.log") ; Install VIPRE antivirus. (WORKS) 
	
	Log("-- installing LogMeIn...")
	;Command("msiexec.exe /i "A_ScriptDir . "\Resources\_LogMeIn.msi /quiet /norestart /log "A_ScriptDir . "\logmein_install.log") ; Install LogMeIn. (WORKS)
	
	Log("-- editing registries and clearing files...")
	;RegWrite, Reg_SZ, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui /f /v EnableSystray /t REG_DWORD /d 0
	;FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk"
	;FileDelete "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk"
	
	if(vTypeNumber == 1) ; Office staff get Office365, staff printers, and Sierra.
	{ 
		Log("== Office Staff Configuration...")	
		Log("-- installing Sierra files...")
		Command("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.	
		
		Log("-- configuring Office for staff...")
		Command("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_staff.xml")
		
		Log("-- updating Desktop shortcuts...")
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Sierra shortcut.
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Outlook*")
		
		Log("-- installing staff LPTOne print release...")
		Command(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
	}
	
	if(vTypeNumber == 2) ; Frontline computers get LPTOne staff, staff printers, Sierra, Offline Circ and remove Office.
	{
		Log("== Frontline Staff Configuration...")
		Log("-- configuring automatic logon...")
		;AddAutoLogon()
		
		Log("-- installing Sierra files...")
		Command("robocopy """A_ScriptDir . "\Resources\Sierra Desktop App"" ""C:\Sierra Desktop App"" /s") ; Sierra files.
		Command("robocopy "A_ScriptDir . "\Resources\Millennium C:\Millennium /s") ;  Offline circ files.
		
		Log("-- copying staff shortcuts...")
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop ADP*") ; ADP shortcut
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts\Printers C:\Users\Default\Desktop\Printers /s") ; Copy links to staff printers.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Sierra*" ) ; Sierra shortcut.
		Command("robocopy "A_ScriptDir . "\Resources\Shortcuts C:\Users\Public\Desktop Offline*") ; Offline Circ shortcut.		
		
		Log("-- installing staff LPTOne print release...")
		;Command(A_ScriptDir . "\Resources\Envisionware\_LPTOnePrintRelease.exe /S") ; Install staff Print Release Terminal.
		
		Log("-- installing staff Envisionware Reservation Station...")
		;Command(A_ScriptDir . "\Resources\Envisionware\_PCReservationStation.exe /S") ; Install Reservation Station
	}
	
	if(vTypeNumber == 3) ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		Log("== Patron Terminal Configuration...")
		Log("-- configuring automatic logon...")
		;AddAutoLogon()
		
		Log("-- installing PatronAdminPanel...")
		Command("robocopy "A_ScriptDir . "\Resources\PatronAdminPanel C:\PatronAdminPanel /s") ; PatronAdminPanel script files.
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, PatronAdminPanel, "C:\PatronAdminPanel\PatronAdminPanel.exe" ; Set PatronAdminPanel auto-start.
		
		Log("-- configuring Office for patrons...")
		Command("cmd.exe /c "A_ScriptDir . "\Resources\Office365\setup.exe /configure "A_ScriptDir . "\Resources\Office365\customconfiguration_patron.xml")
		
		Log("-- updating Desktop shortcuts...")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Word*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Excel*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop PowerPoint*")
		Command("robocopy ""C:\ProgramData\Microsoft\Windows\Start\Programs"" C:\Users\Public\Desktop Publisher*")
		
		Log("-- updating Start menu...")
		Command("robocopy C:\Users\Public\Desktop C:\ProgramData\Microsoft\Windows\Start Menu /s")
		
		Log("-- installing patron LPTOne printers...")
		Command(A_ScriptDir . "\Resources\Envisionware\_LPTOneClient.exe /S -jqe.host="%vEwareServers%) ; Patron printers.
		
		Log("-- installing patron Envisionware client...")
		Command(A_ScriptDir . "\Resources\Envisionware\_PCReservationClient.exe /S -ip="%vEwareServers% . " -tcpport=9432") ; Envisionware Client.
		Sleep 15000
		ClosePCReservation()
	}
	
	if(vTypeNumber == 4) ; Catalog script is installed.
	{
		Log("== Catalog Computer Configuration...")
		Log("-- configuring automatic logon...")
		AddAutoLogon()		
		
		Log("-- installing EncoreAlways script...")
		Command("robocopy "A_ScriptDir . "\Resources\EncoreAlways\ C:\EncoreAlways /s")	; EncoreAlways script files.
		
		Log("-- configuring catalog registries...")
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, EncoreAways, "C:\EncoreAlways\EncoreAlways.exe" ; Set EncoreAlways auto-start.
	}
	
	if(vTypeNumber == 5) ; Self-Checkout terminal software is installed.
	{
		;AddAutoLogon()
		;Command(Self-Check)
	}
	
	if(vTypeNumber == 6) ; Kiosk Computer
	{
		;Command(Kiosk)
	}
	
	if(vNumErrors != 0) ; Final Check for errors and closes program.
	{
		Log("!! Configuration Incomplete! There were "%vNumErrors% . " errors with this program.")
		SoundPlay *16
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
	}
	else
	{
		Log("== Configuration Complete! There were "%vNumErrors% . " errors with this program.")
		RegWrite, REG_SZ,HKEY_LOCAL_MACHINE,SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce, Application, %comspec% /c /s /q del "C:\IT\Deployment" ; Deletes configuration package on reboot
		SoundPlay *64
		MsgBox, 64, Deployment Complete,  New computer deployment complete! Rebooting in 10 seconds., 10 ; MsgBox times out after 10 seconds.
		Shutdown, 2 ; Reboots computer.
		ExitApp
	}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

#Include, labels.ahk