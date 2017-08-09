#Include, functions.ahk
#Include, SecondFunctions.ahk ; This file will be renamed at some point 

;======================================||=======================================
;								 Specific Tasks
;
; This File handles the specific tasks that the program will execute depending
; on the role of the computer deploying. The tasks executed are not dependent On
; on the location of the computer exceot for when the computer being deployed Is
; a VAN computer.
;
;======================================||=======================================
__SpecificTasks__:
{
	DoLogging(" ")
	DoLogging("===============================================================")
	DoLogging("		Starting SpecificTasks for Role:" . strComputerRole)
	DoLogging("===============================================================")
	DoLogging(" ")

	If (strComputerRole == "Office") {
		OfficeTasks()
	} Else If (strComputerRole == "Frontline") {
		FrontLineTasks()
	} Else If (strComputerRole == "Patron") {
		PatronTasks()
	} Else If (strComputerRole == "Catalog") {
		CatalogTasks()
	} Else If (strComputerRole == "Self-Check") {
		SelfCheckTasks()
	} Else If (strComputerRole == "Kiosk") {
		KioskTasks()
	}

	Return
}
MsgBox SpecificTasks overran ; This code should never run

;======================================||=======================================
;								  Office Tasks
;
; This Function is used to contain all of the tasks that should run when
; deploying an office computer. Any other tasks that need to be added for the 
; deployment can be added to this section. The tasks are divided into two 
; sections the first sections handles the different things that need be
; installed or run. The Second half of the tasks handles the different Windows
; tasks, such as creating file short cuts.
;
;======================================||=======================================
OfficeTasks() 
{
	;This section of OfficeTasks handles the installation of the programs
	Global strResourcesPath

	; Moves the Seirra Portable app to C: drive
	ExecuteExternalCommand("robocopy " 								; Command
	 	. " """ . strResourcesPath . "\Sierra Desktop App"""		; Target
		. " ""C:\Sierra Desktop App"" "								; Dest
		. " /s  /UNILOG+:C:\Deployment\robocopy_Sierra.log")		; Options

	; Calls Office 365 installer and runs it with customConfiguration
	ExecuteExternalCommand(strResourcesPath . "\Office365\setup.exe"
		. " /configure " 											
		. strResourcesPath . "\Office365\customconfiguration_staff.xml")

	; Copy links to staff printers.
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\Printers " 							; Target
		. " C:\Users\Default\Desktop\Printers" 						; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Printers.log")		; Options

	FileCreateDir, C:\IT\Icons
	ExecuteExternalCommand("robocopy "
		. strResourcesPath . "\shortcuts "
		. " C:\IT\Icons"
		. " /s /UNILOG+:C:\Deployment\robocopy_icons.log")

	;This section handles different Windows tasks
	;These variables will be local
	strOfficePath := "C:\Program Files (x86)\Microsoft Office\root\Office16"
	strPublicDesktop := "C:\Users\Public\Desktop"
	strDefaultDesktop := "C:\Users\Default\Desktop"

	; Notes about Public vs Default Desktop
	; Public Desktop:
	; 	- Creates Icons for ALL users of the computer
	;	- Icons need admin privileges to delete from them desktop
	; 	- Requires Admin privileges to delete from the Public Folder
	; Default Desktop :
	;	- Creates Icons for NEW users of the computer 
	;	- Can be deleted from desktop without admin privileges
	; 	- Requires Admin privileges to delete from the Default Folder

	FileCreateShortcut, \\contentserver\bucket 					; Target
		, C:\Users\Public\Desktop\Bucket.lnk 					; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Open the bucket file server							; Description
		, C:\Windows\system32\imageres.dll       				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 138													; Icon Number
		, 1														; Run State

	FileCreateShortcut, https://portal.adp.com/public/login		; Target
		, C:\Users\Public\Desktop\ADP.lnk 						; Link File
		, ; Standard Working directory							; WorkingDirr
		, ; No Arguments										; Args 
		, Launch the ADP Website								; Description
		, C:\IT\Icons\adp.ico 			; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, https://spiceworks.dcls.org/portal		; Target
		, C:\Users\Public\Desktop\Helpdesk Portal.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch the Help Desk Portal							; Description 
		, C:\IT\Icons\spiceworks.ico		; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe		; Target
		, C:\Users\Public\Desktop\Sierra Desktop App.lnk		; Link File
		, C:\Sierra Desktop App									; WorkingDir
		, ; No Arguments										; Args 
		, Launch the Sierra Desktop App							; Description
		, C:\IT\Icons\Sierra.ico			; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\WINWORD.EXE				; Target
		, C:\Users\Default\Desktop\Word 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Word									; Description
		, ; Takes the Icon from the Word exe					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\EXCEL.EXE					; Target
		, C:\Users\Default\Desktop\Excel 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Excel								; Description
		, ; Takes the Icon from the Excel exe					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\POWERPNT.EXE				; Target
		, C:\Users\Default\Desktop\PowerPoint 2016.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, 														; Args
		, Launch Microsoft PowerPoint							; Description
		, ; Takes the Icon from the PowerPoint exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\MSPUB.EXE					; Target
		, C:\Users\Default\Desktop\Publisher 2016.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Publisher							; Description
		, ; Takes the Icon from the Publisher exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\OUTLOOK.EXE					; Target
		, C:\Users\Default\Desktop\Outlook 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Outlook								; Description
		, ; Takes the Icon from the Outlook exe					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, c:\windows\explorer.exe					; Target
		, :\Users\Default\Desktop\File Explorer.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch File Explorer									; Description
		, ; Takes the Icon from the Explorer exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
}

