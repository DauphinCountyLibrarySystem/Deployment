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

	Return
}

__DefaultAfterFirstRestart__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting DefaultAfterFirstRestart Operation")
	DoLogging("===============================================================")
	DoLogging(" ")

	;After the
	arrExternalCleanupJobs := []
	arrExternalCleanupJobs.insert("powershell.exe -Command ""& { "
		. " Unregister-ScheduledTask "
		. " -TaskName RestartConfigureImage "
		. " -Confirm:$false }""")
	iTotalErrors += DoExternalTasks(arrExternalCleanupJobs, bIsVerbose)

	JoinDomain()
	;InstallLogMeIn()

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

JoinDomain()
{
	DoLogging("Joining the Domain")

	IniRead, strDomainPassword										; Variable
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
		, Passwords 												; Section
		, DomainJoin 												; Key

	;Adds computer to Domain
	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. " Start-Sleep -s 3; "
		. " `$pass `= ConvertTo-SecureString -String " . strDomainPassword 
		. " -AsPlainText -Force; "
		. " `$mycred `= New-Object -TypeName "
		. " System.Management.Automation.PSCredential "
		. " -ArgumentList unattend,`$pass; "
		. " Add-Computer  -DomainName dcls.org -Credential `$mycred "
		. " -OUPath '" . CreateOUPath() . "' -Force -PassThru }""")
	;Enables file sharing
	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. " get-NetFirewallRule "
		. " | where {$_.DisplayName -like '*file*'} "
		. " | Set-NetFirewallRule -enabled True "
		. " }""" )

	DoLogging("")
	return
}

InstallLogMeIn()
{
	Global strResourcesPath

	ExecuteExternalCommand("msiexec.exe /i " . strResourcesPath . "\Installers\_LogMeIn.msi "
    	. " /quiet /norestart /log "A_ScriptDir . "\logmein_install.log")

	return
}

;===============================================================================
;
;
;===============================================================================
CreateOUPath()
{
	Global iTotalErrors
	Global strLocation
	;Local strOUPath

	DoLogging("ii Creating distinguished name for domain join...")
	Try {
		If (strComputerRole == "Office")
			strOUPath := "OU=Offices,OU=Systems,OU="
						. strLocation
						. ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
		If (strComputerRole == "Frontline")
			strOUPath := "OU=Frontline,OU=Systems,OU=" 
						. strLocation 
						. ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
		If (strComputerRole == "Frontline" and bIsWireless == 1) ;Staff Laptop
			strOUPath := "OU=Laptops,OU=Systems,OU=" 
						. strLocation
						. ",OU=Staff,OU=DCLS,DC=dcls,DC=org"  
		If (strComputerRole == "Patron")
			strOUPath := "OU=" 
						. strLocation 
						. ",OU=Patron,OU=DCLS,DC=dcls,DC=org"  
		If (strComputerRole == "Patron" and bIsWireless == 1) ;Patron Laptop
			strOUPath := "OU=Laptops,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
		If (strComputerRole == "Catalog")
			strOUPath := "OU=Catalog,OU=Patron,OU=DCLS,DC=dcls,DC=org"
		If (strComputerRole == "Self-Check")
			strOUPath := "OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
		If (strComputerRole == "Kiosk")
			strOUPath := "OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
		DoLogging("ii Distinguished Name: " . strOUPath)
	} Catch {
		DoLogging("!! Failure to create distinguished name!")
		iTotalErrors +=1
	}

	Return strOUPath
}


