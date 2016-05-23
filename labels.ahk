ButtonExit: ; Label for the Exit button. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

ButtonInstall: ; Label that takes user input and prepares to run installers, confirming first. (WORKS)
{
	Gui, Submit, NoHide
	vLocation := aLocation[vLocationNumber]
	vComputerType := aComputerType[vTypeNumber]
	ConfirmationWindow(vIsWireless, vLocation, vComputerType, vComputerName)
	Return
}	

ClosePCReservation:
{
	CoordMode, Mouse, Screen
	MouseMove, (20), (A_ScreenHeight - 20)
	Sleep, 250
	Send, {Ctrl Down}{Click}{Ctrl up}
	Sleep, 250
	Send envisionware{enter}{enter}
	Return
}

CreateOptionsWindow: ; Create the main GUI. 
{
	Gui 2: New, , Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text,, Type in new computer name:
	Gui 2: Font, Norm
	Gui 2: Add, Edit, Uppercase vvComputerName,
;----This section contains a Radio toggle for Library locations.----
	Gui 2: Font, Bold s10
	Gui 2: Add, GroupBox, Section r8, Select Branch:
	Gui 2: Font, Norm
	Gui 2: Add, Radio, altsubmit vvLocationNumber xp+10 yp+20, East Shore
	Gui 2: Add, Radio, altsubmit, McCormick Riverfront
	Gui 2: Add, Radio, altsubmit, Madeline Olewine
	Gui 2: Add, Radio, altsubmit, Kline Library
	Gui 2: Add, Radio, altsubmit, Alexander Family
	Gui 2: Add, Radio, altsubmit, Elizabethville
	Gui 2: Add, Radio, altsubmit, Johnson Family
	Gui 2: Add, Radio, altsubmit, Northern Dauphin
;----This Section contains a Radio toggle for computer type.----
	Gui 2: Font, Bold s10
	Gui 2: Add, GroupBox, Section r4 ys, Select computer type:
	Gui 2: Font, Norm
	Gui 2: Add, Radio, altsubmit vvTypeNumber xp+10 yp+20, Office Staff
	Gui 2: Add, Radio, altsubmit, Frontline Staff
	Gui 2: Add, Radio, altsubmit, Patron Computer
	Gui 2: Add, Radio, altsubmit, Catalog Computer			
	;Gui 2: Add, Radio, altsubmit, Self-Checkout Station		<- To Be Implimented
	;Gui 2: Add, Radio, altsubmit, Print Kiosk				<- To Be Implimented
;----This section contains Checkbox toggles.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Checkbox, Section xs vvIsWireless, This is a Wireless computer. ; Wireless check toggle.
	Gui 2: Add, Checkbox, vvIsVerbose, Use Verbose logging. ; Verbose logging toggle.
	Gui 2: Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui 2: Add, Button, Section gButtonInstall w100, Install
	Gui 2: Add, Button, yp xp+110 gButtonExit w100, Exit
	Gui 2: Show
	Return
}

GuiClose: ; Label for default close functions, prompts confirmation screen. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

2GuiClose: ; Label for default close functions in second GUI, prompts confirmation screen. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}