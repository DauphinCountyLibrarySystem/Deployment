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

	bSierraDesktopIcon = True
	InstallSierra(bSierraDesktopIcon)

	bOfficeDesktopIcons = True
	InstallOffice365(bOfficeDesktopIcons)

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

	bDesktopIcon = False
	bOnStartup = False
	InstallPCReservationReservationStation(bDesktopIcon, bOnStartup)

	bSierraDesktopIcon = True
	InstallSierra(bSierraDesktopIcon)

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

	; Install staff Print Release Terminal.
	bLPTDesktopIcon = True
	bLPTOnStartup = False
	InstallLPTOnePrintReleaseTerminal(bLPTDesktopIcon, bLPTOnStartup)

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

	bOfficeDesktopIcons = True
	InstallOffice2016(bOfficeDesktopIcons)

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
	
	bOneStopDesktopIcon = True
	bOneStopOnStartup = True
	InstallOneStop(bOneStopDesktopIcon, bOneStopOnStartup)
	ConfigureSelfCheck()


	bDesktopIcon = False
	bOnStartup = False
	InstallPCReservationReservationStation(bDesktopIcon, bOnStartup)

	bLPTOneDesktopIcon = True
	bLPTOneOnStartup = false
	InstallLPTOnePrintReleaseTerminal(bLPTDesktopIcon, bLPTOnStartup)


	;Move the License
	;Envisionware License
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath 											; Source
		. """C:\Program Files (x86)\EnvisionWare"""					; Dest
		. " envisionware.lic " ; Will Only Copy this File 			; Options
		. " /UNILOG+:C:\Deployment\robocopy_EWareLicense.log")		; Options

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

	;In order for Self-Check to create the firewall rules it needs to have been opened
	Run, "C:Program Files (x86)\EnvisionWare\OneStop\ewSelfCheck.exe"
	SetTitleMatchMode, 2
	WinWait, OneStop
	WinClose

	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. " Get-NetFirewallRule | where {$_.DisplayName -like '*self check*'} "
		. " | Set-NetFirewallRule -Action Allow "
		. "} ")

	return
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
	Global strResourcesPath

	; Install Reservation Station
	bDesktopIcon = False
	bOnStartup = False
	InstallPCReservationReservationStation(bDesktopIcon, bOnStartup)
	


	; Install LPT One Print Release Terminal
	bLPTDesktopIcon = true
	bLPTOnStartup = true
	InstallLPTOnePrintReleaseTerminal(bLPTDesktopIcon, bLPTOnStartup)

	bEWLaunchDesktopIcon = True
	bEWLaunchOnStartup = True
	InstallEWLaunch(bEWLaunchDesktopIcon, bEWLaunchOnStartup)


}

;-------------------------------------------------------------------------------
;	Installs PC Reservation Station the version of PC Res that is used to make
; computer reservations but does not lock the computers. As of now, the config 
; file does not make the computer a dedicated Reservation Station but instead 
; has Reservation Station be a smaller window that does not interfere with other
; uses. By Default this function creates a desktop shortcut for 
; Reservation Station. Because EnvisionWare's silent Installer does not support
; Command Line Configuaration (You can configure the install via command line 
; but this prevents you from installing silently) we have to do Configuaration 
; after the install.
;-------------------------------------------------------------------------------
InstallPCReservationReservationStation(bDesktopIcon, bOnStartup)
{
	DoLogging("Installing PC Reservation Station")
	Global strResourcesPath
	Global strInstallersPath
	Global strLocation

	; Install Reservation Station
	ExecuteExternalCommand(strInstallersPath . "\_PCReservationStation.exe /S")

	;Check that this is not needed to be changed to be a staff controlled computer
	createFrontLineEwareConfig(strLocation) ;Fixme: This method should be improved so that it is similar to the way that Self-Check builds its config files Issue #32
	strPCResPath := "C:\ProgramData\EnvisionWare\PC Reservation"
	
	; Moves the Config File to the proper location
	ExecuteExternalCommand("robocopy "								; Command
		. strResourcesPath . "\EwareConfig"							; Source
		. " """ . strPCResPath . "\Reservation Station\config""" 	; Dest
		. " /mov")													; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26

	; This command enables the firewall rules that PC Reservation Reservation 
	; Station creates
	ExecuteExternalCommand("powershell.exe -Command ""& { "
		. " Get-NetFirewallRule | where {$_.DisplayName -like '*reservation*'}"
		. " | Set-NetFirewallRule -Action Allow"
		. "}")

	If (!bDesktopIcon) {
		DoLogging("Deleteing PC Reservation Reservation Station Desktop Icon")
		ExecuteExternalCommand("del ""C:\Users\Public\Desktop\PC Reservation "
			. "Reservation Station.lnk""")
	} Else {
		; By Default PC Reservation Station gets a desktop Icon so we don't have
		; to change anything
		; DO NOTHING
	}

	If (!bOnStartup) {
		DoLogging("Removing PC Reservation Reservation Station from Startup")
		ExecuteExternalCommand("del ""C:\ProgramData\Microsoft\Windows\"
			. "Start Menu\Programs\StartUp\"
			."PC Reservation Reservation Station.lnk""")
	} Else {
		; By Default PC Reservation starts on startup so if we want  don't have
		; to change anything
		; DO NOTHING
	}
}

