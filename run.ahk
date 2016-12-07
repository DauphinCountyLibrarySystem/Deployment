; The following can be used to run a command and retrieve its output:
RunWait, %comspec% /c "ping 127.0.0.1"
MsgBox % RunWaitOne("ping 127.0.0.1")

; ...or run multiple commands in one go and retrieve their output:
MsgBox % RunWaitMany("
(
PING 127.0.0.1
)")

RunWaitOne(command) {
    ; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
    shell := ComObjCreate("WScript.Shell")
    ; Execute a single command via cmd.exe
    exec := shell.Exec(ComSpec " /C " command)
    ; Read and return the command's output
    return exec.StdOut.ReadAll()
}

RunWaitMany(commands) {
    shell := ComObjCreate("WScript.Shell")
    ; Open cmd.exe with echoing of commands disabled
    exec := shell.Exec(ComSpec " /K echo off")
    ;exec := shell.Exec(ComSpec " /Q /K echo off")
    ; Send the commands to execute, separated by newline
    exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
    ; Read and return the output of all commands
    return exec.StdOut.ReadAll()
}