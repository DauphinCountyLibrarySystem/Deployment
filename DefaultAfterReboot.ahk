#Include, SecondFunctions.ahk

__DefaultAfterReboot__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting DefaultAfterReboot Operation")
	DoLogging("===============================================================")
	DoLogging(" ")


	JoinDomain()
	InstallLogMeIn()

	Return
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
	;ExecuteExternalCommand("netsh advfirewall firewall set rule group=""File and Printer Sharing"" new enable=Yes")

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