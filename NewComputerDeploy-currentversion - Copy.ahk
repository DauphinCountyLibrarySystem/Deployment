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
Gui, New, , Computer Deployment
vMyloc := null
aStaff := {1: "esastf", 2: "klstf", 3: "momstf", 4: "mrlstf", 5: "aflstf", 6: "johstf", 7: "evstf", 8: "ndstf"}
aOffce := {1: "esaoff", 2: "kloff", 3: "momoff", 4: "mrloff", 5: "afloff", 6: "johoff", 7: "evoff", 8: "ndoff"}
aPatrn := {1: "esapat", 2: "klpat", 3: "mompat", 4: "mrlpat", 5: "aflpat", 6: "johpat", 7: "evpat", 8: "ndpat"}
aCatlg := {1: "esacat", 2: "klcat", 3: "momcat", 4: "mrlcat", 5: "aflcat", 6: "johcat", 7: "evcat", 8: "ndcat"}
aLpton := {1: "esaplt", 2: "kllpt", 3: "momlpt", 4: "mrllpt", 5: "afllpt", 6: "johlpt", 7: "evlpt", 8: "ndlpt"}
aSelfc := {1: "esaslf", 2: "klslf", 3: "momslf", 4: "mrlslf", 5: "aflslf", 6: "johslf", 7: "evslf", 8: "ndslf"}
; This section creates a toggle for Library locations.
Gui, Font, Bold s10
Gui, Add, GroupBox, r8, Select Branch:
Gui, Font, Norm
Gui, Add, Radio, altsubmit gSetloc vBranch xp+10 yp+20, East Shore
Gui, Add, Radio, altsubmit gSetloc, Kline Library
Gui, Add, Radio, altsubmit gSetloc, Madeline Olewine
Gui, Add, Radio, altsubmit gSetloc, McCormick Riverfront
Gui, Add, Radio, altsubmit gSetloc, Alexander Family
Gui, Add, Radio, altsubmit gSetloc, Johnson Memorial
Gui, Add, Radio, altsubmit gSetloc, Elizabethville
Gui, Add, Radio, altsubmit gSetloc, Northern Dauphin

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
Gui, Add, Checkbox, ym vWrls, This is a wireless computer.
Gui, Show, AutoSize
Return ;Initializes variables and creates GUI. 

Setloc: ;Subroutine to change branch location
	{	
		Gui, Submit, NoHide
		vMyloc = Branch
		Return
	}
FinalRun: ;Subrotine that contains the final path to run the installers
	{	
		Gui, Submit, NoHide
		if(vMyloc == null)
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
		vInstaller := aStaff[Branch]
		Gosub, FinalRun
		Return
	}

Boffce: ;Office Computer subroutine.
	{
		vInstaller := aOffce[Branch]
		Gosub, FinalRun
		Return
	}

Bpatrn: ;Paton computer subroutine.
	{
		vInstaller := aPatrn[Branch]
		Gosub, FinalRun
		Return
	}

Bcatlg: ;Catalog subroutine.
	{
		vInstaller := aCatlg[Branch]
		Gosub, FinalRun
		Return
	}

Blpton: ;Print/Reservation Kiosk computer.
	{
		vInstaller := aLpton[Branch]
		Gosub, FinalRun
		Return
	}

Bslfch: ;Self-check subroutine
	{
		vInstaller := aSelfc[Branch]
		Gosub, FinalRun
		Return
	}
GuiClose:
	ExitApp