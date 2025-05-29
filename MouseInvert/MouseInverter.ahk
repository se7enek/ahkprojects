#SingleInstance, Force
#NoEnv
#Persistent
OnExit, OnExit

SetControlDelay, -1
SetBatchLines, -1
SetMouseDelay, -1
SetWinDelay, -1
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen

#include <FindText>

hHookMouse := DllCall("SetWindowsHookEx"
, "Int", 14
, "Ptr", RegisterCallback("WH_MOUSE_LL")
, "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr")
, "UInt", 0)

Gui, Main: +AlwaysOnTop -Caption -Border +E0x20 
Gui, Main: Color, Yellow

ScreenW := A_ScreenWidth
ScreenH := A_ScreenHeight

cx := ScreenW / 2 ; center x/y pos of screen
cy := ScreenH / 2

ManaBar := {sx : 0.53 * ScreenW
	,sy : 0.84 * ScreenH
	,ex : 0.64 * ScreenW
	,ey : 0.87 * ScreenH}


GroupAdd, Game, ahk_exe LOSTARK.exe

SetTimer, IfConfused, 500
; Sleep, 1000
; ToolTip
; SetTimer, IfConfused, Off
Return

IfConfused:
; Global Invert
; ToolTip, If %Invert%
; MouseGetPos, xxx, yyy
; ToolTip, % xxx "`n" yyy
If (FindText().ImageSearch(x,y, ManaBar.sx, ManaBar.sy, ManaBar.ex, ManaBar.ey, A_ScriptDir "\confusion.png")) {
	SetTimer, IfConfused, Off
	BlockInput, MouseMove
	MouseGetPos, sx, sy ; starting mouse pos
	mx := ScreenW - sx ; new mouse x/y symmetrical
	my := ScreenH - sy
	gx := sx - 25
	gy := sy - 25
    Gui, Main: Show, NoActivate w51 h51 x%gx% y%gy%, MouseSpot
    WinSet, Trans, 200, MouseSpot
    WinSet, Region, 0-0 W51 H51 E, MouseSpot
	DllCall("SetCursorPos", "Int", mx, "Int", my)
	Sleep, 50
	Invert := True
	BlockInput, MouseMoveOff
	SetTimer, IfStillConfused, 500
}
Return

IfStillConfused:
; Global Invert
; ToolTip, If Still %Invert%
; tu gdzies jest blad ze nie chce myszka przeskoczyc
If (!FindText().ImageSearch(x,y,ManaBar.sx, ManaBar.sy, ManaBar.ex, ManaBar.ey, A_ScriptDir "\confusion.png")) {
	SetTimer, IfStillConfused, Off
	BlockInput, MouseMove
	
	MouseGetPos, sx, sy ; starting mouse pos
	mx := ScreenW - sx ; new mouse x/y symmetrical
	my := ScreenH - sy
	Gui, Main: Hide
	DllCall("SetCursorPos", "Int", mx, "Int", my)
	Sleep, 100
	Invert := False
	SetTimer, IfConfused, 500
	BlockInput, MouseMoveOff
}
Return



q::
Invert := !Invert
BlockInput, MouseMove
MouseGetPos, sx, sy ; starting mouse pos
mx := ScreenW - sx ; new mouse x/y symmetrical
my := ScreenH - sy

If(!Invert) {
	; section to run when its supposed to be no longer inverted
    Gui, Main: Hide
	; show_Mouse(True)
}
else {
	; section to run when its about to be inverted
	; SystemCursor(False)
	; show_Mouse(False)
	; dllcall("ShowCursor","int",0)
	gx := sx - 25
	gy := sy - 25
    Gui, Main: Show, NoActivate w51 h51 x%gx% y%gy%, MouseSpot
    WinSet, Trans, 200, MouseSpot
    WinSet, Region, 0-0 W51 H51 E, MouseSpot
}

DllCall("SetCursorPos", "Int", mx, "Int", my)
Sleep, 50
BlockInput, MouseMoveOff
Return

OnExit:
UnhookWindowsHookEx(hHookMouse)
ExitApp


WH_MOUSE_LL(nCode, wParam, lParam)
{
	Global
    Static lx:=999999, ly
	Critical
	
	if !nCode && (wParam = 0x200) {

		if (!Invert && lx != 999999) { ;normal behaviour
			lx := 999999
			ly := 999999
		}
		else if (Invert) { ; inverted mouse
			mx := NumGet(lParam+0, 0, "Int")
			my := NumGet(lParam+0, 4, "Int")
			
			;move gui opposite of mouse
			WinMove, MouseSpot,, ScreenW - mx - 25, ScreenH - my - 25
	
			if (lx != 999999) ; if mouse moves 1 pixel to left, then set mouse for 1 pixel to right
			{
				mx := lx - (mx - lx)
				my := ly - (my - ly)
				if (mx > A_screenwidth)
					mx := A_screenwidth
			}

			;move cursor pos to proper inverted position
			DllCall("SetCursorPos", "Int", mx, "Int", my)

			;save mouse pos for if function (6 lines above) in next iteration
			VarSetCapacity(lpPoint,8)
			DllCall("GetCursorPos", "Uint", &lpPoint)
			lx := NumGet(lpPoint, 0, "Int")
			ly := NumGet(lpPoint, 4, "Int")
	
			if(lx > A_ScreenWidth-5)
				lx := A_ScreenWidth-5
	
			NumPut(lx, lParam+0, 0, "Int")
			NumPut(ly, lParam+0, 4, "Int")
			ret:=DllCall("CallNextHookEx", "Uint", 0, "int", nCode, "Uint", wParam, "Uint", lParam)
			Return 1
		}
		
	}
	else
		Return DllCall("CallNextHookEx", "Uint", 0, "int", nCode, "Uint", wParam, "Uint", lParam)
}
SetWindowsHookEx(idHook, pfn)
{
	Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0)
}
UnhookWindowsHookEx(hHook)
{
	Return DllCall("UnhookWindowsHookEx", "Uint", hHook)
}

