#SingleInstance, Force
SetBatchLines, -1
#Include %A_ScriptDir%/BARCODER.ahk
#Include %A_ScriptDir%/GDIP_All.ahk

F1::
ISBN:=ClipISBN() ;  "9787122122308"
Msgbox,,,%ISBN%, 1
if(StrLen(ISBN)<1)
{
    Msgbox,,,No ISBN info found, 1
    Return
}
MATRIX_TO_PRINT := BARCODER_GENERATE_CODE_128B(ISBN)
 
if (MATRIX_TO_PRINT = 1)
{
	Msgbox, 0x10, Error, The input message is either blank or contains characters that cannot be encoded in CODE_128B.
	Return
}
TempImgFile:=A_ScriptDir . "\" . "TempISBN.png"
IfExist, %TempImgFile%
    FileDelete, %TempImgFile%
GDI_SaveFile(MATRIX_TO_PRINT,TempImgFile)

Gui, Add, Picture, w300 h200, %TempImgFile%
Gui, Show
; msgbox, 0, Success, CODE128B image succesfully created!
Return
GuiEscape:
Reload

F2::Reload
ClipISBN()
{
    send,^c
    ClipWait, 1
    ISBN=%Clipboard%
    ; ISBN:=StrReplace(ISBN, "-" , "")
    ; ISBN:=Trim(ISBN)
    ISBN:=ExtractNumbers(ISBN)
    IsISBNPos:=RegExMatch(ISBN, "([0-9]{10,13})",SubPat)
    Return SubPat1
}
ExtractNumbers(sInput)
{
    Numbers:=""
    CharArray := StrSplit(sInput)
    Loop % CharArray.MaxIndex()
    {
        this_char := CharArray[A_Index]
        If (this_char is integer) 
            Numbers:=Numbers . this_char
    }
    Return, Numbers

}
GDI_SaveFile(MATRIX_TO_PRINT,ImgFileFullPath)
{
    ; Start gdi+
    If !pToken := Gdip_Startup()
    {
        MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
        ExitApp
    }
    
    HEIGHT_OF_IMAGE := 80 ; 20 is the arbitrary height of the Barcode image for this example. You can chage it to any number to increase/decrease the height of the image. Since a scanner must get an accurate vision of a full line, a taller image may offer a higher chance that a physically damaged print will have at least 1 fully readable line (This should not be confused with QR Codes Error Correction Level protection though).
    
    pBitmap := Gdip_CreateBitmap(MATRIX_TO_PRINT.MaxIndex() + 8, HEIGHT_OF_IMAGE) ; Adding 8 pixels to the width here as a "quiet zone" for the image. This serves to improve the printed code readability.
    G := Gdip_GraphicsFromImage(pBitmap)
    Gdip_SetSmoothingMode(pBitmap, 3)
    pBrush := Gdip_BrushCreateSolid(0xFFFFFFFF)
    Gdip_FillRectangle(G, pBrush, 0, 0, MATRIX_TO_PRINT.MaxIndex() + 8, HEIGHT_OF_IMAGE) ; Same as above
    Gdip_DeleteBrush(pBrush)
 
 
    Loop % HEIGHT_OF_IMAGE
    {
        CURRENT_ROW := A_Index
        Loop % MATRIX_TO_PRINT.MaxIndex()
        {
            CURRENT_COLUMN := A_Index
            If (MATRIX_TO_PRINT[A_Index] = 1)	
            {
                Gdip_SetPixel(pBitmap, CURRENT_COLUMN + 3, CURRENT_ROW, 0xFF000000) ; Adding 3 to the current column and the current row to skip the quiet zones.
            }
        }
    }
 
    CURRENT_ROW := "", CURRENT_COLUMN := "" 

    Gdip_SaveBitmapToFile(pBitmap, ImgFileFullPath)
    Gdip_DisposeImage(pBitmap)
    Gdip_DeleteGraphics(G)
    Gdip_Shutdown(pToken)
}