;-------------------------------------------------------------------------------
; Installs LPT One Print Release Terminal. LPT One Print Release Terminal
; functions in some bizarre way where the config files are not actually what 
; specifiy the target server. Instead the target IP and port and indiciated via
; the desktop shortcut, because of this LPT One Print Release will always
; create and leave behind a desktop icon, otherwise it would not be possible to
; indicate what server we are trying to target. Additionally, it creates another
; shortcut that it plays in the LPT One folder that calls the exe with the 
; proper command line arguments. This shortcut will be created regardless of the
; what you specify for Desktop Icon because otherwise LPT One is completely 
; useless.
;-------------------------------------------------------------------------------
InstallLPTOnePrintReleaseTerminal(bDesktopIcon, bOnStartup)
{
	ExecuteExternalCommand(A_ScriptDir . "\Resources\Installers"
		. "\_LPTOnePrintRelease.exe /S")
	; This desktop Icon is created with the default IP and is incorrect and 
	; needs to be deleted.
	ExecuteExternalCommand("del ""C:\Users\Public\Desktop\LPT One Print Release"
		. " Terminal.lnk""")

	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk 	; Target
		, C:\Users\Public\Desktop\LPT One Print Realease Terminal.lnk ; Link Filename
		, ; Standard Working directory							; WorkingDirr
		, 														; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State

	If (!bDesktopIcon) {
		DoLogging("Error: It was specified not to create a LPT One Print"
			. " Release Terminal but the system requires that you create one.")
		FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\lptPRT.exe 	; Target
		, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk ; Link Filename
		, ; Standard Working directory							; WorkingDirr
		, -host:%strEwareServer% -runmode:prompt				; Args 
		, Launch LPT One Print Release Terminal					; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
	} Else {
		FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\lptPRT.exe 	; Target
			, C:\Program Files (x86)\EnvisionWare\Lptone\lptprt\LPT One Print Release Terminal.lnk ; Link Filename
			, ; Standard Working directory							; WorkingDirr
			, -host:%strEwareServer% -runmode:prompt				; Args 
			, Launch LPT One Print Release Terminal					; Description
			, ; Takes icon from file								; Icon
			, ; No Shortcut Key										; Shortcut Key
			, 1														; Icon Number
			, 1														; Run State
	}

	If (!bOnStartup) {
		; LPT One Printer Terminal defaults to not starting at startup so no
		; change is required
		; DO NOTHING
	} Else {
		DoLogging("Error: Having LPT One Print Release Terminal launch on"
			. " startup is not supported yet.") ; FIXME:
	}

	Return
}

