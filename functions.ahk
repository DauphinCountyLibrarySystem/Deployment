
ClosePCReservation(sec) ; a recursive function that closes Envisionware window after its installation. I'm quite proud of using recursion.
{
  DoLogging("-- ClosePCReservation() running: waiting for " sec " seconds...")
  Sleep (sec*1000)
  If ProcessExist("PC Reservation Client Module.exe")
  {
    DoLogging("-- Attempting to close PC Reservation Client...")
    CoordMode, Mouse, Screen
    MouseMove, (20), (A_ScreenHeight - 20)
    Sleep, 250
    Send, ^{Click} ; this should work better than: Send, {Ctrl Down}{Click}{Ctrl up}
    Sleep, 250
    Send envisionware{enter}{enter}
    Sleep, 1000 ; I'm trying to be generous here. It shouldn't take a second to close.
  }
  If ProcessExist("PC Reservation Client Module.exe")
  {
    sec -= 1 ; decrement each time we recurse
    If sec<1 ; our base case, as it were...
    {
      DoLogging("!! PC Reservation Client is still running, but ClosePCReservation() ran out of time!")
      Return 1
    }
    DoLogging(">< PC Reservation Client is still running, trying again...")
    Return ClosePCReservation(sec)
  }
  DoLogging("<> PC Reservation Client seems to be closed, returning...")
  Return 0
}

ProcessExist(Name)
{
  Process,Exist,%Name%
  return Errorlevel
}

DoExternalTasks(arrTasks, Verbosity) ; Loops through an array of task commands, trying and logging each one.
{
  iTaskErrors := 0
  Loop % arrTasks.MaxIndex()
  {
    Task := arrTasks[A_Index]
    Try {
      If (Verbosity == 1)
      {
        DoLogging("** "A_WorkingDir . "> " Task)
      } Else {
        DoLogging("** "A_WorkingDir . "> " Task, 1)
      }
      shell := ComObjCreate("WScript.Shell") ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
      exec := shell.Exec(ComSpec " /C " Task) ; Execute a single command via cmd.exe
      While !exec.StdOut.AtEndOfStream ;read the output line by line
      {
        DoLogging("   " exec.StdOut.ReadLine())
      }
      DoLogging("")
    } Catch {
      iTaskErrors += 1
      DoLogging("!! Error attempting External Task: "Task . "!")
    }
  }
  Return iTaskErrors
}

DoInternalTasks(arrTasks, Verbosity) ; Loops through an array of task commands, trying and logging each one.
{
  iTaskErrors := 0
  ; parse!
  Try {
    Loop % arrTasks.MaxIndex()
    {
      Task := arrTasks[A_Index]
      strParams := ""
      Loop % Task.MaxIndex()
      {
        Element := Task[A_Index]
        If (A_Index>1)
        {
          strParams := strParams . Element
        }
        If (A_Index>1 And A_Index<Task.MaxIndex())
        {
          strParams := StrParams . ","
        }
      }
      Output := Task[1] . "(" . strParams . ")"
      If (Verbosity == 1)
      {
        DoLogging("** Executing Internal Task: " Output)
      } Else {
        DoLogging("** Executing Internal Task: " Output, 1)
      }
      Try {
        Task[1](strParams)
      } Catch {
        iTaskErrors += 1
        DoLogging("!! Error attempting Internal Task: "Output . "!")
      }
    }
  } Catch {
    iTaskErrors += 1
    DoLogging("!! Error during parsing!")
  }
  Return iTaskErrors
}

ExitFunc(ExitReason, ExitCode) ; Checks and logs various unusual program closures.
{
  Gui +OwnDialogs
  If (ExitCode == 9999) ; this doesn't appear to work?
  {
    DoLogging("Restarting as Admin...")
    Return 0
  }
  If (ExitReason == "Menu") Or ((ExitReason == "Exit") And (ExitCode == 1))
  {
    SoundPlay *48
    MsgBox, 52, Exiting Configure-Image, Configuration is not complete!`nThis will end Configure-Image.`nAre you sure you want to exit?
      IfMsgBox, No
        Return 1  ; OnExit functions must return non-zero to prevent exit.
    DoLogging("-- User initiated and confirmed process exit via A_ExitReason: Menu (System Tray) or ExitCode: 1 (GUI Controls). Dying now.")
    Return 0
  }
  If ((A_ExitReason == "Exit") And (ExitCode == 0))
  {
    DoLogging("-- Received ExitCode 0, which should indicate that the process succeeded. Dying now.")
    Return 0
  }
  If ((A_ExitReason == "Exit") And (ExitCode > 1))
  {
    DoLogging("-- Received ExitCode 1 or higher, which indicates that iTotalErrors was non-zero. Dying now.")
    Return 0
  }
  If A_ExitReason In Logoff,Shutdown
  {
    DoLogging("-- System logoff or shutdown in process`, dying now.")
    Return 0  
  }
  If A_ExitReason == "Close"
  {
    DoLogging("!! The system issued a WM_CLOSE or WM_QUIT`, or some other unusual termination is taking place`, dying now.")
    Return 0
  }
  DoLogging("!! I am closing unusually`, with A_ExitReason: " A_ExitReason " and ExitCode: " ExitCode ", dying now.")
  ; Do not call ExitApp -- that would prevent other OnExit functions from being called.
}

ExitWait()
{
  Sleep 150 ; just in case the thread needs more time to finish the log
}

DoLogging(msg, Type=3) ; 1 logs to file, 2 logs to console, 3 does both, 10 is just a newline to file.
{
  global ScriptBasename, AppTitle
  If (Type == 1) {
    FileAppend, %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%%A_Tab%%msg%`n, %ScriptBasename%.log
    }
  If (Type == 2) {
    SendToConsole(msg)
    }
  If (Type == 3) {
    FileAppend, %A_YYYY%-%A_MM%-%A_DD% %A_Hour%:%A_Min%:%A_Sec%.%A_MSec%%A_Tab%%msg%`n, %ScriptBasename%.log
    SendToConsole(msg)
    }
  If (Type == 10) {
    FileAppend, `n, %ScriptBasename%.log
    }  
  Sleep 50 ; Hopefully gives the filesystem time to write the file before logging again
  Return
}

SendToConsole(msg) ; For logging to Console window.
{
  GuiControlGet, Console, 1:
  GuiControl, 1:, Console, %Console%%msg%`r`n
  ControlSend, Edit1, ^{End}, Console
}

WaitForPing(num) ;
{
  shell := ComObjCreate("WScript.Shell") ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
  DoLogging("ii Pinging to determine when the wireless adapter has connected to the network")
  DoLogging("** Ping -n "num . " -w 1000 8.8.8.8")
  exec := shell.Exec(ComSpec " /C Ping -n "num . " -w 1000 8.8.8.8") ; I am just assuming that 8.8.8.8 will always be online...
  Sleep 1000 ; Give it time to get started
  While !exec.StdOut.AtEndOfStream ;read the output line by line
  {
    DoLogging("   " exec.StdOut.ReadLine())
    If InStr(exec.StdOut.ReadLine(), "Reply") ; If we get a reply, we break early
    {
      DoLogging("   " exec.StdOut.ReadLine()) ; hopefully this is the line with the reply.
      DoLogging("ii Received reply, we should be good to proceed.")
      DoLogging("")
      Return
    }
  }
  MsgBox, This should not have happened, but it looks like you're not connected to the wireless network. Maybe take a look at that before proceeding?
  DoLogging("")
  Return 1
}