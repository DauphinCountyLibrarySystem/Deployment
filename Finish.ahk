#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.




__Finish__:
{
	Gosub, __subCleanupJobs__

	Gosub, __subFinishAndExit__
}

__subCleanupJobs__:
{  
	DoLogging(" ")
	DoLogging("__ __subCleanupJobs__")
	DoLogging("ii Registry and file cleanup...")
	arrCleanupJobsList := []
	arrCleanupJobsList.Insert(["RegWrite", "REG_DWORD"
		, "HKEY_LOCAL_MACHINE\SOFTWARE\LogMeIn\V5\Gui", "EnableSystray", "0"])
	arrCleanupJobsList.Insert(["FileDelete"
		, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Control Panel.lnk"])
	arrCleanupJobsList.Insert(["FileDelete"
		, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\LogMeIn Client.lnk"])
	If (strComputerRole == "Patron")
	{
		arrCleanupJobsList.Insert(["RegWrite", "REG_SZ"
			, "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run"
			, "PatronAdminPanel", """C:\PatronAdminPanel\PatronAdminPanel.exe"""])
		iTotalErrors += ClosePCReservation(5)
	}
	If (strComputerRole == "Catalog")
	{
		arrCleanupJobsList.Insert(["RegWrite", "REG_SZ"
			, "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run"
			, "EncoreAways", """C:\EncoreAlways\EncoreAlways.exe"""])
	}
	;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete1", "cmd.exe /c RD /S /Q C:\Deployment"])
	;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete2", "cmd.exe /c RD /S /Q C:\Deployment > c:\00_runonce.log"])
	arrCleanupJobsList.Insert(["RegWrite", "REG_SZ"
		, "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce"
		, "SelfDelete", "cmd.exe /c Robocopy.exe C:\Deployment\Resources\Empty " 
			. "C:\Deployment /MIR /XF *.log /UNILOG+:c:\Deployment\robocopy_selfdelete.log"])
	;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete4", "cmd.exe /c RD /S /Q C:\Deployment > c:\02_runonce_on_empty.log"])
	;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete5", "powershell.exe -Command ""& { Remove-Item -Path C:\Deployment -Recurse -Force | Out-File C:\03_powershell_remove-item.log }"" "])
	;arrCleanupJobsList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce", "SelfDelete6", "cmd.exe /c c:\selfdelete.cmd > c:\selfdelete.log"])
	iTotalErrors += DoInternalTasks(arrCleanupJobsList, bIsVerbose)

	;Deleting tasks from Windows task scheduler is an external task
	arrExternalCleanupJobs := []
	arrExternalCleanupJobs.insert("powershell.exe -Command ""& { Unregister-ScheduledTask -TaskName RestartConfigureImage -Confirm:$false }""")
	iTotalErrors += DoExternalTasks(arrExternalCleanupJobs, bIsVerbose)

	Return
}

__subFinishAndExit__:
{
	If (iTotalErrors > 0) ; Final check for errors and closes program.
	{
		DoLogging("!! Configuration INCOMPLETE! There were " iTotalErrors . " errors with this run.")
		SoundPlay *16
		errorMsg := "There were " iTotalErrors . " error(s) durring configuration.`n"
			. "Something(s) may not have been configured or installed properly.`n"
			. "Check the log to to see more details."
		MsgBox, 16, Configuration INCOMPLETE,  %errorMsg%
		ExitApp, 2 ; indicates errors
	} Else {
		DoLogging("== Configuration Successful! There were " iTotalErrors . " errors with this program.")
		SoundPlay *64
		successMsg := "Configuration completed successfully!`n"
			. "Restarting in 10 seconds unless canceled. . ."
		;This msgBox will time out after 10 seconds
		MsgBox, 1, Configuration Successful,  %successMsg%, 10 
		IfMsgBox, Cancel
			ExitApp, 0
		Shutdown, 2 ; Reboots computer.
		ExitApp, 0 ; indicates success
	}
}