;-------------------------------------------------------------------------------
; Installing Sierra is actually pretty simple because instead of actually 
; installing the program we instead simiply robocopy the files to where they are
; supposed to be.
;-------------------------------------------------------------------------------
InstallSierra(bSierraDesktopIcon)
{
	Global strResourcesPath

	; Moves the Seirra Portable app to C: drive
	ExecuteExternalCommand("robocopy " 								; Command
	 	. " """ . strResourcesPath . "\Sierra Desktop App"""		; Target
		. " ""C:\Sierra Desktop App"" "								; Dest
		. " /s  /UNILOG+:C:\Deployment\robocopy_Sierra.log")		; Options

	If (bSierraDesktopIcon) {
		FileCreateShortcut, C:\Sierra Desktop App\iiirunner.exe		; Target
			, C:\Users\Public\Desktop\Sierra Desktop App.lnk		; Link File
			, C:\Sierra Desktop App									; WorkingDir
			, ; No Arguments										; Args 
			, Launch the Sierra Desktop App							; Description
			, C:\IT\Icons\Sierra.ico			; Icon
			, ; No Shortcut Key										; Shortcut Key
			, 1														; Icon Number
			, 1														; Run State
	} Else {
		; By Default This will not create a desktop icon for sierra so if there 
		; is no change needed to not get a desktop icon.
		; Do Nothing
	}

	Return
}

InstallOneStop (bOneStopDesktopIcon, bOneStopOnStartup) 
{
	Run, ClickInstallThread.exe
	ExecuteExternalCommand(strInstallersPath . "\_SelfCheckout.exe /S")

	If (bOneStopDesktopIcon) {
		; By default it will create a desktop Icon so we don't have to change
		; anything
		; DO NOTHING
	} Else {
		DoLogging("Error: Not having a selfcheck desktop Icon is not supported yet.") ; FixMe
	}
	If (bOneStopOnStartup) {
	FileCreateShortcut, C:\Program Files (x86)\EnvisionWare\OneStop\ewSelfCheck.exe	; Target
		, C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\OneStop.lnk ; Link Frenameile
		, C:\Program Files (x86)\EnvisionWare\OneStop\			; WorkingDirr
		, ; No Arguments										; Args 
		, Launch OneStop controller								; Description
		, ; Takes icon from file								; Icon
		, ; No Shortcut Key										; Shortcut Key
		, 1														; Icon Number
		, 1														; Run State
	} Else {
		; The Default is for self Check to not start on starup so we don't
		; have to change anything
		; DO NOTHING
	}

	Return
}

InstallOffice2016(bOfficeDesktopIcons)
{
	; Installs Office 2016
	ExecuteExternalCommand(""A_ScriptDir . "\Resources\Office2016\setup.exe ")

	If (bOfficeDesktopIcons) {
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
	} Else {
		; By Default Office 2016 Does not create the desktop Icons so no changes
		; Are needed
		; DO NOTHING
	}

	Return
}

InstallEWLaunch(bEWLaunchDesktopIcon, bEWLaunchOnStartup)
{
	Global strResourcesPath

	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers\_InstallAAM.exe /S")

	ExecuteExternalCommand("" . A_ScriptDir . "\Resources\Installers\mysql-connector-odbc-5.3.2-win32.msi /passive")

	CreateEWLaunchIndex()
	ExecuteExternalCommand("robocopy "								; Command
		. """" . strResourcesPath . "\Launch Command"""				; Source
		. " C:\" 													; Dest
		. " /e /is /move")											; Options ; Fixme: Have this write a Log similar to how the other robocopies do Issue #26
	Return
}

InstallOffice365 (bOfficeDesktopIcons) {
	; Calls Office 365 installer and runs it with customConfiguration
	Global strResourcesPath
	
	ExecuteExternalCommand(strResourcesPath . "\Office365\setup.exe"
		. " /configure " 											
		. strResourcesPath . "\Office365\customconfiguration_staff.xml")

	If (bOfficeDesktopIcons) {
		strOfficePath := "C:\Program Files (x86)\Microsoft Office\root\Office16"

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
	} Else {
		; By Default Office 365 Will not create Desktop Icons so no changes are 
		; needed
		; DO NOTHING
	}

	Return
}