;======================================||=======================================
;								 FrontLine Tasks
;
; This Function is used to contain all of the tasks that should run when
; deploying a FrontLine computer. Any other tasks that need to be added for the 
; deployment can be added to this section. The tasks are divided into two 
; sections the first sections handles the different things that need be
; installed or run. The Second half of the tasks handles the different Windows
; tasks, such as creating file short cuts.
;
;======================================||=======================================
FrontLineTasks() 
{
	;This section of FrontLineasks handles the installation of the programs
	Global strResourcesPath
	; Moves the Seirra Portable app from Source to Dest 
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\Sierra Desktop App"""				; Source
		. " ""C:\Sierra Desktop App"" "								; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Sierra.log")			; Options

	; Moves Offline circ files from Source to Dest 
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\Millennium "							; Source
		. " C:\Millennium "											; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Millennium.log") 	; Options

	; Copy links to staff printers from Source to Dest
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\Printers "							; Source
		. " C:\Users\Default\Desktop\Printers "						; Dest
		. " /s /UNILOG+:C:\Deployment\robocopy_Shortcuts.log")		; Options

	; Install Reservation Station
	ExecuteExternalCommand(strResourcesPath . "\Installers\_PCReservationStation.exe /S")

	;Check that this is not needed to be changed to be a staff controlled computer
	createFrontLineEwareConfig(strLocation)
	strPCResPath := "C:\ProgramData\EnvisionWare\PC Reservation"
	; Moves the Config File to the proper location
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\EwareConfig"							; Source
		. " """ . strPCResPath . "\Reservation Station\config""" 	; Dest
		. " /mov")													; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26

	; Install staff Print Release Terminal.
	ExecuteExternalCommand(A_ScriptDir . "\Resources\Installers"
		. "\_LPTOnePrintRelease.exe /S")

	;Envisionware License
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath											; Source
		. " ""C:\Program Files (x86)\EnvisionWare"""				; Dest
		. " envisionware.lic" ;Copies only this file 				; Option
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

	;This section handles different Windows tasks
	strPublicDesktop := "C:\Users\Public\Desktop"
	strDefaultDesktop := "C:\Users\Default\Desktop"

	; Notes about Public vs Default Desktop
	; Public Desktop:
	; 	- Creates Icons for ALL users of the computer
	;	- Icons need admin privileges to delete from them desktop
	; 	- Requires Admin privileges to delete from the Public Folder
	; Default Desktop :
	;	- Creates Icons for NEW users of the computer 
	;	- Can be deleted from desktop without admin privileges
	; 	- Requires Admin privileges to delete from the Default Folder

	; This Section will handle th
	FileCreateShortcut, \\contentserver\bucket 					; Target
		, C:\Users\Public\Desktop\Bucket.lnk 					; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Open the bucket file server							; Description
		, C:\Windows\system32\imageres.dll       				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 138													; Icon Number
		, 1														; Run State

	FileCreateShortcut, https://portal.adp.com/public/login		; Target
		, C:\Users\Public\Desktop\ADP.lnk 						; Link File
		, ; Standard Working directory							; WorkingDirr
		, ; No Arguments										; Args 
		, Launch the ADP Website								; Description
		, C:\Icons\adp.ico 										; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, https://spiceworks.dcls.org/portal		; Target
		, C:\Users\Public\Desktop\Helpdesk Portal.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch the Help Desk Portal							; Description 
		, C:\Icons\helpdeskportal.ico 							; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe		; Target
		, C:\Users\Public\Desktop\Sierra Desktop App.lnk		; Link File
		, C:\Sierra Desktop App									; WorkingDir
		, ; No Arguments										; Args 
		, Launch the Sierra Desktop App							; Description
		, C:\Icons\sierra.ico 									; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, C:\Millennium\Offline\offlinecirc.exe	; Target
		, C:\Users\Public\Desktop\Offline Circulation.lnk		; Link File
		, C:\Millenium\Offline									; WorkingDir
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, C:\Millennium\Offline\offlinecirc.ico					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, c:\windows\explorer.exe					; Target
		, :\Users\Default\Desktop\File Explorer.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch File Explorer									; Description
		, ; Takes the Icon from the Explorer exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
}

