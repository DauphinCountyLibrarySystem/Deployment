/*
						***NEW COMPUTER DEPOYMENT APP***
	App that allows for the quick, automatic installation of new computers.
	Author: Christopher Roth
*/
if not A_IsAdmin ;checks that script is running in admin mode, and restarts in that mode if not.
{
   Run *RunAs "%A_ScriptFullPath%"
   ExitApp
}
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
;----Embed installer files (testing scripts for this version)
FileInstall, C:\Users\croth\Documents\GitHub\Deployment\wesastf.ahk, wesastf.ahk
FileInstall, C:\Users\croth\Documents\GitHub\Deployment\esastf.ahk, esastf.ahk
;----Initialize GUI, global variables, and arrays----
aLoca:= {1: "esa", 2: "kl", 3: "mom", 4: "mrl", 5: "afl", 6: "joh", 7: "ev", 8: "nd"}
aComp:= {1: "stf", 2: "off", 3: "pat", 4: "lpt", 5: "ksk", 6: "chk"}
Gui, New, , Computer Deployment
; This section creates a toggle for Library locations.
Gui, Font, Bold s10
Gui, Add, GroupBox, r8, Select Branch:
Gui, Font, Norm
Gui, Add, Radio, altsubmit vBranch xp+10 yp+20, East Shore
Gui, Add, Radio, altsubmit, Kline Library
Gui, Add, Radio, altsubmit, Madeline Olewine
Gui, Add, Radio, altsubmit, McCormick Riverfront
Gui, Add, Radio, altsubmit, Alexander Family
Gui, Add, Radio, altsubmit, Johnson Memorial
Gui, Add, Radio, altsubmit, Elizabethville
Gui, Add, Radio, altsubmit, Northern Dauphin
Gui, Add, Checkbox, x10 vWrls, This is a wireless computer.
; This section creates the buttons that select the type of computer.
Gui, Font, Bold
Gui, Add, Text, ym, Select Computer Type:
Gui, Font, Norm
Gui, Add, Button, gBstaff xp+10 yp+20 w100, Staff
Gui, Add, Button, gBoffce w100, Office
Gui, Add, Button, gBcatlg w100, Catalog
Gui, Add, Button, gBpatrn w100, Patron
Gui, Add, Button, gBlpton w100, Kiosk
Gui, Add, Button, gBslfch w100, Self-Check

Gui, Show, AutoSize
Return ;Initializes variables and creates GUI. 

FinalRun: ;Subrotine that contains the final path to run the installers
	{	
		Gui, Submit, NoHide
		if(Branch == 0)
		{
			MsgBox, 48, No Library, Please select a library branch.
			Return
		}
		else
		{
			if(Wrls == 1) ;check for wireless toggle
			{
				IfExist, w%vInstaller%.ahk
				{
					Run, w%vInstaller%.ahk
					Return
					; MOBILE
					; - Wireless Profile
					; - Spiceworks Agent

				}
				else
				{
					MsgBox, 48, Installer Not Found, The installer cannot be found at the specified path.
					Return
				}
				Return
			}
			else
			{
				IfExist, %vInstaller%.ahk
				{
					Run, %vInstaller%.ahk
					Return
					; ALL
					; - Rename
					; - Domain Join
					; - Autologon
					; - Logmein
					; - Vipre
					; - OU move
				}
				else
				{
					MsgBox, 48, Installer Not Found, The installer cannot be found at the specified path.
					Return
				}
				Return
			}
			Return
		}
	Return
	}	
Bstaff: ;Staff Computer subroutine
	{
		Gui, Submit, NoHide
		vType := 1
		vInstaller := aLoca[Branch]aComp[vType]
		; FRONTLINE
		; - Printers
		; - Sierra
		; - Offline Circ
		; - PC Reservation Station
		Gosub, FinalRun
		Return
	}

Boffce: ;Office Computer subroutine.
	{
		Gui, Submit, NoHide
		vType := 2
		vInstaller := aLoca[Branch]aComp[vType]
		; OFFICE
		; - Printers
		; - MS Office
		Gosub, FinalRun
		Return
	}

Bpatrn: ;Patron computer subroutine.
	{
		Gui, Submit, NoHide
		vType := 3
		vInstaller := aLoca[Branch]aComp[vType]
		; PATRON
		; - PC Reservation
		; - LPTOne
		; - MS Office (No Outlook)
		Gosub, FinalRun
		Return
	}

Bcatlg: ;Catalog subroutine.
	{	
		Gui, Submit, NoHide
		vType := 4
		vInstaller := aLoca[Branch]aComp[vType]
		; CATALOG
		; - Catalog Script
		Gosub, FinalRun
		Return
	}

Blpton: ;Print/Reservation Kiosk computer.
	{
		Gui, Submit, NoHide
		vType := 5
		vInstaller := aLoca[Branch]aComp[vType]
		; KIOSK
		; Kiosk Software
		Gosub, FinalRun
		Return
	}

Bslfch: ;Self-check subroutine
	{
		Gui, Submit, NoHide
		vType := 6
		vInstaller := aLoca[Branch]aComp[vType]
		; SELF CHECK
		; Self-Check Software
		Gosub, FinalRun
		Return
	}
GuiClose:
	ExitApp