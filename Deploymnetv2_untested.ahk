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
Global aCompType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog", 5: "Selfcheck"} ; Stores list of computer types to deploy.
Global vBranch ; Stores the value of the Location array index.
Global vType ; Stores the value of the CompType array index.
Global vWireless ; Stores wireless toggle value.
Global vCompname ; Stores input computer name.
Global vMyLocation ; Stores the value extracted from Location array at vBranch index.
Global vMyComp ; Stores the value extracted from CompType array at vType index.

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
Return

;   ================================================================================
;	PRE-INSTALL CHECKS
;   ================================================================================
; here we want to make sure that everything will work, so let's test that we have the files for the actions we want to perform.
; the following should tell us if the file is locked.
Log("== Performing file checks...")
Return

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	Log("== Main Process...")
	if(vWireless == 1)
		RunWait wirelessprofile.ahk
	Install(vMyLocation, vMyComp)
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================
ButtonInstall: ; Label that takes user input and prepares to run installers, confirming first.
{
	Gui, Submit, NoHide
	vMyLocation := aLocation[vBranch]
	vMyComp := aCompType[vType]
	ConfirmationWindow()
	Return
}

ButtonExit:
	ExitApp
	
GuiClose:
	ExitApp
	
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

ExitFunc(ExitReason, ExitCode)
{
	Gui +OwnDialogs
	if ExitReason in Menu,Exit
    {
        MsgBox, 52, Exiting Deployment, This will cancel deployment.`nAre you sure you want to exit?
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

CreateWindow() ; Create the main GUI. 
{
	Gui, New, , Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui, Font, Bold s10
	Gui, Add, Text,, Type in new computer name:
	Gui, Font, Norm
	Gui, Add, Edit, Uppercase vvCompname,
;----This section contains a Radio toggle for Library locations.----
	Gui, Font, Bold s10
	Gui, Add, GroupBox, Section r8, Select Branch:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvBranch xp+10 yp+20, East Shore
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
	Gui, Add, Radio, altsubmit vvType xp+10 yp+20, Office Staff
	Gui, Add, Radio, altsubmit, Frontline Staff
	Gui, Add, Radio, altsubmit, Patron Computer
	Gui, Add, Radio, altsubmit, Catalog Computer
	Gui, Add, Radio, altsubmit, Self-Checkout Station
	Gui, Font, Bold s10
	Gui, Add, Checkbox, xs vvWireless, Check if a wireless computer. ; Wireless check toggle.
	Gui, Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui, Add, Button, Section gButtonInstall w100, Install
	Gui, Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui, Show
	Return
}

ConfirmationWindow() ; Checks that selections are correct before continuing.
{
	Gui +OwnDialogs
	if(vWireless = 1)
		vIsWireless := "This is a Wireless computer."
	if(vWireless = 0)
		vIsWireless := "This is a Ethernet computer."
	if(vCompname == "")
	{
		MsgBox, 48, Not Named, Please type in a name for the computer.
		Return
	}
	if(vMyLocation == "")
	{
		MsgBox, 48, No Library, Please select a library branch.
		Return
	}
	if(vMyComp == "")
	{
		MsgBox, 48, No Computer, Please select a computer type.
		Return
	}
	MsgBox, 36, Confirm, This will install to a computer named %vCompname%.`nThis is a %vMyComp% computer at %vMyLocation%.`n%vIsWireless% `nIs this correct?
	IfMsgBox, Yes
		Gosub __main__
	Return
}

Install(loc, com) ; Passed the location and computer types runs an installer with a matching name.
{
	RunWait %loc%%com%.ahk
	Return
}