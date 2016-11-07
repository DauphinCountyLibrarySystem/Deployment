;#warn
If Not A_IsAdmin
{
    If A_IsCompiled
    Run *RunAs "%A_ScriptFullPath%"
    Else
    Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
    ExitApp
}

;MsgBox(text)
;{
;	MsgBox % text
;}

;cmd := "MsgBox"
;param := " hi"

;%cmd%(param)

arrAddAutoLogonList := []

arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "AutoAdminLogon", "0"])
;arrAddAutoLogonList.Insert(["RegWrite", "REG_SZ", "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon", "DefaultDomainName", "dcls.org"])
DoInternalTasks(arrAddAutoLogonList)

DoInternalTasks(arrTasks) ; Loops through an array of task commands, trying and logging each one.
{
  
  Loop % arrTasks.MaxIndex()
  {
    Task := arrTasks[A_Index]
    ;strParams := ""
    Loop % Task.MaxIndex()
    {
    	Element := Task[A_Index]
    	Try {
        If (A_Index>1)
        {
          strParams := strParams . Element
        }
        If (A_Index>1 And A_Index<Task.MaxIndex())
        {
          strParams := StrParams . ","
        }
    	} Catch {
    		;catch here
    	}
    }
    ;MsgBox % "Trying:`n" . Task[1] . "`nwith elements:`n" . strParams
    Task[1](strParams)
  }
}

RegWrite(strInput)
{
  Try {
    StringSplit, arrParams, strInput, `,
    ;MsgBox % "RegWrite, `n" arrParams1 "`n" arrParams2 "`n" arrParams3 "`n" arrParams4
    RegWrite, %arrParams1%,%arrParams2%,%arrParams3%,%arrParams4%
    } Catch {
      MsgBox Cthulhu!
    }
}