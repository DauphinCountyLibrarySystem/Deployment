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