CallNextHookEx(nCode, wParam, lParam, hHook = 0)
{
	Return DllCall("CallNextHookEx", "Uint", hHook, "int", nCode, "Uint", wParam, "Uint", lParam)
}

SystemCursor(OnOff := 1) {  ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
 ; https://www.autohotkey.com/boards/viewtopic.php?t=6167
 Static AndMask, XorMask, $, h_cursor
  , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; Blank cursors
  , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; Handles of default cursors
  , c := StrSplit("32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650", ",")
 If (OnOff = "Init" || OnOff = "I" || $ = "") {  ; Init when requested or at first call
  $ = h                                          ; Active default cursors
  VarSetCapacity(h_cursor,4444, 1), VarSetCapacity(AndMask, 32*4, 0xFF), VarSetCapacity(XorMask, 32*4, 0)
  For each, cursor in c {
   h_cursor := DllCall("LoadCursor", "Ptr",0, "Ptr", cursor)
   h%each%  := DllCall("CopyImage", "Ptr", h_cursor, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0)
   b%each%  := DllCall("CreateCursor", "Ptr", 0, "Int", 0, "Int", 0
                     , "Int", 32, "Int", 32, "Ptr", &AndMask, "Ptr", &XorMask)
  }
 }
 $ := OnOff = 0 || OnOff = "Off" || $ = "h" && (OnOff < 0 || OnOff = "Toggle" || OnOff = "T") ? "b" : "h"
 For each, cursor in c {
  h_cursor := DllCall("CopyImage", "Ptr", %$%%each%, "UInt", 2, "Int", 0, "Int", 0, "UInt", 0)
  DllCall("SetSystemCursor", "Ptr", h_cursor, "UInt", cursor)
 }
}

;-------------------------------------------------------------------------------
show_Mouse(bShow := True) { ; show/hide the mouse cursor
	;-------------------------------------------------------------------------------
		; WINAPI: SystemParametersInfo, CreateCursor, CopyImage, SetSystemCursor
		; https://msdn.microsoft.com/en-us/library/windows/desktop/ms724947.aspx
		; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648385.aspx
		; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648031.aspx
		; https://msdn.microsoft.com/en-us/library/windows/desktop/ms648395.aspx
		;---------------------------------------------------------------------------
		static BlankCursor
		static CursorList := "32512, 32513, 32514, 32515, 32516, 32640, 32641"
			. ",32642, 32643, 32644, 32645, 32646, 32648, 32649, 32650, 32651"
		local ANDmask, XORmask, CursorHandle
	
		If bShow ; shortcut for showing the mouse cursor
	
			Return, DllCall("SystemParametersInfo"
				, "UInt", 0x57              ; UINT  uiAction    (SPI_SETCURSORS)
				, "UInt", 0                 ; UINT  uiParam
				, "Ptr",  0                 ; PVOID pvParam
				, "UInt", 0                 ; UINT  fWinIni
				, "Cdecl Int")              ; return BOOL
	
		If Not BlankCursor { ; create BlankCursor only once
			VarSetCapacity(ANDmask, 32 * 4, 0xFF)
			VarSetCapacity(XORmask, 32 * 4, 0x00)
	
			BlankCursor := DllCall("CreateCursor"
				, "Ptr", 0                  ; HINSTANCE  hInst
				, "Int", 0                  ; int        xHotSpot
				, "Int", 0                  ; int        yHotSpot
				, "Int", 32                 ; int        nWidth
				, "Int", 32                 ; int        nHeight
				, "Ptr", &ANDmask           ; const VOID *pvANDPlane
				, "Ptr", &XORmask           ; const VOID *pvXORPlane
				, "Cdecl Ptr")              ; return HCURSOR
		}
	
		; set all system cursors to blank, each needs a new copy
		Loop, Parse, CursorList, `,, %A_Space%
		{
			CursorHandle := DllCall("CopyImage"
				, "Ptr",  BlankCursor       ; HANDLE hImage
				, "UInt", 2                 ; UINT   uType      (IMAGE_CURSOR)
				, "Int",  0                 ; int    cxDesired
				, "Int",  0                 ; int    cyDesired
				, "UInt", 0                 ; UINT   fuFlags
				, "Cdecl Ptr")              ; return HANDLE
	
			DllCall("SetSystemCursor"
				, "Ptr",  CursorHandle      ; HCURSOR hcur
				, "UInt", A_Loopfield       ; DWORD   id
				, "Cdecl Int")              ; return BOOL
		}
	}

F12:: ExitApp