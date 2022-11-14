#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_MyDocuments%\Warcraft III\CustomMapData\Aspect of Doom saves\
; SetWorkingDir, C:\Users\Hartsock\OneDrive\Documents\Warcraft III\CustomMapData\Aspect of Doom saves\

accts := new DataStructure()
AccountListGUIValue :=

^l::
load_data:
    ;Loop over all files in the selected folder.
    files := []
    Loop, Files, %A_WorkingDir%\*, FD
    {
        fileNameContent := ""
        rowStuff := {}

        ; Read file content and get load code for the file
        Loop, Read, %A_WorkingDir%\%A_LoopFileName%
        {
            Loop, parse, A_LoopReadLine, %A_Tab%
            {
                if (InStr(A_LoopField, "( """) > 0)
                    rowStuff["LoadCode"] := StrReplace( SubStr(A_LoopField, InStr(A_LoopField, "( """)+3) , """ )", "" )
            }
        }
        lengthOfDoc := StrLen(A_LoopFileName)

        rowStuff["Account"] := SubStr(A_LoopFileName, 4, InStr(A_LoopFileName, "'s")-4)
        rowStuff["Class"] := SubStr(A_LoopFileName, InStr(A_LoopFileName, "'s")+3, InStr(A_LoopFileName, "Level - ") - InStr(A_LoopFileName, "'s") - 4)
        rowStuff["Level"] := StrReplace(SubStr(A_LoopFileName, InStr(A_LoopFileName, " - ")+3), ".txt", "")
        files.Push(rowStuff)
    }

    for index, element in files
    {
        accts.ConsumeData(element["Account"], element["Class"], element["Level"], element["LoadCode"])
    }
    Gosub, LoadBaseGUI
Return

LoadBaseGUI:
    Gui, LoadGUI:New, +AlwaysOnTop +Owner
    Gui, LoadGUI:Default
    Gui, Add, Text, x10 h25 w150 y10, Account
    accts.RenderAccounts()
    Gui, Add, Button, x175 h25 w100 y30 gRefreshSaves vRefreshBtn, &Refresh Saves
    Gui, Show, NoActivate x800 y100 , Window
Return

RefreshSaves:
    ;Gui, Submit, NoHide
    GuiControlGet, AccountListGUIValue, , AccountListGUIValue
    accts.SelectedAccount := AccountListGUIValue
    ;Kill existing rendering before rendering
    accts.KillExistingRendered()
    accts.Render()
Return

Class DataStructure {
    Accounts := []
    SelectedAccount := ""
    ConsumeData(account, character, level, loadCode){
        if (this.Accounts[account] and this.Accounts[account].AccountName == account){
            this.Accounts[account].AddCharacter(character, level, loadCode)
        }
        else{
            this.Accounts[account] := new Acct(account, character, level, loadCode)
        }
    }
    RenderAccounts(){
        ; Render the accounts dropdown.  Auto select the first one found.
        AccountNamesTextList := ""
        for acctIndex, account in this.Accounts{
            AccountNamesTextList .= account.AccountName . "|"
        }
        Gui, Add, DropDownList, vAccountListGUIValue gRefreshSaves Choose1 x10 y30 h25, %AccountNamesTextList%
        Gosub, RefreshSaves
    }
    KillExistingRendered(){
        ; Kill everything dynamically rendered...
    }
    Render(){
        Yval := 75
        ; Give table headers
        Gui, Add, Text, x10 y%Yval% w100, Class To Load
        Gui, Add, Text, x125 y%Yval% w75, Level
        Yval := Yval+25
        ; Generate the characters for the selected account
        for inx, char in this.Accounts[this.SelectedAccount].Characters{
            GUIIndex++
            charName := char.CharacterName
            charNameNoSpaces := StrReplace(charName, " ", "")
            highestLevel := 0
            highestLevelCode := ""
            highestLoad :=
            for loadIndex, load in char.Loads{
                if (highestLevel <= load.level){
                    highestLevel := load.Level
                    highestLevelCode := load.LoadCode
                    highestLoad := load
                }
            }
            char.SetHighestLoadCode(highestLevelCode)
            ; Gui, Add, Text, x10 y%Yval% w200, %charName%
            Gui, Add, Button, x10 y%Yval% w100 h20 hwnd%charNameNoSpaces% gLoadTheCode, %charName%
            Gui, Add, Text, x125 y%Yval% w75, %highestLevel%
            ; onclick := func("LoadTheCode").bind("test")
            ; GuiControl, +g, %charNameNoSpaces%, %onclick%
            Yval := Yval+25
        }
    }
    LoadTheCode(){
        lc := this.Accounts[this.SelectedAccount].Characters[A_GuiControl].HighestLoadCode
        Gui, Destroy
        WinActivate, ahk_exe Warcraft III.exe
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -load %lc%
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -c
        Sleep, 10
        Send, {Enter}
    }
}

LoadTheCode:
    accts.LoadTheCode()
Return

GUIIndex := 0

Class Acct {
    AccountName :=
    Characters := {}
    __New(name, character, level, loadCode){
        this.AccountName := name
        this.Characters[character] = new Character(character, level, loadCode)
        Return this
    }
    AddCharacter(character, level, loadCode){
        if (this.Characters[character] and this.Characters[character].CharacterName == character)
            this.Characters[character].AddLoadCode(level,loadCode)
        else
            this.Characters[character] := new CharacterClass(character, level, loadCode)
    }
}

Class CharacterClass{
    CharacterName :=
    Loads := []
    HighestLoadCode := ""
    __New(characterName, level, loadCode){
        this.CharacterName := characterName
        this.Loads.Push(new CodeInfo(level, loadCode))
        Return this
    }
    AddLoadCode(level, loadCode){
        this.Loads.Push(new CodeInfo(level, loadCode))
    }
    SetHighestLoadCode(loadCode){
        this.HighestLoadCode := loadCode
    }
}

Class CodeInfo{
    Level :=
    LoadCode :=
    ; Maybe items in the future
    __New(level, loadCode){
        this.Level := level
        this.LoadCode := loadCode
        Return this
    }
}

#IfWinActive, ahk_exe Warcraft III.exe
    ^s::
    SaveCharacter:
        if (WinActive("ahk_exe Warcraft III.exe") = 0)
            Return
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -save
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -c
        Sleep, 10
        Send, {Enter}
    Return

    ^r::
    RepickCharacter:
        if (WinActive("ahk_exe Warcraft III.exe") = 0)
            Return
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -repick
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, {Enter}
        Sleep, 10
        Send, -c
        Sleep, 10
        Send, {Enter}
    Return