
if (A_Args.Length() = 0 ) 
{
	MsgBox, % "usage: reload-firefox.exe <WindowTitle> <TabTitle>"
}

AppTitle := A_Args[1]
; AppTitle = Mozilla Firefox

CmdWindowTitle := A_Args[2]
; CmdWindowTitle = olaf@3rdQUAD

SiteTitle := A_Args[3]
; SiteTitle = A3quer---1stLevelVorlage.svg




; MsgBox, % SiteTitle

MaxTabs = 10

SetTitleMatchMode 2

IfWinNotExist, %AppTitle%
  Goto Ende

WinActivate, %AppTitle%

SetTitleMatchMode 1

; WinActivate, %SiteTitle% – %AppTitle%

IfWinActive, %SiteTitle% – %AppTitle%
	Goto DoReload

Loop, %MaxTabs%
{
	Send, ^{TAB}
	Sleep, 50
	ifWinActive, %SiteTitle%
	   Break
}

DoReload:
Send, ^R


Ende:



WinActivate, %CmdWindowTitle%