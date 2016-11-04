/*   
  Name: New Computer Deployment    
  Version: 2.2.2
  Authors: Christopher Roth, Lucas Bodnyk

  Changelog:
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
      bug hunting: follow (almost) all returns with 'MsgBox, Cthulhu!' so we can ensure that program flow is correct.
      examine log output to determine if it can be improved?
      banish Cthulhu!
      uncomment the business end of the Tasks functions, so that it actually does anything...
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
  Gui 1: Add, Edit, Readonly x10 y10 w620 h460 vConsole ; I guess not everything has to be a function...
  Gui 1: -SysMenu
  Gui 1: Show, x20 y20 w640 h480, Console Window
  DoLogging("   Console window up.",2)
} Catch {
  MsgBox failed to create console window! I can't run without console output! Dying now.
  ExitApp
}
Try {
  DoLogging("")
  DoLogging("   ********************************************************************************")
  DoLogging("   Configure-Image v2.0 initializing for machine: " A_ComputerName)
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
  ;WinMinimizeAll
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
  
  Gosub __subCreateOUPath__

  Gosub __subDefaultTasks__

  Gosub __subSpecificTasks__

  Gosub __subAddAutoLogon__

  Gosub __subCleanupJobs__
  
  Gosub __subFinishAndExit__

  MsgBox Cthuhlu! ; This should never run!
}

MsgBox Cthuhlu! ; This should never run!
;   ================================================================================
;   FUNCTIONS AND LABELS
;   ================================================================================
#Include, labels.ahk