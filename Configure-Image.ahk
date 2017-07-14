strVersion := "2.6.4"
/*   
  Name: Configure-Image
  Authors: Christopher Roth, Lucas Bodnyk
  
  External Libraries:
      DynamicCommand.ahk
        https://autohotkey.com/board/topic/37397-onelinecommands-execute-ahk-code-dynamically/
        One of the comments has the entire source code for the library
      KeyValStore.ahk
        https://github.com/cocobelgica/AutoHotkey-KeyValStore

  Changelog:
    2.6.4 - Improved DoExternalTasks to log WScript.Shell.StdErr. 
            It will also increment iTotalErrors if the StdErr stream is not empty.
            Hopefully this will help us catch what is happening when the domain join fails.
            Also moved the Office icons for patrons from Default to Public desktop.
    2.6.3 - Added RegDelete to clear out 'AutoLogonCount', which was set by the unattend.xml.
            Autologon information should no longer be cleared on reboot.
    2.6.2 - Powershell/Command Shell syntax is a minefield.
    2.6.1 - turned out %comspec% doesn't work via RunOnce. using cmd.exe now.
            The passwords file is now in the Resources folder.
            The finish dialog now gives you a chance to decline rebooting.
            The cleanup RunOnce should now leave behind log files.
            Add-Computer now includes "-Options JoinWithNewName".
            If that fails, I might have to have the user manually rename the computer and then reboot it.
            Add-Computer now only includes "-NewName". I might be going insane.
    2.6.0 - After tedious assessment of AHK "commands", I have pulled in a function from https://autohotkey.com/board/topic/37397-onelinecommands-execute-ahk-code-dynamically/
            This obviously makes it more difficult to distribute. I'll have to look into that. It's also not lost on me that I removed some functions back in 2.5.0 that were obviously doing something.
            Added Icons folder which gets copied to C:\ so that shortcuts keep their icons...
    2.5.1 - Removed -NewName from domain join; added -PassThru
    2.5.0 - Lots of stuff. In no particular order:
            Added RegEx to ensure NETBIOS compatible hostnames.
            I was changing the version string in 3 places every time I updated. Now it's only two. Go me. Also It's been named Configure-Image for a long time now, but this comment block wasn't updated?
            Refactored the wireless tasks. I'm hoping that it's not a problem for the Spiceworks agent to be installed before the network comes up. We might not be using the agent pretty soon anyway though.
            Recording shell StdOut to console. The console now scrolls to the bottom on every line. Resized console.
            Allocate a shell on init, then hide it. No more black screens popping up.
            Created WaitForPing() which should return faster if the network comes up sooner.
            Disabled the gui controls after the user confirms their choices.
            Removed RegWrite and FileDelete functions - defining functions with the same name as existing statements is pure insanity. We also weren't using them.
            Maybe other things I've forgotten already.
            It's becoming increasingly absurd to see this primitive error-"handling" all over my code. I may have to factor it out. It's not hurting anything, but it's certainly not helping...
    2.4.3 - Confirmed that Windows 10 is already activated. No need for activation script. This was actually last version, but w.e. 
    2.4.2 - Testing RunWaitOne() function from AHK reference website. Adjusted domain join syntax, pointed RunOnce removal key to correct target.
    2.4.1 - Seems like equals symbols may not be parsed correctly in strings, so I'm escaping them. Also removed the % from strLocation...
    2.4.0 - Everything should be ready as near as I can tell, I'm releasing this for testing.
    2.3.0 - Fixed DoExternalTasks()
            Our Runwait syntax was incorrect (honestly it's still a mess, but if it works...). I also snazzed up a few other things. More TODO as well!
    2.2.2 - more refactoring, but also some process improvements.
            ^ replace arrLPTOneServers with 'arrLPTOneServers'
            ^ vNumErrors is almost wiped out. Find out where else it is used (CreateOUPath frex.) and refactor
            ^ refactor CreateConfirmationWindow to a subroutine
            ^ refactor CreateOUPath to a subroutine
            ^ refactor cleanup jobs to a set of tasks that can be processed by DoTasks() (the sub currently doesn't handle or catch all of the tasks)
            ^ refactor ClosePCReservation to a function: it should check to make sure PC Reservation is actually closed, and maybe even try again? This would be a great candidate for a recursive function?
            ^ figure out which global variables no longer need to be global, and remove them
    2.2.1 - more refactoring. this hasn't even been tested. I need to learn to commit more, and test more.
    2.1.1 - major refactor - replaced many functions with labelled subroutines, and renamed many variables.
    ?.?.? - added .ini file.
    ?.?.? - added .ini reads to pull passwords from file.
    
  TODO:
      TEST IT OUT!
        I haven't actually run it in all configurations yet.
      examine log output to determine if it can be improved?
      banish Cthulhu!
      PC Reservation shortcut for proper IPs
        ^ I have code in place to test
*/

;===============================================================================
;   AUTO-ELEVATE
;===============================================================================
If Not A_IsAdmin
{
  If A_IsCompiled
  {
    Try
    {
      Run *RunAs "%A_ScriptFullPath%"
    } Catch {
      ExitApp 9999
    }
  }
  Else {
    Try {
      Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
    } Catch {
      ExitApp 9999
    }
  }
}

;===============================================================================
;   DIRECTIVES, ETC.
;===============================================================================
#NoEnv ; Recommended for performance and compatibility 
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent ; Keeps a script running (until closed).
#SingleInstance FORCE ; automatically replaces an old version of the script

