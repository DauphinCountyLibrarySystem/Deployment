#Include, SecondFunctions.ahk
#Include, functions.ahk

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


__AutoLogon__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting AddAutoLogon for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")

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
OfficeAutoLogon()
{
	DoLogging("Configuring for Office Auto Logon")
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
FrontLineAutoLogon() 
{
	DoLogging("Configuring for Front Line Auto Logon")
	Global strLocation
	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	; The Default Usernames for each Location
	arrAutoLogonUser := {"ESA": "esalogon0"
							, "KL": "kllogon4"
							, "MOM": "momlogon3"
							, "MRL": "mrllogon1"
							, "AFL": "afllogon2"
							, "JOH":"johlogon6"
							, "EV": "evlogon5"
							, "ND": "ndlogon8" }
	strAutoLogonUser := arrAutoLogonUser[strLocation]
	;Staff Password for AutoLogon function (Pulled from an external file)

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
		, strWinLogon
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
PatronAutoLogon()
{
	DoLogging("Configuring for Patron Auto Logon")

	Global strLocation
	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

	;Patron Password for AutoLogon function (Pulled from an external file)
	IniRead, strALPWPatron											; Variable
    	, %A_WorkingDir%\Resources\KeysAndPasswords.ini 			; File
    	, Patron 													; Key

	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultUserName"
		, "dcls\" . strLocation . "-PATRON"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
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
CatalogAutoLogon()
{
	DoLogging("Configuring for Catalog Auto Logon")

	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	;Catalog Password for AutoLogon function (Pulled from an external file)
	IniRead, strALPWCatalog
		, %A_WorkingDir%\Resources\KeysAndPasswords.ini
		, Passwords
		, Catalog

	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultUserName"
		, "dcls\esacatalog"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultPassword"
		, strALPWCatalog])

	return
}

;===============================================================================
;							Enable Auto Logon
; This function Enables AutLogon.
;===============================================================================
EnableAutoLogon()
{
	DoLogging("Enabling Auto Logon")

	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "AutoAdminLogon"
		, "1"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultDomainName"
		, "dcls.org"])
	ExecuteInternalCommand(["RegDelete"
		, strWinLogon
		, "AutoLogonCount"])

	return
}


;===============================================================================
;							Remove Auto Logon
; This Function Disables AutoLogon.
;===============================================================================
RemoveAutoLogon()
{
	DoLogging("Disabling autologn")

	strWinLogon = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "AutoAdminLogon"
		, "0"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultDomainName"
		, "dcls.org"])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultUserName"
		, " "])
	ExecuteInternalCommand(["RegWrite"
		, "REG_SZ"
		, strWinLogon
		, "DefaultPassword"
		, " "])
	ExecuteInternalCommand(["RegDelete"
		, strWinLogon
		, "AutoLogonCount"])

	return
}
