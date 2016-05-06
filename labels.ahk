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
	vLocation := aLocation[vBranchNumber]
	vComputerType := aComputerType[vTypeNumber]
	vLPTServers := aLPTServers[vBranchNumber]
	ConfirmationWindow()
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