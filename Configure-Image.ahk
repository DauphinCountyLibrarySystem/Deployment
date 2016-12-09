strVersion := "2.5.0"
/*   
  Name: Configure-Image
  Authors: Christopher Roth, Lucas Bodnyk

  Changelog:
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

;   ================================================================================
;   AUTO-ELEVATE
;   ================================================================================
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

;   ================================================================================
;   DIRECTIVES, ETC.
;   ================================================================================
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#Persistent ; Keeps a script permanently running (that is, until the user closes it or ExitApp is encountered).
#SingleInstance FORCE ; automatically replaces an old version of the script - useful when auto-elevating.

;   ================================================================================
;   CONFIGURATION
;   ================================================================================
arrLPTOneServers := {"ESA": "192.168.100.221"
                   , "MRL": "10.11.20.5"
                   , "MOM": "10.13.20.14"
                   , "KL": "10.14.20.14"
                   , "AFL": "192.168.102.221"
                   , "JOH": "192.168.106.221"
                   , "EV": "192.168.105.221"
                   , "ND": "10.18.40.200"}

arrAutoLogonUser := {"ESA": "esalogon0"
                   , "KL": "kllogon4"
                   , "MOM": "momlogon3"
                   , "MRL": "mrllogon1"
                   , "AFL": "afllogon2"
                   , "JOH":"johlogon6"
                   , "EV": "evlogon5"
                   , "ND": "ndlogon8" }

IniRead, strActivationKey, KeysAndPasswords.ini, Keys, Windows10        ; Windows activation key (pulled from external file).
IniRead, strSpiceworksKey, KeysAndPasswords.ini, Keys, Spiceworks       ; Spiceworks authentication key (pulled from external file).
IniRead, strDomainPassword, KeysAndPasswords.ini, Passwords, DomainJoin ; Password for OU move (pulled from external file).

IniRead, strALPWPatron, KeysAndPasswords.ini, Passwords, Patron         ; Password for AutoLogon function (pulled from external file).
IniRead, strALPWStaff, KeysAndPasswords.ini, Passwords, Staff           ; Password for AutoLogon function (pulled from external file).
IniRead, strALPWCatalog, KeysAndPasswords.ini, Passwords, Catalog       ; Password for AutoLogon function (pulled from external file).

;   ================================================================================
;   INCLUDES, GLOBAL VARIABLES, ONEXIT, ETC...
;   ================================================================================
#Include, functions.ahk
ValidHostnameRegex := "i)^[a-z0-9]{1}[a-z0-9-\.]{0,14}$" ; obviously this isn't a very good pattern. I don't really know what other symbols are allowed other than dash and period, so...
DllCall("AllocConsole")
FileAppend test..., CONOUT$
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")
SplitPath, A_ScriptName, , , , ScriptBasename
StringReplace, AppTitle, ScriptBasename, _, %A_SPACE%, All
OnExit("ExitFunc") ; Register a function to be called on exit
OnExit("ExitWait")

;   ================================================================================
;   INITIALIZATION
;   ================================================================================
__init__:
Try {
  Gui 1: Font,, Lucida Console
  Gui 1: Add, Edit, Readonly x10 y10 w780 h580 vConsole ; I guess not everything has to be a function...
  Gui 1: -SysMenu
  Gui 1: Show, x20 y20 w800 h600, Console Window
  DoLogging("   Console window up.",2)
} Catch {
  MsgBox failed to create console window! I can't run without console output! Dying now.
  ExitApp
}
Try {
  DoLogging("")
  DoLogging("   ********************************************************************************")
  DoLogging("   Configure-Image "strVersion . " initializing for machine: " A_ComputerName)
  DoLogging("   ********************************************************************************")
  DoLogging("")
} Catch  {
  MsgBox Testing Deployment.log failed! You probably need to check file permissions. I won't run without my log! Dying now.
  ExitApp
}

;   ================================================================================
;   STARTUP
;   ================================================================================
__startup__:
{
  DoLogging("")
  DoLogging("__ __startup__")
  WinMinimizeAll
  WinRestore, Console Window

  Gosub __subMainGUI__ ; Here is where we construct the GUI and get the specific information we need
}

Return ; Execution should stop here until the user submits ButtonStart
MsgBox Cthuhlu! ; This should never run!
;   ================================================================================
;   MAIN
;   ================================================================================
__main__: ; if we're running in __main__, we should have all the input we need from the user.
{
  DoLogging("")
  DoLogging("__ __main__")

  Gosub, __subCreateOUPath__

  If (bIsWireless == 1)
  {
    Gosub, __subWirelessTasks__
  } 

  Gosub, __subDefaultTasks__

  Gosub, __subSpecificTasks__

  Gosub, __subAddAutoLogon__

  Gosub, __subCleanupJobs__
  
  Gosub, __subFinishAndExit__

  MsgBox Cthuhlu! ; This should never run!
}

MsgBox Cthuhlu! ; This should never run!
;   ================================================================================
;   FUNCTIONS AND LABELS
;   ================================================================================
#Include, labels.ahk