;======================================||=======================================
;								 Patron Tasks
;
; This Function is used to contain all of the tasks that should run when
; deploying a Patron computer. Any other tasks that need to be added for the 
; deployment can be added to this section. The tasks are divided into two 
; sections the first sections handles the different things that need be
; installed or run. The Second half of the tasks handles the different Windows
; tasks, such as creating file short cuts.
;
;======================================||=======================================
PatronTasks()
{
	;This section of PatronTasks handles the installation of the programs
	Global strResourcesPath
	; Copy PatronAdminPanel from Source to Dest
	IniRead, strEwareServer
		, %A_WorkingDir%\Resources\Servers.ini
		, Servers
		, %strLocation%
	ExecuteExternalCommand("robocopy "								; Command
		. A_ScriptDir . "\Resources\PatronAdminPanel "				; Source
	  	. " C:\PatronAdminPanel "									; Dest
	  	. " /s "													; Options
	  	. "/UNILOG+:C:\Deployment\robocopy_PatronAdminPanel.log")	; Options

	; Installs Office 2016
	ExecuteExternalCommand(""A_ScriptDir . "\Resources\Office2016\setup.exe ")

	If (strLocation == "VAN") {
		; Do Nothing
	} Else {
		; Installs the envisionware Client
		ExecuteExternalCommand(strResourcesPath "\Installers"
			. "\_PCReservationClient.exe /S") 

		;This is the actual command that specifies the IP and port
		createPatronEwareConfig(strLocation)
		ExecuteExternalCommand("robocopy "							; Command
			. """" . A_ScriptDir . "\Resources\EwareConfig """		; Source
			. " ""C:\ProgramData\EnvisionWare\PC Reservation"		; Dest
			. "\Client Module\config"""								; Dest cont
			. " /mov")												; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26
		
		; Patron printers.
		ExecuteExternalCommand(strResourcesPath . "\Installers\_LPTOneClient.exe"
			. " /S -host`:" . strEwareServer) 

	}
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath 											; Source
		. """C:\Program Files (x86)\EnvisionWare"""					; Dest
		. " envisionware.lic " ; Will Only Copy this File 			; Options
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

	strOfficePath := "C:\Program Files (x86)\Microsoft Office\Office16"
	strPublicDesktop := "C:\Users\Public\Desktop"
	strDefaultDesktop := "C:\Users\Default\Desktop"


	; Notes about Public vs Default Desktop
	; Public Desktop:
	; 	- Creates Icons for ALL users of the computer
	;	- Icons need admin privileges to delete from them desktop
	; 	- Requires Admin privileges to delete from the Public Folder
	; Default Desktop :
	;	- Creates Icons for NEW users of the computer 
	;	- Can be deleted from desktop without admin privileges
	; 	- Requires Admin privileges to delete from the Default Folder

	FileCreateShortcut, %strOfficePath%\WINWORD.EXE				; Target
		, C:\Users\Public\Desktop\Word 2016.lnk					; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args  
		, Launch Microsoft Word									; Description
		, ; Takes the icon from Word exe 						; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\EXCEL.EXE				; Target
	  , C:\Users\Public\Desktop\Excel 2016.lnk					; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Excel								; Description
		, ; Takes the icon from excel exe 						; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\POWERPNT.EXE			; Target
	, C:\Users\Public\Desktop\PowerPoint 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft PowerPoint							; Description
		, ; Takes the icon from PowerPoint exe 					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %strOfficePath%\MSPUB.EXE				; Target
		, C:\Users\Public\Desktop\Publisher 2016.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args  
		, Launch Microsoft Publisher							; Description
		, ; Takes the Icon from Publisher exe 					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
}

