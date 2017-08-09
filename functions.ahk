
; A recursive function that will attempt to close the Envisionware window after
; installation. It will attempt to close the window until it does.
; I'm quite proud of using recursion.
ClosePCReservation(sec)
{
  DoLogging("-- ClosePCReservation() running: waiting for " sec " seconds...")
  Sleep (sec*1000)
  If ProcessExist("PC Reservation Client Module.exe")
  {
    DoLogging("-- Attempting to close PC Reservation Client...")
    CoordMode, Mouse, Screen
    MouseMove, (20), (A_ScreenHeight - 20)
    Sleep, 250
    ; this should work better than: Send, {Ctrl Down}{Click}{Ctrl up}
    Send, ^{Click} ; This == Crtl + Click
    Sleep, 250
    Send envisionware{enter}{enter}
    ; I'm trying to be generous here. It shouldn't take a second to close.
    Sleep, 1000 
  }
  If ProcessExist("PC Reservation Client Module.exe")
  {
    sec -= 1 ; decrement each time we recurse
    If sec<1 ; our base case, as it were...
    {
      DoLogging("!! PC Reservation Client is still running !!")
      DoLogging("But ClosePCReservation() ran out of time!")
      Return 1
    }
    DoLogging(">< PC Reservation Client is still running ><")
    DoLogging("Attempting ClosePCReservation again...")
    Return ClosePCReservation(sec)
  }
  DoLogging("<> PC Reservation Client seems to be closed, returning...")
  Return 0
}

ProcessExist(Name)
{
  Process, Exist, %Name%
  return Errorlevel
}

; Loops through the provided array of commands (arrTasks) and attempts to
; execute each of the commands. It will log each attempt.
DoExternalTasks(arrTasks, Verbosity) 
{
  Global iTotalErrors
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
      ;
      If !exec.StdErr.AtEndOfStream ; It's important to note that this does NOT get StdErr in parallel with StdOut - if you stack four commands in a row, and the first two fail, you will get their error output AFTER the 3rd and 4th commands finish StdOut.
      {
        iTotalErrors += 1 ; This will only count once even if you stack commands! At least my error handling counts for something again...
        DoLogging("!! STDERR:")
        While !exec.StdErr.AtEndOfStream
        {
          DoLogging("   " exec.StdErr.ReadLine())
        }
      }
      DoLogging("")
    } Catch {
      iTotalErrors += 1
      DoLogging("!! Error attempting External Task: "Task . "!")
    }
  }
  Return
}

; Loops through the provided array of commands (arrTasks) and attempts to
; execute each of the commands. It will log each attempt.
DoInternalTasks(arrTasks, Verbosity) 
{
  Global iTotalErrors
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
        P := StrSplit(strParams, ",")
        #(Task[1], P[1], P[2], P[3], P[4], P[5], P[6], P[7], P[8], P[9], P[10]
          , P[11], P[12], P[13], P[14], P[15], P[16], P[17], P[18], P[19])
      } Catch {
        iTotalErrors += 1
        DoLogging("!! Error attempting Internal Task: "Output . "A_LastError: " . A_LastError)
      }
    }
  } Catch {
    iTotalErrors += 1
    DoLogging("!! Error during parsing!")
  }

  Return
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
  If A_ExitReason In Logoff, Shutdown
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

WaitForPing(num) 
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

CreatePatronEwareConfig(location)
{
    ;Path to where Servers.ini is found
    serversPath := A_WorkingDir . "\Resources\Servers.ini"
    IniRead, strEwareServer
        , %serversPath%, Servers, %location%
    IniRead, strAutoDiscoveryPort
        , %serversPath%, AutoDiscoveryPort, %location%
    IniRead, strManagementServicePort
        , %serversPath%, ManagementServicePort, %location%

  fileName := "Resources\EwareConfig\pcrClient.ewp"
  fileContent := ""
  . "<!DOCTYPE Settings> `n"
  . "<Settings> `n"
  . "    <version>1</version> `n"
  . "    <type>PC Reservation Client</type> `n"
  . "    <entry name=""Network: Management Service Auto-Discovery Port"">" strAutoDiscoveryPort . "</entry> `n"
  . "    <entry name=""Network: Management Service IP Address/Host Name"">" strEwareServer . "</entry> `n"
  . "    <entry name=""Network: Management Service Port"">"  strManagementServicePort . "</entry> `n"
  . "    <collection name=""Process Exceptions""> `n"
  . "        <entry name=""LPT:One Print Cost Management"">Skip When Closing</entry> `n"
  . "    </collection>`n"
  . "</Settings>"

  FileAppend, %fileContent%, %fileName%
}

