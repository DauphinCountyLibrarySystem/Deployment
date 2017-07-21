#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


ExecuteExternalCommand(task, Verbosity) 
{
    Try {
      If (Verbosity == 1)
      {
        DoLogging("** "A_WorkingDir . "> " task)
      } Else {
        DoLogging("** "A_WorkingDir . "> " task, 1)
      }
      shell := ComObjCreate("WScript.Shell") ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
      exec := shell.Exec(ComSpec " /C " task) ; Execute a single command via cmd.exe
      While !exec.StdOut.AtEndOfStream ;read the output line by line
      {
        DoLogging("   " exec.StdOut.ReadLine())
      }      
      ;
      If !exec.StdErr.AtEndOfStream ; It's important to note that this does NOT get StdErr in parallel with StdOut - if you stack four commands in a row, and the first two fail, you will get their error output AFTER the 3rd and 4th commands finish StdOut.
      {
        iTaskErrors += 1 ; This will only count once even if you stack commands! At least my error handling counts for something again...
        DoLogging("!! STDERR:")
        While !exec.StdErr.AtEndOfStream
        {
          DoLogging("   " exec.StdErr.ReadLine())
        }
      }
      DoLogging("")
    } Catch {
      iTaskErrors += 1
      DoLogging("!! Error attempting External Task: "Task . "!")
    }
  }
}