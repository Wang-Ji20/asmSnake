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

szText macro name, text:vararg
    local lbl
    jmp lbl
    name db text, 0
    lbl:
endm

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
WndProc proto :DWORD, :DWORD, :DWORD, :DWORD

.data
    hinitInstance DWORD ?
    lpszinitCmdLine DWORD ?
    
    FPS DWORD 15
    canvas db 640 DUP(' '), 0
    head_pos_x1 DWORD 1
    head_pos_y1 DWORD 1
    head_pos_x2 DWORD 78
    head_pos_y2 DWORD 78
    length1 DWORD 3
    length1 DWORD 3
    direction1 DWORD 0
    direction2 DWORD 0
    dtmp1 DWORD 0
    dtmp2 DWORD 0

    g_hdc HDC 0
    g_mdc HDC 0
    g_bufdc HDC 0
    g_hfoodBitmap HBITMAP 0
    g_hsnake1Bitmap HBITMAP 0
    g_hsnake2Bitmap HBITMAP 0
    g_hwallBitmap HBITMAP 0

    player2wintxt db "Player2 win!", 0
    player1wintxt db "Player1 win!", 0
    gameovertxt db "Game over", 0

.code

lose PROC x :DWORD, y :DWORD
    .IF (x >= 80) || (y >= N) || (x < 0) || (y < 0)
        mov eax, 1
        ret
    .ENDIF
    .IF (canvas[x * 80 + y] == '*') || (canvas[x * 80 + y] >= '@')
        mov eax, 1
        ret
    .ENDIF
    mov eax, 0
    ret

lose ENDP

win PROC length :DWORD
    mov eax, 0
    .IF length >= 20
        mov eax, 1
    .ENDIF
    ret
win ENDP

snake_creep PROC hwnd :HWND
    mov eax, dtmp1
    mov direction1, eax
    mov eax, dtmp2
    mov direction2, eax
    .IF direction1 == 0
        dec head_pos_x1
    .ELSEIF direction1 == 1
        inc head_pos_x1
    .ELSEIF direction1 == 2
        dec head_pos_y1
    .ELSEIF direction1 == 3
        inc head_pos_y1
    .ENDIF

    .IF direction2 == 0
        dec head_pos_x2
    .ELSEIF direction2 == 1
        inc head_pos_x2
    .ELSEIF direction2 == 2
        dec head_pos_y2
    .ELSEIF direction2 == 3
        inc head_pos_y2
    .ENDIF

    INVOKE lose, head_pos_x1, head_pos_y1
    .IF eax == 1
        INVOKE game_clean, hwnd
        INVOKE MessageBox, 0, offset player2wintxt,
                gameovertxt, 0
        INVOKE ExitProcess, 0
    .ENDIF

    INVOKE lose, head_pos_x2, head_pos_y2
    .IF eax == 1
        INVOKE game_clean, hwnd
        INVOKE MessageBox, 0, offset player1wintxt,
                gameovertxt, 0
        INVOKE ExitProcess, 0
    .ENDIF



snake_creep ENDP

start:
    INVOKE GetModuleHandle, NULL
    mov hinitInstance, eax

    INVOKE GetCommandLine
    mov lpszinitCmdLine, eax

    INVOKE WinMain, hinitInstance, NULL, lpszinitCmdLine, SW_SHOWDEFAULT
    INVOKE ExitProcess, eax


WinMain PROC hInstance :DWORD,
             hPrevInst :DWORD,
             szCmdLine :DWORD,
             nShowCmd :DWORD

    szText szClassName, "GreedySnake"

    local wc :WNDCLASSEX
    local hwnd :HWND

    mov wc.lpfnWndProc, WndProc
    push hInstance
    pop wc.hInstance
    mov wc.lpszClassName, offset szClassName

    invoke	LoadCursor, hInstance, IDC_ARROW
	mov	wc.hCursor, eax

    INVOKE RegisterClassEx, ADDR wc

    szText szWindowTitle, "Greedy Snake"
    INVOKE CreateWindowEx, 0, ADDR szClassName,
        ADDR szWindowTitle, WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        NULL, NULL, hInstance, NULL
    
    .IF eax == 0
        jmp Exit_Program
    .ENDIF

    mov hwnd, eax
    INVOKE ShowWindow, hwnd, nShowCmd
    local msg :MSG

Message_Loop:
    INVOKE GetMessage, ADDR msg, NULL, NULL, NULL
    .IF eax == 0
        jmp Exit_Program
    .ENDIF

    INVOKE TranslateMessage, ADDR msg
    INVOKE DispatchMessage, ADDR msg

    jmp Message_Loop

Exit_Program:
    INVOKE ExitProcess, 0

WinMain ENDP


WndProc PROC,
    hwnd:DWORD, uMsg:DWORD, 
    wParam:DWORD, lParam:DWORD

    .IF uMsg == WM_DESTROY
         INVOKE PostQuitMessage, 0

         xor eax, eax
         ret
    
    .ENDIF

    INVOKE DefWindowProc, hwnd, uMsg, wParam, lParam

WinProcExit:
    ret    

WndProc ENDP

END start