CreateFrontLineEwareConfig(location)
{
    ;Path to where Servers.ini is found
    serversPath := A_WorkingDir . "\Resources\Servers.ini"
    IniRead, strEwareServer
        , %serversPath%, Servers, %location%
    IniRead, strAutoDiscoveryPort
        , %serversPath%, AutoDiscoveryPort, %location%
    IniRead, strManagementServicePort
        , %serversPath%, ManagementServicePort, %location%

  fileName := "Resources\EwareConfig\rsConfig.ewp"
  fileContent := ""
  . "<?xml version=""1.0"" encoding=""utf-8"" ?> `n"
  . "<Settings> `n"
  . "<version>1.1</version> `n"
  . "<type>RS Config</type> `n"
  . "<entry name='Allow No Area Selection'>0</entry> `n"
  . "<entry name='Allow Receipt Printing'>0</entry> `n"
  . "<entry name='Allowed Areas'></entry> `n"
  . "<entry name='Always Print Receipt'>0</entry> `n"
  . "<entry name='Background Color'>0</entry> `n"
  . "<entry name='Barcode Printer'></entry> `n"
  . "<entry name='Barcode Printer Left Margin'>0</entry> `n"
  . "<entry name='Barcode Printer Top Margin'>0</entry> `n"
  . "<entry name='Blank Lines'>0</entry> `n"
  . "<entry name='Dedicated'>0</entry> `n"
  . "<entry name='Default Area'></entry> `n"
  . "<entry name='Fields'>0</entry> `n"
  . "<entry name='Footer Text'></entry> `n"
  . "<entry name='Foreground Color'>0</entry> `n"
  . "<entry name='LPT:One Print Cost Management'>Skip When Closing</entry> `n"
  . "<entry name='Management Console: Host Name'></entry> `n"
  . "<entry name='Management Console: IP Address'>"strEwareServer . "</entry> `n"
  . "<entry name='Management Console: NetBIOS Name'></entry> `n"
  . "<entry name='Management Console: TCP Port'>1969</entry> `n"
  . "<entry name='Management Console: TCP Socket Keep-Alive Interval'>15000</entry> `n"
  . "<entry name='Management Console: UDP Port'>0</entry> `n"
  . "<entry name='Network: Management Service Auto-Discovery Port'>61969</entry> `n"
  . "<entry name='Network: Management Service IP Address/Host Name'>"strEwareServer . "</entry> `n"
  . "<entry name='Network: Management Service Port'>9432</entry> `n"
  . "<entry name='Printer Name'></entry> `n"
  . "<entry name='Receipt Fields'>0</entry> `n"
  . "<entry name='Staff Managed'>1</entry> `n"
  . "<entry name='Window Height'>0</entry> `n"
  . "<entry name='Window Position X'>0</entry>  `n"
  . "<entry name='Window Position Y'>0</entry> `n"
  . "<entry name='Window Width'>0</entry> `n"
  . "</Settings> `n"

  FileAppend, %fileContent%, %fileName%
}

CreateEWLaunchIndex()
{
  DoLogging("Creating EWLaunch Index.html")
  Global strLocation
  Global strResourcesPath

  serversPath := A_WorkingDir . "\Resources\Servers.ini"
  IniRead, strEwareServer, %serversPath%, Servers, %strLocation%

  

  strFileName := "" . strResourcesPath . "\Launch Command\Program Files (x86)\Envisionware\ewLaunch\menus\index.html" 
  strFileContent := ""
    . "<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.01 Transitional//EN""> `n"
    . "<html><head><title>Self Service Station</title> `n"
    . " `n"
    . "<link rel=""stylesheet"" type=""text/css"" href=""style.css""> `n"
    . "</head> `n"
    . "<body> `n"
    . "<div id=""header""></div> `n"
    . "<div class=""space1""></div> `n"
    . "<div id=""page""> `n"
    . "<div class=""pageTitle""><img src=""DCLS_LOGO.png""></div> `n"
    . "<div class=""space2""></div> `n"
    . "  `n"
    . "<div class=""boxey""> `n"
    . "<!--Path and file name of PC Res Self-Service Reservation Station (Icon launch)--> `n"
    . "<p><a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5CPC%20Reservation%5CReservation%20Station%5CPCRes_RS.exe%20-makeresv%20-parent=%ParentWindow%""><img src=""computer.gif""></a> `n"
    . "<br /> `n"
    . "<!--Path and file name of PC Res Self-Service Reservation Station (Text launch)--> `n"
    . "<a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5CPC%20Reservation%5CReservation%20Station%5CPCRes_RS.exe%20-makeresv%20-parent=%ParentWindow%""><strong>Reserve a PC</strong></a></p> `n"
    . "</div> `n"
    . "<div class=""boxey""> `n"
    . "<!--Path and file name of LPT:One PRT (Icon launch)--> `n"
    . "<p><a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5Clptone%5Clptprt%5Clptprt.exe%20-host=" . strEwareServer . "%20-runmode=prompt%20-parent=%ParentWindow%""><img src=""printer.gif""></a> `n"
    . "<br /> `n"
    . "<!--Path and file name of LPT:One PRT (Text launch)--> `n"
    . "<a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5Clptone%5Clptprt%5Clptprt.exe%20-host=" . strEwareServer . "%20-runmode=prompt%20-parent=%ParentWindow%""><strong>Release a Print Job</strong></a></p>`n"
    . "</div> `n"
    . "<div class=""boxey""> `n"
    . "<!--Path and file name of AAM User Account Manager in self-service mode (Icon launch)--> `n"
    . "<p><a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5CAAM%5CAA_Revalue.exe%20-selfserv%20-parent=%ParentWindow%""><img src=""money.gif""></a> `n"
    . "<br /> `n"
    . "<!--Path and file name of AAM User Account Manager in self-service mode (Text launch)--> `n"
    . "<a href=""launch://C:%5CProgram%20Files%20(x86)%5CEnvisionWare%5CAAM%5CAA_Revalue.exe%20-selfserv%20-parent=%ParentWindow%""><strong>Add to Deposit Account</strong></a></p> `n"
    . "</div> `n"
    . "</div> `n"
    . "<div class=""space2""></div> `n"
    . "<div id=""footer""></div> `n"
    . "</body></html> `n"

    FileDelete, %strFileName%
    DoLogging("Writing Index.html")
    FileAppend, %strFileContent%, %strFileName%
}