;======================================||=======================================
;								  Catalog Tasks
;
; This Function is used to contain all of the tasks that should run when
; deploying an Catalog computer. Any other tasks that need to be added for the 
; deployment can be added to this section. As of now, this function only does 
; one task.
;
;======================================||=======================================
CatalogTasks()
{
	Global strResourcesPath
	; Moves the Encore Always Files from Source to Dest 
    ExecuteExternalCommand("robocopy "							; Command
    	. strResourcesPath . "\EncoreAlways "					; Source
    	. " C:\EncoreAlways "									; Dest
    	. "/s /UNILOG+:C:\Deployment\robocopy.log")  			; Options
}

;===============================================================================
;								Self Check Tasks
;
;
;===============================================================================
SelfCheckTasks()
{
	DoLogging("Configuring Self Check Tasks")

	Global strResourcesPath
	strInstallersPath :=  strResourcesPath . "\Installers"
	
	Run, ClickInstallThread.exe
	ExecuteExternalCommand(strInstallersPath . "\_SelfCheckout.exe /S")
	ConfigureSelfCheck()

	;Move the License
	;Envisionware License
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath 											; Source
		. """C:\Program Files (x86)\EnvisionWare"""					; Dest
		. " envisionware.lic " ; Will Only Copy this File 			; Options
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\OneStop\ewSelfCheck.exe	; Target
		, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\OneStop.lnk ; Link Frenameile
		, C:\Program Files (x86)\EnvisionWare\OneStop\			; WorkingDirr
		, ; No Arguments										; Args 
		, Launch OneStop controller								; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	;Check the OneStop configure found on one note
	;this definetly will need config
	;Config will be in custom_text_en_us.js
	;ewSelfCheck.ewp
	;may need to change it to auto start but not sure. 
}

