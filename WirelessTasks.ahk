Include, SecondFunctions.ahk

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


__WirelessTasks__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting AddAutoLogon for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")
	DoLogging("import wireless profile, install Spiceworks agent, then wait for a connection...")


	AddWirelessProfile()
	InstallSpiceWorksAgent();
	
	DoLogging("ii sleep for 3 seconds before testing wireless")
	Sleep 3000 ; for some odd reason, WaitForPing(30) seems to fail after only 15 pings. Here's a minimum time to wait to possibly allow the adapter to "catch up".
	WaitForPing(30) ; up to 30 seconds, which is a long time I know, but it's not like we're staring at the console. It should only take like 5 seconds anyways.
	Return
}

;===============================================================================
;								AddWirelessProfile
; This Function adds the staff wifi profile for all users of the computer.
;===============================================================================
AddWirelessProfile()
{
	; Install wireless profile
	ExecuteExternalCommand("netsh wlan add profile filename`="strResourcesPath 
		. "\WirelessProfile-dclsstaff.xml user`=all") 

	return
}

;===============================================================================
;							Install Spice Works Agent
; This Function isntalls the SpiceWorks Agent.
;===============================================================================
InstallSpiceWorksAgent()
{
	Local strSpiceworksKey
	
	;Activation Key for Spiceworks (Pulled from an external file)
	IniRead, strSpiceworksKey										; Variable
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
		, Keys 														; Section
		, Spiceworks 												; Key
	ExecuteExternalCommand("msiexec.exe "
		. "/i "A_ScriptDir . "\Resources\Installers\_Spiceworks.msi " 
		. " SPICEWORKS_SERVER`=""spiceworks.dcls.org"" 
		. " SPICEWORKS_AUTH_KEY`=""" . strSpiceworksKey . """ 
		. " SPICEWORKS_PORT=443 "
		. " /quiet /norestart /log "A_ScriptDir . "\Spiceworks_install.log") 

	return
}