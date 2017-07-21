#Include, SecondFunctions ; This file will be renamed at some point 

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

	;This section handles different Windows tasks
	local strOfficePath := C:\Program Files (x86)\Microsoft Office\root\Office16
	local strPublicDesktop := C:\Users\Public\Desktop
	local strDefaultDesktop := C:\Users\Default\Desktop

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

	FileCreateShortcut, %officePath%\WINWORD.EXE				; Target
		, C:\Users\Default\Desktop\Word 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Word									; Description
		, ; Takes the Icon from the Word exe					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %officePath%\EXCEL.EXE					; Target
		, C:\Users\Default\Desktop\Excel 2016.lnk				; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Excel								; Description
		, ; Takes the Icon from the Excel exe					; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %officePath%\POWERPNT.EXE				; Target
		, C:\Users\Default\Desktop\PowerPoint 2016.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, 														; Args
		, Launch Microsoft PowerPoint							; Description
		, ; Takes the Icon from the PowerPoint exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %officePath%\MSPUB.EXE					; Target
		, C:\Users\Default\Desktop\Publisher 2016.lnk			; Link File
		, ; Standard Working directory							; WorkingDir
		, ; No Arguments										; Args 
		, Launch Microsoft Publisher							; Description
		, ; Takes the Icon from the Publisher exe				; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	FileCreateShortcut, %officePath%OUTLOOK.EXE					; Target
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

	createFrontLineEwareConfig(strLocation)
	local strPCResPath = "C:\ProgramData\EnvisionWare\PC Reservation"
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
		. " ""C:\Program Files (x86)\EnvisionWare"" envisionware.lic" ; Dest
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

	;This section handles different Windows tasks
	local strPublicDesktop := C:\Users\Public\Desktop
	local strDefaultDesktop := C:\Users\Default\Desktop

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

	; Copy PatronAdminPanel from Source to Dest
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
		local strPCResPath = "C:\ProgramData\EnvisionWare\PC Reservation"
		; Installs the envisionware Client
		ExecuteExternalCommand(strResourcesPath "\Installers"
			. "\_PCReservationClient.exe /S") 

		;This is the actual command that specifies the IP and port
		createPatronEwareConfig(strLocation)
		ExecuteExternalCommand("robocopy "							; Command
			. A_ScriptDir . "\Resources\EwareConfig"				; Source
			. " """ . strPCResPath . "\Client Module\config"""		; Dest
			. " /mov")												; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26
		
		; Patron printers.
		ExecuteExternalCommand(strResourcesPath . "\Installers\_LPTOneClient.exe"
			. " /S -jqe.host`=" . strEwareServer) 
	}
	arrSpecificTaskList.Insert("robocopy "							; Command
		. strResourcesPath 											; Source
		. """C:\Program Files (x86)\EnvisionWare"""					; Dest
		. " envisionware.lic " ; Will Only Copy this File 			; Options					
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

	local strOfficePath := C:\Program Files (x86)\Microsoft Office\Office16
	local strPublicDesktop := C:\Users\Public\Desktop
	local strDefaultDesktop := C:\Users\Default\Desktop


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
CatalogTask()
{
	; Moves the Encore Always Files from Source to Dest 
    ExecuteExternalCommand("robocopy "							; Command
    	. strResourcesPath ."\EncoreAlways\ "					; Source
    	. " C:\EncoreAlways "									; Dest
    	. "/s /UNILOG+:C:\Deployment\robocopy.log")  			; Options
}