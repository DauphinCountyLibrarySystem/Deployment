Include, SecondFunctions

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


__AddAutoLogon__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting AddAutoLogon for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")
	DoLogging("ii create AutoLogon profile for certain roles...")
	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

	; because Office machines don't auto-logon
	If (strComputerRole == "Office") {
		OfficeAutoLogon()
	} else {
		EnableAutoLogon()
		If (strComputerRole == "Frontline") {
			FrontLineAutoLogon()
		} Else If (strComputerRole == "Patron") {  
			PatronAutoLogon()
		} Else If (strComputerRole == "Catalog") {
			CatalogAutoLogon()
		}
	}

	Return
}
MsgBox Cthuhlu! ; This should never run!

;===============================================================================
;							Office Auto Logon
; This function handles the AutoLogon feature for Office Computers. As of now,
; Office Computers to not support Auto Logon, so this just removes Auto Logon.
;
;===============================================================================
OfficeAutoLogon ()
{
	RemoveAutoLogon()
	return
}

;===============================================================================
;							FrontLine Auto Logon
; This function handles the AutoLogon feature for FrontLine Computers. It gets 
; the UserName from the arrAutoLogonUser, and then reads the password for that
; user from the KeysAndPasswords.ini.
;
;===============================================================================
FrontLineAutoLogon () 
{
	Global strLocation
	; The Default Usernames for each Location
	Local arrAutoLogonUser := {"ESA": "esalogon0"
							, "KL": "kllogon4"
							, "MOM": "momlogon3"
							, "MRL": "mrllogon1"
							, "AFL": "afllogon2"
							, "JOH":"johlogon6"
							, "EV": "evlogon5"
							, "ND": "ndlogon8" }
	Local strAutoLogonUser := arrAutoLogonUser[strLocation]
	;Staff Password for AutoLogon function (Pulled from an external file)
	Local strALPWStaff
	IniRead, strALPWStaff											; Variable
			, %A_WorkingDir%\Resources\KeysAndPasswords.ini 		; File
			, Passwords 											; Section
    		, Staff 												; Key
	
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, 
		, "DefaultUserName"
		, "dcls\" . strAutoLogonUser])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultPassword"
		, strALPWStaff])

	return
}

;===============================================================================
;							Patron Auto Logon
; This function handles the AutoLogon feature for Patron Computers. The Patron 
; UserName is just the Location + "-Patron". It then reads that password in from 
; the KeysAndPasswords.ini. 
;===============================================================================
PatronAutoLogon
{
	Global strLocation
	Local strALPWPatron
	;Patron Password for AutoLogon function (Pulled from an external file)
	IniRead, strALPWPatron											; Variable
    	, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
    	, Patron 													; Key

	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultUserName"
		, "dcls\" . strLocation . "-PATRON"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultPassword"
		, strALPWPatron])

	return
}

;===============================================================================
;							Catalog Auto Logon
; This function handles the AutoLogon feature for Catalog Computers. All Catalog
; computers use the username "esacatalog". The password for this account is read
; in from the KeysAndPasswords.ini
;===============================================================================
CatalogAutoLogon
{
	Local strALPWCatalog
	;Catalog Password for AutoLogon function (Pulled from an external file)
	IniRead, strALPWCatalog
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini
		, Passwords
		, Catalog

	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultUserName"
		, "dcls\esacatalog"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%"
		, "DefaultPassword"
		, strALPWCatalog])

	return
}

;===============================================================================
;							Enable Auto Logon
; This function Enables AutLogon.
;===============================================================================
EnableAutoLogon ()
{
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "AutoAdminLogon"
		, "1"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultDomainName"
		, "dcls.org"])
	ExecuteInternalCommand(["RegDelete"
		, %strWinLogon%
		, "AutoLogonCount"])

	return
}


;===============================================================================
;							Remove Auto Logon
; This Function Disables AutoLogon.
;===============================================================================
RemoveAutoLogon()
{
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "AutoAdminLogon"
		, "0"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultDomainName"
		, "dcls.org"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultUserName"
		, " "])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, %strWinLogon%
		, "DefaultPassword"
		, " "])
	ExecuteInternalCommand(["RegDelete"
		, %strWinLogon%
		, "AutoLogonCount"])

	return
}