;===============================================================================
;   CONFIGURATION
;===============================================================================

arrAutoLogonUser := {"ESA": "esalogon0"
                   , "KL": "kllogon4"
                   , "MOM": "momlogon3"
                   , "MRL": "mrllogon1"
                   , "AFL": "afllogon2"
                   , "JOH":"johlogon6"
                   , "EV": "evlogon5"
                   , "ND": "ndlogon8" }

;Activation Key for Windows (Pulled from an external file)
IniRead, strActivationKey, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Keys, Windows10
;Activation Key for Spiceworks (Pulled from an external file)
IniRead, strSpiceworksKey, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Keys, Spiceworks
;Password for OU (Pulled from external file)
IniRead, strDomainPassword, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, DomainJoin

;Patron Password for AutoLogon function (Pulled from an external file)
IniRead, strALPWPatron, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Patron

;Staff Password for AutoLogon function (Pulled from an external file)
IniRead, strALPWStaff, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Staff

;Catalog Password for AutoLogon function (Pulled from an external file)
IniRead, strALPWCatalog, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Catalog

;Admin Credentials for Autologon Function (Pulled from an external file)
IniRead, strAdminUsername, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Usernames, Admin
IniRead, strAdminPassword, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Admin

;===============================================================================
;   GLOBAL VARIABLES, ONEXIT, ETC...
;===============================================================================
; Obviously this isn't a very good pattern. I don't really know what other
;   symbols are allowed other than dash and period, so...
ValidHostnameRegex := "i)^[a-z0-9]{1}[a-z0-9-\.]{0,14}$" 
DllCall("AllocConsole")
FileAppend test..., CONOUT$
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")
SplitPath, A_ScriptName, , , , ScriptBasename
StringReplace, AppTitle, ScriptBasename, _, %A_SPACE%, All
OnExit("ExitFunc") ; Register a function to be called on exit
OnExit("ExitWait")

;===============================================================================
;   INITIALIZATION
;===============================================================================
__init__:
;Check if the version has been marked as rebooted.

Try {
  Gui 1: Font,, Lucida Console
  Gui 1: Add, Edit, Readonly x10 y10 w940 h620 vConsole ; I guess not everything has to be a function...
  Gui 1: -SysMenu
  Gui 1: Show, x20 y20 w960 h640, Console Window
  DoLogging("   Console window up.",2)
} Catch {
  MsgBox failed to create console window! I can't run without console output! Dying now.
  ExitApp
}

bIsRebooted := false
DoLogging(%0% . " arguments found.")
Loop, %0% {
  DoLogging("A_Index is: " . %A_Index%)
  If (%A_Index% == "rebooted") {
    bIsRebooted = true
    break
  }
}
Try {
  If (!bIsRebooted) {
    DoLogging("")
    DoLogging("   ********************************************************************************")
    DoLogging("   Configure-Image "strVersion . " initializing for machine: " A_ComputerName)
    DoLogging("   ********************************************************************************")
    DoLogging("")
  } else {
    ;bIsRebooted == True
    DoLogging("")
    DoLogging("   ********************************************************************************")
    DoLogging("   Configure-Image "strVersion . " restarting on machine: " A_ComputerName)
    DoLogging("   ********************************************************************************")
    DoLogging("")
  }
} Catch  {
  MsgBox Testing Deployment.log failed! You probably need to check file permissions. I won't run without my log! Dying now.
  ExitApp
}

;===============================================================================
;   STARTUP
;===============================================================================
__startup__:
{
  DoLogging("")
  DoLogging("__ __startup__")
  WinMinimizeAll
  WinRestore, Console Window

  If (!bIsRebooted) {
    ;Constructs the GUI and gets the specific information that we need
    ;We only want to do this if this is not the rebooted version of the app
    Gosub __subMainGUI__
  } Else {
    ;bIsRebooted == true
    Gosub, __afterReboot__
  }

}

Return ; Execution should stop here until the user submits ButtonStart
MsgBox Cthuhlu! ; This should never run!
;===============================================================================
;   MAIN
;===============================================================================
; if we're in __main__, we should have all the input we need from the user.
__main__:
{
  If (strComputerRole == "Self-Check") {
    MsgBox, "The Self-Check role is not currently Supported."
    ExitApp, 1
  }
  DoLogging("")
  DoLogging("__ __main__")
  
    If (bIsWireless == 1)
    {
      Gosub, __subWirelessTasks__
    } 

  Gosub, __subDefaultTasks__
  
  Gosub, __subReboot__

  Exit 0 ;After it triggers the reboot it should exit the script.
  MsgBox Cthuhlu! ; This should never run!
}

__afterReboot__:
{
  GoSub, __subLoadUserInput__

  Gosub, __subCreateOUPath__

  GoSub, __subDefaultAfterReboot__

  GoSub, __subSpecificTasks__

  GoSub, __subAddAutoLogon__

  GoSub, __subCleanupJobs__

  GoSub, __subFinishAndExit__

  DoLogging(" Advancing to task reserved for after the reboot.")

}


MsgBox Cthuhlu! ; This should never run!

;===============================================================================
;   FUNCTIONS AND LABELS
;===============================================================================
#Include, functions.ahk
#Include, labels.ahk
#Include, DynamicCommand.ahk
#Include, KeyValStore.ahk

