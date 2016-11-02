
ConfirmationWindow(Wireless, Location, Computer, Name) ; Checks that selections are correct before continuing.
{
	Gui +OwnDialogs
	if(Wireless == 1)
		WirelessText := "This is a Wireless computer."
	else
		WirelessText := "This is an Ethernet computer."
		
	if (Computer == "Office")
		TypeText := "This will install:`n- Sierra`n- Office for staff computer`n- Staff printers"
	if (Computer == "Frontline")
		TypeText := "This will install:`n- Sierra`n- Offline Circulation`n- Staff printers`n- PC Reservation Reservation Station`n- Envisionware Print Release station`n- Auto Logon configuration for staff"
	if (Computer == "Patron")
		TypeText := "This will install:`n- Office for patron computer`n- Envisionware PC Reservation client`n- Envisionware LPTOne printer client`n- PatronAdminPanel`n- Auto Logon configuration for patrons"	
	if (Computer == "Catalog")
		TypeText := "This will install:`n- EncoreAlways`n- Auto Logon configuration for catalogs"
		
	if(Name == "")
	{
		SoundPlay *48
		MsgBox, 48, Not Named, Please type in a name for the computer.
		Return
	}
	if(StrLen(Name) > 15)
	{
		SoundPlay *48
		MsgBox, 48, Large Name, The computer name is too long.`nPlease input a name that is fifteen characters or less.
		Return
	}
	if(Location == "Branch...")
	{
		SoundPlay *48
		MsgBox, 48, No Library, Please select a library branch.
		Return
	}
	if(Computer == "Computer...")
	{
		SoundPlay *48	
		MsgBox, 48, No Computer, Please select a computer type.
		Return
	}
	SoundPlay *32
	MsgBox, 36, Confirm, Please confirm the following:`nName: %Name%`nLocation: %Location%`nRole: %Computer%`n%WirelessText% `n%TypeText% `nIs this correct?
	IfMsgBox, Yes
	{
		Log("-- Selections complete:")
    ;Log("-- " WirelessText " It is at " Location " and it will be named " Name ". " TypeText)
    Log("--                Name: " Name)
    Log("--            Location: " Location)
    Log("--             Network: " WirelessText)
		Gosub __main__
    MsgBox Cthuhlu!
	}
	Return
}




; everything below this should remain a function


DoTasks(arrTasks) ; Loops through an array of task commands, trying and logging each one.
{
	
	;MsgBox % "DoTasks():`n" . "arrTasks.MaxIndex() " . arrTasks.MaxIndex()
	Loop % arrTasks.MaxIndex()
	{
    Task := arrTasks[A_Index]
    Try {
      If(vIsVerbose == 1)
      {
        Log("** Executing: " Task)
      } else {
        Log("** Executing: " Task, 1)
      }
    ;RunWait, Task
   ;MsgBox % "Task Number: " . A_Index . "`n" . "Task: `n" . Task
    } Catch {
    iTaskErrors += 1
    Log("!! Error attempting "Task . "!")
    }
  }
  Return iTaskErrors
}

ExitFunc(ExitReason, ExitCode) ; Checks and logs various unusual program closures.
{
	Gui +OwnDialogs
	if ExitReason in Menu,
    {
		SoundPlay *48
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

Log(msg, Type=3) ; 1 logs to file, 2 logs to console, 3 does both, 10 is just a newline to file.
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
	Return
}

Message(msg) ; For logging to Console window.
{
GuiControlGet, Console, 1:
GuiControl, 1:, Console, %Console%%msg%`r`n
}