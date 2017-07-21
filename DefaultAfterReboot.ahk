__subDefaultAfterReboot__:
{
	JoinDomain()
	InstallLogMeIn()

	Return
}

JoinDomain()
{
	Local strDomainPassword
	Local strFinalOuPath = CreateOUPath()

	IniRead, strDomainPassword										; Variable
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
		, Passwords 												; Section
		, DomainJoin 												; Key

	;Adds computer to Domain
	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. " Start-Sleep -s 3; "
		. " `$pass `= ConvertTo-SecureString -String "strDomainPassword 
		. " -AsPlainText -Force; "
		. " `$mycred `= New-Object -TypeName "
		. " System.Management.Automation.PSCredential "
		. " -ArgumentList unattend,`$pass; "
		. " Add-Computer  -DomainName dcls.org -Credential `$mycred "
		. " -OUPath '"strFinalOUPath . "' -Force -PassThru }""")

	return
}

InstallLogMeIn()
{
	ExecuteExternalCommand("msiexec.exe /i \Resources\Installers\_LogMeIn.msi "
		. " /quiet /norestart /log \logmein_install.log")

	return
}

CreateOUPath()
{
	Global strLocation
	Local strOUPath
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
		If (strComputerRole == "Self Checkout")
			strOUPath := "OU=Self Service,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
		If (strComputerRole == "LPT Kiosk")
			strOUPath := "OU=Kiosk,OU=Patron,OU=DCLS,DC=dcls,DC=org"    
		DoLogging("ii Distinguished Name: "strFinalOUPath)
	} Catch {
		DoLogging("!! Failure to create distinguished name!")
		vNumErrors += 1
	}

	Return strFinalOUPath
}