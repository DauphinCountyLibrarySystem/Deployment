#Include, functions.ahk
#Include SpecificTasks.ahk

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;===============================================================================
;									First Restart
;
; First Restart is a simple label. It gives the computer 1 (0x00000001) auto logon 
; to the local admin account. Then triggers a restart.
;===============================================================================
__FirstRestart__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting First Restart Operation")
	DoLogging("===============================================================")
	DoLogging(" ")
	If (strcomputerRole == "Patron")
		InstallOffice2016(True)
	RegisterFirstRestart()



	;We have the user's input saved to DeploymentInfo.xml and will use that after
	; the restart to continue running this with the same configuration
	; but first we need to create an autologon key with admin credentials
	; to ensure it logs back in after restart
	;Admin Credentials for Autologon Function (Pulled from an external file)
	;Local strAdminUsername
	;Local strAdminPassword

	IniRead, strAdminUsername
	    , %A_WorkingDir%\Resources\KeysAndPasswords.ini, Usernames, Admin
	IniRead, strAdminPassword
    		, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Admin
	arrAddAutoLogonList := []
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "AutoAdminLogon", "1"])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultDomainName",  ".\"])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultUserName",  strAdminUsername])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultPassword", strAdminPassword])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_DWORD"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "AutoLogonCount", 0x00000001])
	iTotalErrors += DoInternalTasks(arrAddAutoLogonList, bIsVerbose)

	Run %comspec% /c "shutdown.exe /r /t 0" ;Restarts after 3 seconds
	
	Return
}

__SecondRestart__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting Second Restart Operation")
	DoLogging("===============================================================")
	DoLogging(" ")
	RegisterSecondRestart()

	IniRead, strAdminUsername
	    , %A_WorkingDir%\Resources\KeysAndPasswords.ini, Usernames, Admin
	IniRead, strAdminPassword
    		, %A_WorkingDir%\Resources\KeysAndPasswords.ini, Passwords, Admin
	arrAddAutoLogonList := []
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "AutoAdminLogon", "1"])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultDomainName",  ".\"])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultUserName",  strAdminUsername])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "DefaultPassword", strAdminPassword])
	arrAddAutoLogonList.Insert(["RegWrite", "REG_DWORD"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		, "AutoLogonCount", 0x00000001])
	iTotalErrors += DoInternalTasks(arrAddAutoLogonList, bIsVerbose)

	Run %comspec% /c "shutdown.exe /r /t 0" ;Restarts after 3 seconds
}

;===============================================================================
; 							Register First Restart
;
; This functions will register a task using Windows Task Scheduler to start the
; Configure Image exe on user logon.
;
;===============================================================================
RegisterFirstRestart()
{
	DoLogging("Registering the task to restart Configure Image")
	strTaskFilePath := A_ScriptDir . "\Configure-ImageTask.xml"

	ExecuteExternalCommand("powershell.exe "
		. " -Command ""& { "
		. " Register-ScheduledTask "
		. " -Xml (get-content '" . strTaskFilePath . "' | out-string) "
		. " -Taskname RestartConfigureImage}""")

	return
}

;===============================================================================
; 						Register Second Restart
;
; This functions will register a task using Windows Task Scheduler to start the
; Configure Image exe on user logon.
;
;===============================================================================
RegisterSecondRestart()
{
	DoLogging("Registering the task to restart Configure Image for the second time")
	strTaskFilePath := A_ScriptDir . "\Configure-ImageSecondTask.xml"

	ExecuteExternalCommand("powershell.exe "
		. " -Command ""& { "
		. " Register-ScheduledTask "
		. " -Xml (get-content '" . strTaskFilePath . "' | out-string) "
		. " -Taskname RestartConfigureImage}""")

	return
}


