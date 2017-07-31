#Include, functions.ahk

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


;===============================================================================
;									Reboot
;
; Reboot is a simple label. It gives the computer 1 (0x00000001) auto logon 
; to the local admin account. Then triggers a restart.
;===============================================================================
__Reboot__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting Reboot Operation")
	DoLogging("===============================================================")
	DoLogging(" ")


	;We have the user's input saved to DeploymentInfo.xml and will use that after
	; the reboot to continue running this with the same configuration
	; but first we need to create an autologon key with admin credentials
	; to ensure it logs back in after reboot
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

