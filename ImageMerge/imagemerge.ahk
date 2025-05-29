#Persistent
#SingleInstance, Force
#NoEnv
SetBatchLines, -1

#Include, Gdip.ahk

OnClipboardChange("ClipChanged")

global Images := [], X := 0, SelfScript = false

If (!pToken := Gdip_Startup())
    ExitApp
Return

;~LButton::
;MouseGetPos,,Y
;Return

ClipChanged(Type) {
    If (Type != 2 || SelfScript == true)
        Return
    Sleep, 50
    obj := {}
    obj.img := Gdip_CreateBitmapFromClipboard()
    obj.x := X
    obj.h := Gdip_GetImageHeight(obj.img)
    obj.w := Gdip_GetImageWidth(obj.img)
    Images.Push(obj)
    Sleep, 100
}

F4::
TotalWidth := 0
TotalHeight := 0
for i,obj in Images {
    TotalHeight := TotalHeight + obj.h
    If (obj.w > TotalWidth)
        TotalWidth := obj.w
}
;for i,obj in Images {
;    TotalWidth := TotalWidth + obj.w
;    If (obj.h > TotalHeight)
;        TotalHeight := obj.h
;}

pBitmap := Gdip_CreateBitmap(TotalWidth, TotalHeight)

G := Gdip_GraphicsFromImage(pBitmap)


;pBrush := Gdip_BrushCreateSolid(0x36393f00)
pBrush := Gdip_BrushCreateSolid(0xff323339)
Gdip_FillRectangle(G, pBrush, 0, 0, TotalWidth, TotalHeight)
Gdip_DeleteBrush(pBrush)

CurrentHeight := 0
for i,obj in Images {
    Gdip_DrawImage(G, obj.img, 0, CurrentHeight, obj.w, obj.h, 0, 0, obj.w, obj.h)
    ;CurrentWidth := CurrentWidth + obj.w
    CurrentHeight := CurrentHeight + obj.h
    Sleep, 50
    Gdip_DisposeImage(obj.img)
}


SelfScript = true
Gdip_SetBitmapToClipboard(pBitmap)
SelfScript = false

Gdip_DisposeImage(pBitmap)

Gdip_DeleteGraphics(G)
Reload
;Gdip_Shutdown(pToken)
;ExitApp
;Return


