#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

RunAsAdmin() {
    static init := A_IsAdmin ? 1 : RunAsAdmin()
    if init
        return
    
    s := (A_IsUnicode ? "" : "A") ; dllcall function suffix
    RegExMatch(DllCall("GetCommandLine" s, "Str"), "^(?|""(?<Exe>[^""]+)""|(?<Exe>[^ ]+))(?: (?<Args>.*))?$", CommandLine)
    DllCall("shell32\ShellExecute" s, "Ptr", 0, "Str", "RunAs", "Str", CommandLineExe, "Str", CommandLineArgs, "Str", A_WorkingDir, "Int", 1)
    ExitApp
}

DisplayAdminPanel()
return

DisplayAdminPanel()	{
	Gui, Add, Text, x12 y12, %A_ComputerName%
	Gui, Add, Text, x128 y12, %A_IPAddress1%
	Gui, Add, Text, x12 y36, Select an OS:
;	Gui, Add, Button, x12 y48 w100 h20 , ; Intentional gap
	Gui, Add, Button, x12 y78 w100 h20 , Windows 8.1 ; These buttons will work beautifully with up to 12 letter labels.
;	Gui, Add, Button, x12 y108 w100 h20 ,
	Gui, Add, Button, x12 y138 w100 h20 ,
	Gui, Add, Button, x12 y168 w100 h20 ,
	Gui, Add, Button, x12 y198 w100 h20 ,
	Gui, Add, Button, x12 y228 w100 h20 , 
;	Gui, Add, Button, x12 y258 w100 h20 , 
	Gui, Add, Button, x12 y288 w100 h20 ,
;	Gui, Add, Button, x128 y48 w100 h20 , ; Intentional gap
	Gui, Add, Button, x128 y78 w100 h20 , Windows 10
;	Gui, Add, Button, x128 y108 w100 h20 , ; Intentional gap
	Gui, Add, Button, x128 y138 w100 h20 ,
	Gui, Add, Button, x128 y168 w100 h20 ,
	Gui, Add, Button, x128 y198 w100 h20 , 
	Gui, Add, Button, x128 y228 w100 h20 , 
;	Gui, Add, Button, x128 y258 w100 h20 , 
	Gui, Add, Button, x128 y288 w100 h20 Default, Cancel
	Gui, Show, h320 w240 Center, Admin Panel
	Return
}

ButtonWindows8.1:
RunWait *RunAs c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ipk DCV8N-WY92Y-24HM6-37PXP-D68K3, c:\windows\system32\
RunWait *RunAs c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ato, c:\windows\system32\
ExitApp

ButtonWindows10:
RunWait *RunAs c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ipk ***REMOVED***, c:\windows\system32\
RunWait *RunAs c:\windows\system32\cscript.exe //b c:\windows\system32\slmgr.vbs /ato, c:\windows\system32\
ExitApp

ButtonCancel:
ExitApp