ConfigureSelfCheck()
{
	;Build Reciept.htm
	Global strLocation
	Global iTotalErrors
	If (strLocation = "ESA") {
		strLibraryName := "East Shore Area Library"
	} Else If (strLocation= "EV") {
		strLibraryName := " Elizabethville Area Library"
	} Else If (strLocation= "JOH") {
		strLibraryName := "Johnson Memorial Library"
	} Else If (strLocation= "ND") {
		strLibraryName := "Northern Dauphin Library"
	} Else If (strLocation= "AFL") {
		strLibraryName := "William H. & Marion C. Alexander Family Library"
	} Else If (strLocation= "KL") {
		strLibraryName := "Kline Library"
	} Else If (strLocation= "MOM") {
		strLibraryName := "Madeline L. Olewine Memorial Library"
	} Else If (strLocation= "MRL") {
		strLibraryName := "McCormick Riverfront Library"
	} Else {
		;This is servering as the default case in the event that
		; the location is not reconized. It shouldn't happen
		strLibraryName := "The Library"
	}
	
	intLineNumber := 1 ; ahk starts lines at 1
	boolIsDone := false
	while (!boolIsDone) {
		FileReadLine, strCurrentLine, %strResourcesPath%\One Stop Configs\tempreceipt_en_us.htm, intLineNumber
		If (ErrorLevel == 1) { ;If we reached end of file we are done
			boolIsDone = True
		} Else {
			strToken = Library Name Goes Here
			IfInString, strCurrentLine, %strToken%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken
					, strLibraryName
					, 0 ;OutputVarCount
					, -1 )
			} 
			FileAppend, %strCurrentLine% `n , receipt_en_us.htm
		}
		intLineNumber += 1
	}
	FileMove, receipt_en_us.htm, C:\Program Files (x86)\EnvisionWare\OneStop\html\receipts, 1
	If (A_LastError == 87) { ; The Windows could not find file error code
		;DoLogging("!!!The System failed to find the generated custom_text_en_us.js!!!")
		iTotalErrors += 1
	}

	intLineNumber := 1 ; ahk starts lines at 1
	boolIsDone := false
	while (!boolIsDone) {
		FileReadLine, strCurrentLine, %strResourcesPath%\One Stop Configs\tempcustom_text_en_us.js, intLineNumber
		If (ErrorLevel == 1) { ;If we reached end of file we are done
			boolIsDone = True
		} Else {
			strToken = Library Name Goes Here
			IfInString, strCurrentLine, %strToken%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken
					, strLibraryName
					, 0 ;OutputVarCount
					, -1 )
			} 
			FileAppend, %strCurrentLine% `n , custom_text_en_us.js
		}
		intLineNumber += 1
	}
	FileMove, custom_text_en_us.js, C:\Program Files (x86)\EnvisionWare\OneStop\html\scripts, 1
	If (A_LastError == 87) { ; The Windows could not find file error code
		;DoLogging("!!!The System failed to find the generated custom_text_en_us.js!!!")
		iTotalErrors += 1
	}

	intLineNumber := 1 ; ahk starts lines at 1
	boolIsDone := false
	while (!boolIsDone) {
		FileReadLine, strCurrentLine, %strResourcesPath%\One Stop Configs\tempewSelfCheck.ewp, intLineNumber
		If (ErrorLevel == 1) { ;If we reached end of file we are done
			boolIsDone = True
		} Else {
			Global strILSUsername
			Global strLocation
			strILSToken = ILS Username Goes Here
			strLocationToken = Location Goes Here
			IfInString, strCurrentLine, %strILSToken%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strILSToken
					, strILSUsername
					, 0 ;OutputVarCount
					, -1 )
			}
			IfInString, strCurrentLine, %strLocationToken%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strLocationToken
					, strLocation
					, 0 ;OutputVarCount
					, -1 )
			} 
			FileAppend, %strCurrentLine% `n , ewSelfCheck.ewp
		}
		intLineNumber += 1
	}
	FileMove, ewSelfCheck.ewp, C:\ProgramData\EnvisionWare\OneStop\config, 1
	If (A_LastError == 87) { ; The Windows could not find file error code
		;DoLogging("!!!The System failed to find the generated custom_text_en_us.js!!!")
		iTotalErrors += 1
	}
	
	Global strResourcesPath
	FileMove, %strResourcesPath%\One Stop Configs\itemDetails.js, C:\Program Files (x86)\EnvisionWare\OneStop\html\scripts, 1

	ExecuteExternalCommand(strResourcesPath . "\Installers\_PCReservationStation.exe /S")

	createFrontLineEwareConfig(strLocation)
	strPCResPath := "C:\ProgramData\EnvisionWare\PC Reservation"
	; Moves the Config File to the proper location
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\EwareConfig"							; Source
		. " """ . strPCResPath . "\Reservation Station\config""" 	; Dest
		. " /mov")													; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26
	ExecuteExternalCommand("del ""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\PC Reservation Reservation Station.lnk""")	

	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers"
		. "\_LPTOnePrintRelease.exe /S host`=" . strEwareServer)
	;LPTOne cannot connect to JQE? may need to robocopy in a configs
	ExecuteExternalCommand("del ""C:\Users\Public\Desktop\LPT One Print Release"
		. " Terminal.lnk""")

	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\lptPRT.exe 	; Target
		, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk ; Link Frenameile
		, ; Standard Working directory							; WorkingDirr
		, -host:%strEwareServer% -runmode:prompt				; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
	
	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk 	; Target
		, C:\Users\Public\Desktop\LPT One Print Realease Terminal.lnk ; Link Frenameile
		, ; Standard Working directory							; WorkingDirr
		, 														; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
}


