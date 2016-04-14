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
Global aComputerType := {1: "Office", 2: "Frontline", 3: "Patron", 4: "Catalog", 5: "Selfcheck"} ; Stores list of computer types to deploy.
Global vBranchNumber ; Stores the value of the Location array index.
Global vTypeNumber ; Stores the value of the CompType array index.
Global vWireless ; Stores wireless toggle value.
Global vComputerName ; Stores input computer name.
Global vLocation ; Stores the value extracted from Location array at vBranchNumber index.
Global vComputerType ; Stores the value extracted from CompType array at vTypeNumber index.
Global vNumInstallErrors := 0

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
;	PRE-INSTALL CHECKS
;   ================================================================================
; here we want to make sure that everything will work, so let's test that we have the files for the actions we want to perform.
; the following should tell us if the file is locked.
;Log("== Performing file checks...")
;CheckFile("ESAOffice.ahk")
;CheckFile("WillFail.ahk")

;   ================================================================================
;	STARTUP
;   ================================================================================
Log("== Starting Up...")
WinMinimizeAll
createWindow() ; Here is where we construct the GUI 
Return

;   ================================================================================
;	MAIN
;   ================================================================================
__main__:
{
	Log("== Main Process...")
	if(vWireless == 1) ; If wireless, install wireless profile and Spiceworks.
		Install("default\wireless.ahk")
	Install("default\rename.ahk",vComputerName) ;--|
	Install("default\join-domain.ahk")			;  |-- Renames, joins domain, and sends to OU.
	Install("default\SendTo-OU.ahk")			;--|
	if(vTypeNumber > 1 ) ; If a type other than Office, install autologon.
		Install("computers\autologon.ahk", vLocation, vComputerType)
	if(vTypeNumber == 1 or vTypeNumber == 2) ; Office or Staff computers get printers and Sierra.
	{
		Install("computers\printers.ahk", vLocation, vComputerType)
		Install("computers\sierra.ahk")
	}
	if(vTypeNumber ==1) ; Office staff get full Microsoft Office software.
		Install("computers\msoffice.ahk", vComputerType)
	if(vTypeNumber == 2) ; Staff computers get Offline Circ and PC Reservation Station.
	{
		Install("computers\offlinecirc.ahk")
		Install("computers\PCresstation.ahk", vLocation)
	}
	if(vTypeNumber == 3) ; Patron computers get PC reservation Client, Office without Outlook, and LPTone printers.
	{
		Install("computers\PCresclient.ahk")
		Install("computers\msoffice.ahk", vComputerType)
		Install("computers\lptone.ahk")
	}
	if(vTypeNumber == 4) ; Catalog script is installed.
		Install("computers\catalog.ahk")
	if(vTypeNumber == 5) ; Self-Checkout terminal software is installed.
		Install("computers\selfcheck.ahk")
	if(vNumInstallErrors != 0)
		MsgBox, 16, Installation Error,  There were %vNumInstallErrors% errors during the installation! Check the log for more details.
	Return
}
;   ================================================================================
;	FUNCTIONS AND LABELS
;   ================================================================================

ButtonExit: ; Label for the Exit button.
	ExitApp
	
ButtonInstall: ; Label that takes user input and prepares to run installers, confirming first.
{
	Gui, Submit, NoHide
	vLocation := aLocation[vBranchNumber]
	vComputerType := aComputerType[vTypeNumber]
	ConfirmationWindow()
	Return
}
	
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
	Gui, Font, Bold s10
	Gui, Add, Checkbox, xs vvWireless, Check if a wireless computer. ; Wireless check toggle.
	Gui, Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui, Add, Button, Section gButtonInstall w100, Install
	Gui, Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui, Show
	Return
}

Install(vInstallPath, vParameter1 :="", vParameter2 :="") ; locates installer file with passed name sting, and logs if it fails.
{
	Try {
		Log("Installing: "vInstallPath . " with parameters: "vParameter1 . ", "vParameter2)
		RunWait %A_ScriptDir%\%vInstallPath% "%vParameter1% %vParameter2%"
		} Catch {
		vNumInstallErrors += 1
		Log("Error installing "vInstallPath . "!")
		}
	Return
}