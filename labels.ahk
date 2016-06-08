ButtonExit: ; Label for Exit button. (WORKS)
{
	SoundPlay *48
	MsgBox, 52, Exiting Configure-Image, This will end Configure-Image.`nAre you sure you want to exit?
    IfMsgBox, No
		Return
	Log("-- User is exiting Configure-Image`, dying now.")
	ExitApp
}

ButtonStart: ; Label for Install button. Takes user input and prepares to run installers, confirming first. (WORKS)
{
	Gui, Submit, NoHide
	ConfirmationWindow(vIsWireless, vLocation, vComputerType, vComputerName)
	Return
}	

ClosePCReservation: ; Label that closes Envisionware window after its installation.
{
	CoordMode, Mouse, Screen
	MouseMove, (20), (A_ScreenHeight - 20)
	Sleep, 250
	Send, {Ctrl Down}{Click}{Ctrl up}
	Sleep, 250
	Send envisionware{enter}{enter}
	Return
}

CreateOptionsWindow: ; Label which creates the main GUI.
{
	Gui 2: New, , Computer Deployment
;----This Section contains the Computer Name label and field.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text,, Type in new computer name:
	Gui 2: Font, Norm
	Gui 2: Add, Edit, Uppercase vvComputerName,
;----This section contains a Drop Down Lists for Library locations and computer types.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Text, Section, Select Branch:
	Gui 2: Font, Norm
	Gui 2: Add, DDL, vvLocation, Branch...||ESA|MRL|MOM|KL|AFL|EV|JOH|ND
	Gui 2: Font, Bold s10
	Gui 2: Add, Text,, Select computer type:
	Gui 2: Font, Norm
	Gui 2: Add, DDL, vvComputerType, Computer...||Office|Frontline|Patron|Catalog
;----This section contains Checkbox toggles.----
	Gui 2: Font, Bold s10
	Gui 2: Add, Checkbox, Section vvIsWireless, This is a Wireless computer. ; Wireless check toggle.
	Gui 2: Add, Checkbox, vvIsVerbose, Use Verbose logging. ; Verbose logging toggle.
	Gui 2: Font, Norm
;----This Section contains Submit and Exit Buttons.----
	Gui 2: Add, Button, Section gButtonStart w100, Start
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