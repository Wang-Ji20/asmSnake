.386
.model flat, stdcall
option casemap: none

include \masm32\include\msvcrt.inc
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc


snakeall@16 PROTO C, hwnd:HINSTANCE, :HINSTANCE, :PWSTR, :DWORD
.data
    hinitInstance DWORD ?
    lpszinitCmdLine DWORD ?

.code
main PROC C
    INVOKE GetModuleHandle, NULL
    mov hinitInstance, eax

    INVOKE GetCommandLine
    mov lpszinitCmdLine, eax

    INVOKE snakeall@16, hinitInstance, NULL, lpszinitCmdLine, SW_SHOWDEFAULT
    INVOKE ExitProcess, eax
main ENDP
END