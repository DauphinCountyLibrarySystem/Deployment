/* 	
	Name: New Computer Deployment		
	Version: 0.2.1
	Authors: Christopher Roth, Lucas Bodnyk

	Changelog:
		* Added .ini file.
		* Added .ini reads to pull passwords from file.
*/

;   ================================================================================
;	CONFIGURATION
;   ================================================================================
Global aLPTServers := {"ESA": 192.168.100.221, "MRL": 10.11.20.5, "MOM": 10.13.20.14, "KL": 10.14.20.14, "AFL": 192.168.102.221, "JOH": 192.168.106.221, "EV": 192.168.105.221, "ND":  10.18.40.200} ; Stores list of LPTOne server IPs.
IniRead, vActivationKey, KeysAndPasswords.ini, Keys, Windows10  ; Windows activation key (pulled from external file).
IniRead, vSpiceworksKey, KeysAndPasswords.ini, Keys, Spiceworks ; Spiceworks authentication key (pulled from external file).
IniRead, vOUPassword, KeysAndPasswords.ini, Passwords, OUPassword ;Password for OU move (pulled from external file).
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
Global vIsWireless  ; Stores wireless checkbox value.
Global vIsVerbose ; Stores Verbose logging checkbox value.
Global vComputerName ; Stores input computer name.
Global vLocation  ; Stores the value extracted from location Drop Down List
Global vComputerType  ; Stores the value extracted from ComputerType Drop Down List
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
	Log("== Starting Configuration")
	vOUPath := CreateOUPath(vLocation, vComputerType, vIsWireless) ; Creates distinguished name for OU move
	aDefaultList := DefaultTasks(vOUPassword, vIsWireless) ; Creates default task list, with wireless tasks if needed.
	aTypeList := CreateTaskList(vComputerType) ; Creates list of tasks specific to computer type.
	Log("-- Default Configuration")
	DoTasks(aDefaultList)
	Log("-- "%vComputerType% . " Computer Configuration")
	DoTasks(aTypeList)
	
	if(vComputerType != "Office")
	{	
		Log("-- Configuring Auto-Logon")
		IniRead, vLogonPassword, KeysAndPasswords.ini, Passwords, %vComputerType% ; Password for AutoLogon function (pulled from external file).
		AddAutoLogon(vLocation, vComputerType, vLogonPassword)
	}
	Log("-- Editing Registy and Clearing Files")
	RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui, EnableSystray, 0
	FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk
	FileDelete C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk
	
	if(vComputerType == "Patron")
	{
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, PatronAdminPanel, ""C:\PatronAdminPanel\PatronAdminPanel.exe"" ; Set PatronAdminPanel auto-start.
		Sleep 15000
		Gosub ClosePCReservation
	}
	
	if(vComputerType == "Catalog")
		RegWrite, REG_SZ, HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run, EncoreAways, ""C:\EncoreAlways\EncoreAlways.exe"" ; Set EncoreAways auto-start
	
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