#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


ExecuteExternalCommand(task) 
{
	Global iTotalErrors
	Global bIsVerbose
	
	Try {
		If (bIsVerbose == 1) {
			DoLogging("** "A_WorkingDir . "> " task)
		} Else {
			DoLogging("** "A_WorkingDir . "> " task, 1)
		}
		shell := ComObjCreate("WScript.Shell") ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
		exec := shell.Exec(ComSpec " /C " task) ; Execute a single command via cmd.exe
		;read the output line by line
		While !exec.StdOut.AtEndOfStream {
			DoLogging("   " exec.StdOut.ReadLine())
		}      
		;; It's important to note that this does NOT get StdErr in parallel with StdOut - if you stack four commands in a row, and the first two fail, you will get their error output AFTER the 3rd and 4th commands finish StdOut.
		If !exec.StdErr.AtEndOfStream {
			iTaskErrors += 1 ; This will only count once even if you stack commands! At least my error handling counts for something again...
			DoLogging("!! STDERR:")
			While !exec.StdErr.AtEndOfStream {
				iTotalErrors = iTotalErrors + 1
				DoLogging("   " exec.StdErr.ReadLine())
			}
		}
		DoLogging("")
	} Catch {
		iTotalErrors += 1
		DoLogging("!! Error attempting External Task: "Task . "!")
	}
}

ExecuteInternalCommand(task) 
{
	Global bIsVerbose
	Global iTotalErrors
	; parse!
	Try {
		strParams := ""
		Loop % task.MaxIndex()
		{
			Element := task[A_Index]
			If (A_Index>1)
			{
				strParams := strParams . Element
			}
			If (A_Index>1 And A_Index<task.MaxIndex())
			{
				strParams := StrParams . ","
			}
		}
		Output := task[1] . "(" . strParams . ")"
		If (bIsVerbose)
		{
			DoLogging("** Executing Internal Task: " Output)
		} Else {
			DoLogging("** Executing Internal Task: " Output, 1)
		}
		Try {
			P := StrSplit(strParams, ",")
			#(task[1], P[1], P[2], P[3], P[4], P[5], P[6], P[7], P[8], P[9], P[10]
				, P[11], P[12], P[13], P[14], P[15], P[16], P[17], P[18], P[19])
		} Catch {
			iTotalErrors += 1
			DoLogging("!! Error attempting Internal Task: "Output . "A_LastError: " . A_LastError)
		}
	} Catch {
		iTotalErrors += 1
		DoLogging("!! Error during parsing!")
	}

	return
}

CreatePatronEwareConfig(location)
{
	;Path to where Servers.ini is found
	serversPath := A_WorkingDir . "\Resources\Servers.ini"
	IniRead, strEwareServer
			, %serversPath%, Servers, %location%
	IniRead, strAutoDiscoveryPort
			, %serversPath%, AutoDiscoveryPort, %location%
	IniRead, strManagementServicePort
			, %serversPath%, ManagementServicePort, %location%

	sourceFileName := "Resources\EwareConfig\TemppcrClient.ewp"
	destinationFileName := "Resources\EwareConfig\pcrClient.ewp"

	intLineNumber := 1 ; ahk starts lines at 1
	boolIsDone := false
	while (!boolIsDone) {
		FileReadLine, strCurrentLine, %sourceFileName%, intLineNumber
		If (ErrorLevel == 1) { ;If we reached end of file we are done
			boolIsDone := True
		} Else {
			strToken1 = Discovery Port Goes Here
			strToken2 = IP Goes Here
			strToken3 = Management Port Goes here
			IfInString, strCurrentLine, %strToken1%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken1
					, strAutoDiscoveryPort
					, 0 ;OutputVarCount
					, -1 )
			} 
			IfInString, strCurrentLine, %strToken2%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken2
					, strEwareServer
					, 0 ;OutputVarCount
					, -1 )
			} 
			IfInString, strCurrentLine, %strToken3%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken3
					, strManagementServicePort
					, 0 ;OutputVarCount
					, -1 )
			} 
			FileAppend, %strCurrentLine% `n , %destinationFileName%
		}
		intLineNumber += 1
	}

	FileAppend, %fileContent%, %destinationFileName%
}

CreateFrontLineEwareConfig(location)
{
	;Path to where Servers.ini is found
	serversPath := A_WorkingDir . "\Resources\Servers.ini"
	IniRead, strEwareServer
		, %serversPath%, Servers, %location%
	IniRead, strAutoDiscoveryPort
		, %serversPath%, AutoDiscoveryPort, %location%
	IniRead, strManagementServicePort
		, %serversPath%, ManagementServicePort, %location%

	sourcefileName := "Resources\EwareConfig\TemprsConfig.ewp"
	destinationFileName := "Resources\EwareConfig\rsConfig.ewp"

	intLineNumber := 1 ; ahk starts lines at 1
	boolIsDone := false
	while (!boolIsDone) {
		FileReadLine, strCurrentLine, %sourceFileName%, intLineNumber
		If (ErrorLevel == 1) { ;If we reached end of file we are done
			boolIsDone := True
		} Else {
			strToken = IP Goes Here
			IfInString, strCurrentLine, %strToken%
			{
				strCurrentLine := StrReplace(strCurrentLine
					, strToken
					, strEwareServer
					, 0 ;OutputVarCount
					, -1 )
			} 
			FileAppend, %strCurrentLine% `n , %destinationFileName%
		}
		intLineNumber += 1
	}

	FileAppend, %fileContent%, %fileName%
}

