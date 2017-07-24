#Include, SecondFunctions.ahk

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


__DefaultTasks__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting DefaultTasks for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")

	RenameComputer()
	CopyPrinters()
	RegisterRestart()

	Return
}

;===============================================================================
;									Rename Computer
;
; This function will rename the computer. I'm not sure that the PowerShell 
; command needs to be that complex anymore. It should be able to be simiplfied 
; into something like rename-Computer; but the current version works.
;===============================================================================
RenameComputer() 
{	
	DoLogging("Renaming the computer.")
	Global strComputerName

	IniRead, strDomainPassword										; Variable
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
		, Passwords 												; Section
		, DomainJoin 												; Key

	; This complex PowerShell Command that will rename the computer
	; I'm not sure if strDomainPassword is need but it ain't broke
	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. "`$pass `= ConvertTo-SecureString -String " . strDomainPassword 
			. " -AsPlainText -Force; "
		. " `$mycred `= New-Object -TypeName "
		. " System.Management.Automation.PSCredential "
		. " -ArgumentList unattend,`$pass; "
		. " Rename-Computer -NewName '" . strComputerName . "' "
		. " -DomainCredential `$mycred -Force -PassThru }""")

	return
}

;===============================================================================
;									Copy Printers
;
; To be honest, I'm not sure what this function does. I believe it copies the
; printer details onto the computer.
;===============================================================================
CopyPrinters()
{
	DoLogging("Copying Printers")
	Global strResourcesPath

	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\Icons "								; Source
		. " C:\Icons "												; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Icons.log")			; Options

	return
}

;===============================================================================
; 								Register Restart
;
; This functions will register a task using Windows Task Scheduler to start the
; Configure Image exe on user logon.
;
;===============================================================================
RegisterRestart()
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
