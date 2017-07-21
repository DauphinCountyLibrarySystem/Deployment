#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


__DefaultTasks__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting AddAutoLogon for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")

	arrDefaultTaskList := []
	DoLogging("Renaming the computer.")
	RenameComputer();
	CopyPrinters();
	RegisterRestart(); 

	Return
}

RenameComputer() 
{	
	Global strComputerName
	Local strDomainPassword

	IniRead, strDomainPassword										; Variable
    	, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
    	, Passwords 												; Section
    	, DomainJoin 												; Key

	; This complex PowerShell Command that will rename the computer
	; I'm not sure if strDomainPassword is need but it ain't broke
	ExecuteExternalTask("powershell.exe -Command ""& { "
		. "`$pass `= ConvertTo-SecureString -String " . strDomainPassword 
			. " -AsPlainText -Force; "
		. " `$mycred `= New-Object -TypeName "
		. " System.Management.Automation.PSCredential "
		. " -ArgumentList unattend,`$pass; "
		. " Rename-Computer -NewName '" . strComputerName . "' "
		. " -DomainCredential `$mycred -Force -PassThru }""")

	return
}

CopyPrinters()
{
	Global strResourcesPath

	ExecuteExternalTask("robocopy "									; Command
		. strResourcesPath . "\Icons "								; Source
		. " C:\Icons "												; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Icons.log")			; Options

	return
}

RegisterRestart()
{
	ExecuteExternalTask("powershell.exe "
		. " -Command ""& { "
		. " Register-ScheduledTask "
		. " -Xml (get-content '\Configure-ImageTask.xml' | out-string) "
		. " -Taskname RestartConfigureImage}""")

	return
}
