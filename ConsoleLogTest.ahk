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
Global vWireless  ; Stores wireless toggle value.
Global vComputerName ; Stores input computer name.
Global vLocation  ; Stores the value extracted from Location array at vBranchNumber index.
Global vComputerType  ; Stores the value extracted from ComputerType array at vTypeNumber index.
Global vLPTServers ; Stores the value extracted from the LPTServers array ay vBranchNumber index.
Global vDistiguishedName := "" ; Stores the Distuguished Name for transferring the OU
Global vNumErrors := 0	; Tracks the number of errors, if any.

;   ================================================================================
;	BEGIN INITIALIZATION
;   ================================================================================
Try {
	Gui, New,, ConsoleWindow
	Gui, Font,, Lucida Console
	Gui, Add, Edit, Readonly x10 y10 w620 h460 vConsole ; I guess not everything has to be a function...
	Gui, Show, x20 y20 w640 h480, Console Window
	Log("   Console window up.")
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
Command("Testing command")
createOptionsWindow() ; Here is where we construct the GUI --- HERE IS WHERE THE LOG BREAKS

Return

;   ================================================================================
;	MAIN
;   ================================================================================

__main__:
{
	Command(vComputerName)
	Command(vLocation)
	Command(vComputerType)
	Command(vIsWireless)
	
	if(vNumErrors != 0) ; Final Check for errors and closes program.
	{

		Log("== Configuration Incomplete! There were "%vNumErrors% . " errors with this program.",3)
		MsgBox, 16, Configuration Error,  There were %vNumErrors% errors during the configuration process!`nSomething may not have configured or installed propery.`nCheck the log for more details.
		ExitApp
	}
	else
	{

		Log("== Configuration Complete! There were "%vNumErrors% . " errors with this program.",3)
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

Command(vCommand, vHide := "") ; Runs a configuration command.
{
	Log("Executing: "vCommand)
	Try {
		MsgBox %vCommand%
		} Catch {
		vNumErrors += 1
		Log("Error executing "vCommand . "!")
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

createOptionsWindow() ; Create the main GUI. 
{
	Gui, New,, Computer Deployment
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
	Gui, Add, GroupBox, Section r4 ys, Select computer type:
	Gui, Font, Norm
	Gui, Add, Radio, altsubmit vvTypeNumber xp+10 yp+20, Office Staff
	Gui, Add, Radio, altsubmit, Frontline Staff
	Gui, Add, Radio, altsubmit, Patron Computer
	Gui, Add, Radio, altsubmit, Catalog Computer			
	;Gui, Add, Radio, altsubmit, Self-Checkout Station		<- To Be Implimented
	;Gui, Add, Radio, altsubmit, Print Kiosk				<- To Be Implimented
	Gui, Font, Bold s10
	Gui, Add, Checkbox, xs vvWireless, This is a Wireless computer. ; Wireless check toggle.
	Gui, Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui, Add, Button, Section gButtonInstall w100, Install
	Gui, Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui, Show
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

Log(msg, Type="3") ; 1 logs to file, 2 logs to console, 3 does both, 10 is just a newline to file
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
GuiControlGet, Console
GuiControl,, Console, %Console%%msg%`r`n
}