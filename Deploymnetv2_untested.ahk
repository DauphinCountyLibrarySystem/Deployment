/* 	
	Name: New Computer Deployment		
	Version: 2.0
	Author:	Christopher Roth

	Changelog:

		2.0
		* Improved interface design
		* Improved code readability
		* Uses some code from Lucas Bodnyk's SierraWrapper
		* Code now uses functions!
*/
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
aLocation := {1: "esa", 2: "kl", 3: "mom", 4: "mrl", 5: "afl", 6: "joh", 7: "ev", 8: "nd"} ; Stores list of library locations.
aCompType := {1: "office"} ; Stores list of computer types to deploy.
vBranch := ""
vType := ""	
vWireless := ""
vCompname := ""
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
WinMinimizeAll
createWindow() ; Here is where we construct the GUI 


;   ================================================================================
;	PRE-INSTALL CHECKS
;   ================================================================================
; here we want to make sure that everything will work, so let's test that we have the files for the actions we want to perform.
; the following should tell us if the file is locked.
Log("== Performing file checks...")
;checkFile("some option")
;checkFile("some option")
;checkFile("some option")

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	Log("== Main Process...")
	;If zIsWireless {
	;	Install("wirelessprofile")
	;	Install("spiceworks")
	;}
	;If (zType == "Frontline" OR zType == "Patron" OR zType == "Catalog") {
	;	Install("%zLocation%-autologon")
	;}
	;If (zType == "Patron") {
	;	Install("%zLocation%-firstfile") 
	;	Install("%zLocation%-firstfile") 
	;}

	;If (zType == "Frontline") OR (zType == "Office") {
	;	Install("%Sierra.exe") 
	;}
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

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
ButtonInstall:
{
	Gui, Submit, NoHide
	ConfirmationWindow()
	Return
}
ButtonExit:
{
}
ExitFunc(ExitReason, ExitCode)
{
	if ExitReason in Menu
    {
        MsgBox, 4, , This will cancel deployment.`nAre you sure you want to exit?
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

CreateWindow() 
	{
;----This section creates a toggle for Library locations.----
	Gui, Font, Bold s10
	Gui, Add, GroupBox, r8, Select Branch:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvBranch xp+10 yp+20, East Shore
	Gui, Add, Radio, altsubmit, Kline Library
	Gui, Add, Radio, altsubmit, Madeline Olewine
	Gui, Add, Radio, altsubmit, McCormick Riverfront
	Gui, Add, Radio, altsubmit, Alexander Family
	Gui, Add, Radio, altsubmit, Johnson Memorial
	Gui, Add, Radio, altsubmit, Elizabethville
	Gui, Add, Radio, altsubmit, Northern Dauphin
	Gui, Add, Checkbox, x10 vvWireless, This is a wireless computer.
;----This section creates a toggle for computer type.----
	Gui, Font, Bold s10
	Gui, Add, GroupBox, ym r6, Select computer type:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvType xp+10 yp+20, East Shore
	Gui, Add, Radio, altsubmit, Office Staff
	Gui, Add, Radio, altsubmit, Frontline Staff
	Gui, Add, Radio, altsubmit, Patron Computer
	Gui, Add, Radio, altsubmit, Catalog Computer
	Gui, Add, Radio, altsubmit, Self-Checkout
	Gui, Add, Edit, Uppercase vvCompname, Enter computer name:
	Gui, Add, Button, gButtonInstall, Install
	Gui, Add, Button, gButtonExit, Exit
	Gui, Show
	Return
	}

ConfirmationWindow() {
	}
	
/*	
checkFile() {
Log("Checking for %file%")
Try { 
	FileMove, %File%, %File%
	} Catch {
		
	}
	
InstallWireless() {
	Try {
		RunWait, wirelessprofile
		} Catch {
			Log("Install for %install% failed!")
			}
	Try {
		RunWait, spiceworks
		} Catch {
			Log("Install for %install% failed!")
			}
	}
	
InstallPatron() {
	Try {
		RunWait, wirelessprofile
		} Catch {
			Log("Install for %install% failed!")
			}
	Try {
		RunWait, spiceworks
		} Catch {
			Log("Install for %install% failed!")
			}
*/