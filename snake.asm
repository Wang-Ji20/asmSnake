.386
.model flat, stdcall
option casemap: none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc
include \masm32\include\gdi32.inc
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\gdi32.lib

.data
    szCaption db "Hello", 0
    szText db "Hello World!", 0
    canvas BYTE DUP(0)
    hInstance DWORD ?
    hwnd DWORD ?
    hdc DWORD ?
    ClassName BYTE "Greedy Snake", 0
    WindowName BYTE "Greedy Snake", 0
    MainWin WNDCLASS <NULL, WinProc, NULL, NULL, NULL, NULL, NULL, COLOR_WINDOW, NULL, ClassName>
    msg MSGStruct <>

.code


main PROC
    INVOKE GetModuleHandle, Null
    mov hInstance, eax
    mov MainWin.hInstance, eax

    INVOKE RegisterClass, ADDR MainWin
    .IF eax == 0
        call ErrorHandler
        jmp Exit_Program
    .ENDIF

    INVOKE CreateWindowEx, 0, ADDR ClassName,
        ADDR WindowName, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL, NULL, hInstance, NULL
    
    .IF eax == 0
        call ErrorHandler
        jmp Exit_Program
    .ENDIF

    mov hwnd, eax
    INVOKE ShowWindow hwnd, SW_SHOW

Message_Loop:
    INVOKE GetMessage, ADDR msg, NULL, NULL, NULL
    .IF eax == 0
        jmp Exit_Program
    .ENDIF
    
    INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
    INVOKE ExitProcess, 0

main ENDP

WinProc PROC,
    hWnd:DWORD, localMsg:DWORD, 
    wParam, lParam

    


END main
