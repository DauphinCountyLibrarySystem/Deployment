#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
Msgbox running \\ESA-IT-APP01\ESA Reception Desk
Runwait c:\windows\system32\rundll32.exe printui.dll`,PrintUIEntry /in /n"\\ESA-IT-APP01\ESA Reception Desk"
msgbox done