;===============================================================================
;								Kiosk Tasks
;
;
;===============================================================================
KioskTasks()
{
	DoLogging("Configuring Kiosk Tasks")
	Global strLocation

	IniRead, strEwareServer
		, %A_WorkingDir%\Resources\Servers.ini
		, Servers
		, %strLocation%
	;Check OneNote / GitHub to see if there are more details on what this has 
	;installed

	; Install Reservation Station
	ExecuteExternalCommand(strResourcesPath . "\Installers\_PCReservationStation.exe /S")

	createFrontLineEwareConfig(strLocation)
	strPCResPath := "C:\ProgramData\EnvisionWare\PC Reservation"
	; Moves the Config File to the proper location
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\EwareConfig"							; Source
		. " """ . strPCResPath . "\Reservation Station\config""" 	; Dest
		. " /mov")													; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26
	ExecuteExternalCommand("del ""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\PC Reservation Reservation Station.lnk""")

	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers\_InstallAAM.exe /S")

	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers\mysql-connector-odbc-5.3.2-win32.msi /passive")
	; Install staff Print Release Terminal.
	; Because fuck all logic EnvisionWare does not allow you to silently
	; install a configure system. So instead the installation for Printer thing
	; Will actually have to happen in two steps. First step does the silent del
	; install second step will robocopy things over that we needed to configure
	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers"
		. "\_LPTOnePrintRelease.exe /S host`=" . strEwareServer)
	;LPTOne cannot connect to JQE? may need to robocopy in a configs
	ExecuteExternalCommand("del ""C:\Users\Public\Desktop\LPT One Print Release"
		. " Terminal.lnk""")

	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\lptPRT.exe 	; Target
		, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk ; Link Frenameile
		, ; Standard Working directory							; WorkingDirr
		, -host:%strEwareServer% -runmode:prompt				; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
	
	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk 	; Target
		, C:\Users\Public\Desktop\LPT One Print Realease Terminal.lnk ; Link Frenameile
		, ; Standard Working directory							; WorkingDirr
		, 														; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	CreateEWLaunchIndex()
	ExecuteExternalCommand("robocopy "								; Command
		. """" . strResourcesPath . "\Launch Command"""				; Source
		. " C:\" 													; Dest
		. " /e /is /move")											; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26

	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\ewLaunch\ewlaunch.exe	; Target
		, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ewLaunch.lnk ; Link Frenameile
		, ; Standard Working directory							; WorkingDirr
		, ; No Arguments										; Args 
		, Launch ewLaunch kiosk controller						; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
	



	;Installing kiosk is the prolly the most complex task we Have
	;Need to install all the things from kiosk folder
	;With some interesting configuring
	; then drop the Program Files, and ProgramData files
	;Lastly we drop the files fromt he Dauphion County file in the ewLaunch/Menus
}