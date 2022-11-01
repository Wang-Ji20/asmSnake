TITLE Windows Application                   (WinApp_v2.asm)

; Another version of WinApp.asm
; Modified by: HenryFox
; Last update: 10/13/21
; Original version uses Irvine32 and GraphWin, this version uses windows.inc

; This program displays a resizable application window and
; several popup message boxes.
; Thanks to Tom Joyce for creating a prototype
; from which this program was derived.

.386
.model flat, C
option casemap: none

include         windows.inc
include         gdi32.inc
includelib      gdi32.lib
include         user32.inc
includelib      user32.lib
include         kernel32.inc
includelib      kernel32.lib
include         masm32.inc
includelib      masm32.lib
include         msvcrt.inc
includelib      msvcrt.lib
include         shell32.inc
includelib      shell32.lib
includelib ole32.lib 
includelib oleaut32.lib 
includelib comctl32.lib
include comctl32.inc
include ole32.inc
include oleaut32.inc
;------------------ Structures ----------------

WNDCLASS STRUC
  style           DWORD ?
  lpfnWndProc     DWORD ?
  cbClsExtra      DWORD ?
  cbWndExtra      DWORD ?
  hInstance       DWORD ?
  hIcon           DWORD ?
  hCursor         DWORD ?
  hbrBackground   DWORD ?
  lpszMenuName    DWORD ?
  lpszClassName   DWORD ?
WNDCLASS ENDS

MSGStruct STRUCT
  msgWnd        DWORD ?
  msgMessage    DWORD ?
  msgWparam     DWORD ?
  msgLparam     DWORD ?
  msgTime       DWORD ?
  msgPt         POINT <>
MSGStruct ENDS

MAIN_WINDOW_STYLE = WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU \
	+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME

;--------------------------;
; My Function Declarations ;
;--------------------------;
SnakeCreep  PROTO :HWND
GamePaint 	PROTO :HWND
GameInit	PROTO :HWND
GameClean   PROTO :HWND
win PROTO :DWORD, :DWORD
lose PROTO :DWORD
myloadFood PROTO C
myloadWall PROTO C
myloadSnake1 PROTO C
myloadSnake2 PROTO C
mySelectObject PROTO C, :DWORD, :DWORD
myBitBlt PROTO C, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
myCreateCompatibleDC@4 PROTO C, :DWORD
myCreateCompatibleBitmap PROTO C, :DWORD, :DWORD, :DWORD
myReleaseDC PROTO C, :DWORD, :DWORD
myGetDC PROTO C, :DWORD
debug_canvas PROTO C, :DWORD
getoffset PROTO C, :DWORD, :DWORD
randomNumber PROTO C
;-----------------------;
; My Macro Declarations ;
;-----------------------;


; change the arr (var:32bit)
Mov2dArr MACRO arr,varX,varY,value
	pushad
	mov eax, w_N
	mul varX
	add eax, varY
	mov [arr + eax], value
	popad
ENDM

; get the arr (var:32bit)
Get2dArr MACRO arr,varX,varY,dest
	push edx
	mov eax, w_N
	mul varX
	add eax, varY
	mov dest, [arr + eax]
	pop edx
ENDM

;==================== DATA =======================
.data

AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
PopupText  BYTE "This window was activated by a "
	       BYTE "WM_LBUTTONDOWN message",0

GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

CloseMsg   BYTE "WM_CLOSE message received",0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0
debug_num BYTE "%d", 10, 13, 0
message1 BYTE "im alive", 10, 13, 0

;------------------------------------------------------------
; Some Names
foodAssetPath		BYTE "food.bmp"
snake1AssetPath		BYTE "snake1.bmp"
snake2AssetPath		BYTE "snake2.bmp"
wallAssetPath		BYTE "wall.bmp"

;------------------------------------------------------------
; Game Config&State Global Vars
w_WIDTH				DWORD 800
w_N					DWORD 80
FPS 				DWORD 15
canvas 				BYTE 6400 DUP(?), 0	; 80x80=640?

dtmp1				DWORD 0
dtmp2				DWORD 0
head_pos_x1 		DWORD 1
head_pos_y1 		DWORD 1
head_pos_x2 		DWORD 78
head_pos_y2 		DWORD 78
length1 			DWORD 3
length2 			DWORD 3
direction1 			DWORD 0
direction2 			DWORD 0
ii DWORD 0
;------------------------------------------------------------
; for test
testmsg				BYTE "test", 10, 13, 0
keyboardMsgFmt		BYTE "You have entered %c", 10, 13, 0

;------------------------------------------------------------
; WinProc Vars
ps					PAINTSTRUCT <>

;------------------------------------------------------------
; GamePaint Vars
g_hdc				HDC 0
g_mdc				HDC 0
g_bufdc				HDC 0

g_hfoodBitmap		HBITMAP 0
g_hsnake1Bitmap		HBITMAP 0
g_hsnake2Bitmap		HBITMAP 0
g_hwallBitmap		HBITMAP 0

;------------------------------------------------------------

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

;=================== CODE =========================
.code
WinMain PROC
; Get a handle to the current process.
	INVOKE GetModuleHandle, NULL
	mov hInstance, eax
	mov MainWin.hInstance, eax

; Load the program's icon and cursor.
	INVOKE LoadIcon, NULL, IDI_APPLICATION
	mov MainWin.hIcon, eax
	INVOKE LoadCursor, NULL, IDC_ARROW
	mov MainWin.hCursor, eax

; Register the window class.
	INVOKE RegisterClass, ADDR MainWin
	.IF eax == 0
	  call ErrorHandler
	  jmp Exit_Program
	.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
	INVOKE CreateWindowEx, 0, ADDR className,
	  ADDR WindowName,MAIN_WINDOW_STYLE,
	  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
	  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
	mov hMainWnd,eax

; If CreateWindowEx failed, display a message & exit.
	.IF eax == 0
	  call ErrorHandler
	  jmp  Exit_Program
	.ENDIF

; Show and draw the window.
	INVOKE ShowWindow, hMainWnd, SW_SHOW
	INVOKE UpdateWindow, hMainWnd

; Display a greeting message.
	INVOKE MessageBox, hMainWnd, ADDR GreetText,
	  ADDR GreetTitle, MB_OK

; Init the game
	INVOKE GameInit, hMainWnd

; Begin the program's message-handling loop.
Message_Loop:
	; Get next message from the queue.
	INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

	; Quit if no more messages.
	.IF eax == 0
	  jmp Exit_Program
	.ENDIF

	; Translate the message
	INVOKE TranslateMessage, ADDR msg
	
	; Relay the message to the program's WinProc.
	INVOKE DispatchMessage, ADDR msg
    jmp Message_Loop

Exit_Program:
	  INVOKE ExitProcess,0
WinMain ENDP

;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------
	mov eax, localMsg

	.IF eax == WM_LBUTTONDOWN		; mouse button?
		INVOKE MessageBox, hWnd, ADDR PopupText,
			ADDR PopupTitle, MB_OK 
		jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?
		INVOKE MessageBox, hWnd, ADDR AppLoadMsgText,
			ADDR AppLoadMsgTitle, MB_OK
		jmp WinProcExit
	.ELSEIF eax == WM_CLOSE			; close window?
		INVOKE MessageBox, hWnd, ADDR CloseMsg,
			ADDR WindowName, MB_OK
		INVOKE PostQuitMessage,0
		jmp WinProcExit
	.ELSEIF eax == WM_PAINT			; paint?
		INVOKE BeginPaint, 		hWnd, ADDR ps
		mov g_hdc, eax
		INVOKE GamePaint, 		hWnd
		INVOKE EndPaint, 		hWnd, ADDR ps
		INVOKE ValidateRect, 	hWnd, 0
		jmp WinProcExit
	.ELSEIF eax == WM_CHAR			; key down?
		; show which key pressed
		pushad
		INVOKE crt_printf, ADDR keyboardMsgFmt, wParam
		popad
		.IF wParam == 'w' || wParam == 'W' && direction1 == 2 || direction1 == 3
			mov dtmp1, 0
		.ELSEIF wParam == 'a' || wParam == 'A' && direction1 == 0 || direction1 == 1
			mov dtmp1, 2
		.ELSEIF wParam == 's' || wParam == 's' && direction1 == 2 || direction1 == 3
			mov dtmp1, 1
		.ELSEIF wParam == 'd' || wParam == 'D' && direction1 == 0 || direction1 == 1
			mov dtmp1, 3
		.ELSEIF wParam == 'i' || wParam == 'I' && direction2 == 2 || direction2 == 3
			mov dtmp2, 0
		.ELSEIF wParam == 'j' || wParam == 'J' && direction2 == 0 || direction2 == 1
			mov dtmp2, 2
		.ELSEIF wParam == 'k' || wParam == 'K' && direction2 == 2 || direction2 == 3
			mov dtmp2, 1
		.ELSEIF wParam == 'l' || wParam == 'L' && direction2 == 0 || direction2 == 1
			mov dtmp2, 3
		.ENDIF
		INVOKE GamePaint, hWnd
		jmp WinProcExit
	.ELSEIF eax == WM_TIMER
        INVOKE SnakeCreep, hwnd
		INVOKE GamePaint, hWnd
        xor eax, eax
        ret
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF

WinProcExit:
	ret
WinProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

lose PROC x :DWORD, y :DWORD
.IF (x >= 80) || (y >= N) || (x < 0) || (y < 0)
	mov eax, 1
	ret
.ENDIF
Get2dArr canvas, row, col, al
.IF (al == '*') || (al >= '@')
	mov eax, 1
	ret
.ENDIF
mov eax, 0
ret
lose ENDP

win PROC snakelength :DWORD
mov eax, 0
.IF snakelength >= 20
	mov eax, 1
.ENDIF
ret
win ENDP

;----------------------------------------------------------
SnakeCreep PROC,
	hwnd :HWND
; I know a bit about what it does and try to make it work.
;----------------------------------------------------------
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
	INVOKE GameClean, hwnd
	INVOKE MessageBox, 0, offset player2wintxt,
			gameovertxt, 0
	INVOKE ExitProcess, 0
.ENDIF

INVOKE lose, head_pos_x2, head_pos_y2
.IF eax == 1
	INVOKE GameClean, hwnd
	INVOKE MessageBox, 0, offset player1wintxt,
			gameovertxt, 0
	INVOKE ExitProcess, 0
.ENDIF

LOCAL i:DWORD
LOCAL j:DWORD
mov eax, 0
mov i, eax
mov j, eax
LOCAL p:DWORD
.WHILE i < 80
	.WHILE j < 80
		.IF i == head_pos_x1 && j == head_pos_y1
			Get2dArr canvas, i, j, al
			.IF al == '.'
				inc length1
				.WHILE 1
					INVOKE rand
					mov p, eax
					.IF canvas[p] == ' '
						mov canvas[p], '.'
						.BREAK
					.ENDIF
				.ENDW
			.ENDIF
			Mov2dArr canvas, i, j, '@'
		.ENDIF
		.IF i == head_pos_x2 && j == head_pos_y2
			Get2dArr canvas, i, j, al
			.IF al == '.'
				inc length2
				.WHILE 1
					INVOKE rand
					mov p, eax
					.IF canvas[p] == ' '
						mov canvas[p], '.'
						.BREAK
					.ENDIF
				.ENDW
			.ENDIF
			.IF al == '@'
				INVOKE GameClean, hwnd
				.IF length1 > length2
					INVOKE MessageBox, 0, offset player1wintxt,
							gameovertxt, 0
				.ELSEIF length1 < length2
					INVOKE MessageBox, 0, offset player1wintxt,
							gameovertxt, 0
				.ELSE
					INVOKE MessageBox, 0, offset drawtxt,
							gameovertxt, 0
				.ENDIF
				INVOKE ExitProcess, 0
			.ENDIF
			Mov2dArr canvas, i, j, '`'
		.ENDIF
		Get2dArr canvas, i, j, al
		.IF al <= 'Z' && al >= '@'
			inc al
			sub al, '@'
			.IF al > length1
				Mov2dArr canvas, i, j, ' '
			.ENDIF
		.ENDIF
		Get2dArr canvas, i, j, al
		.IF al <= 'z' && al >= '`'
			inc al
			sub al, '`'
			.IF al > length2
				Mov2dArr canvas, i, j, ' '
			.ENDIF
		.ENDIF
		inc j
	.ENDW
	inc i
.ENDW

INVOKE win, length1
.IF eax
	INVOKE GameClean, hwnd
	INVOKE MessageBox, 0, offset player1wintxt,
			gameovertxt, 0
	INVOKE ExitProcess, 0
.ENDIF
INVOKE win, length2
.IF eax
	INVOKE GameClean, hwnd
	INVOKE MessageBox, 0, offset player2wintxt,
			gameovertxt, 0
	INVOKE ExitProcess, 0
.ENDIF

SnakeCreep ENDP

GameClean PROC hwnd :HWND
    INVOKE KillTimer, hwnd, 1
    INVOKE DeleteObject, g_hsnake1Bitmap
    INVOKE DeleteObject, g_hfoodBitmap
    INVOKE DeleteDC, g_mdc
    INVOKE DeleteDC, g_bufdc
GameClean ENDP

;----------------------------------------------------------
GamePaint PROC,
	hwnd :HWND
; I dont know what it really does. I try to make it work.
;----------------------------------------------------------
LOCAL bmp	:HBITMAP
LOCAL i		:DWORD
LOCAL j 	:DWORD
LOCAL widthDivN	:DWORD
LOCAL loopN		:DWORD

	;INVOKE crt_printf, offset canvas

	INVOKE myGetDC, hwnd
	mov g_hdc, eax

	INVOKE myCreateCompatibleBitmap, g_hdc, w_WIDTH, w_WIDTH
	mov bmp, eax
	
	INVOKE mySelectObject, g_mdc, bmp
	
	xor esi, esi
	xor edi, edi

	mov i, 0
	mov j, 0

	; calc width / N
	mov eax, w_WIDTH
	div BYTE PTR w_N
	movzx ebx, al
	mov widthDivN, ebx

	;-------------------------------------------
	; I havent checked this WHILE block 
	; I just solved some errors like "A2026 constant expected"
	;
	.WHILE i < 80
		mov j, 0
        .WHILE j < 80
            mov edi, i
            mov esi, j

			mov eax, w_N
			mul edi
			add eax, esi
			mov cl, [canvas + eax]
            
            .IF cl == 46
                pushad
                INVOKE mySelectObject, g_bufdc, g_hfoodBitmap
				;--------------------------------------
				; calculate (WIDTH)/N*i and (WIDTH)/N*j
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
				;--------------------------------------
                INVOKE myBitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad
            .ELSEIF cl == 42
                pushad
                INVOKE mySelectObject, g_bufdc, g_hwallBitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE myBitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
				popad
            .ELSEIF cl >= 41h && cl <= 90
                pushad
                INVOKE mySelectObject, g_bufdc, g_hsnake1Bitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE myBitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad              
            .ELSEIF cl >= 61h && cl <= 122
                pushad
                INVOKE mySelectObject, g_bufdc, g_hsnake2Bitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE myBitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad
            .ENDIF
			inc j
        .ENDW
		inc i
    .ENDW
	;
	;------------------------------------------

	INVOKE myBitBlt, g_hdc, 0, 0, w_WIDTH, w_WIDTH, g_mdc, 0, 0, SRCCOPY
    INVOKE myReleaseDC, hwnd, g_hdc
	RET
GamePaint ENDP

;----------------------------------------------------------
GameInit PROC,
	hwnd :HWND
; I dont know what it really does. I just try to make it work.
;----------------------------------------------------------
LOCAL i		:DWORD
LOCAL j		:DWORD
local p 	:DWORD
local row 	:DWORD
local col 	:DWORD
LOCAL widthDivN	:DWORD

	mov i, 0
	.WHILE i < 80
		mov j, 0
        .WHILE j < 80
			pushad
			Mov2dArr canvas, i, j, ' '
            .IF i == 0 || i == 79 || j == 0 || j == 79
                mov bl, 42
				Mov2dArr canvas, i, j, '*'
            .ENDIF
			popad
			inc j
        .ENDW
		inc i
    .ENDW

	INVOKE debug_canvas, addr canvas


	pushad
	; set initial directions and positions
	mov dtmp1, 1
	Mov2dArr canvas, head_pos_x1, head_pos_y1, 'A'
	Mov2dArr canvas, head_pos_x2, head_pos_y2, 'a'

	.WHILE 1
        mov p, 0

		mov eax, w_N
		mul w_N
		mov ebx, eax	; N^2 in ebx

        INVOKE randomNumber

		;pushad
		;INVOKE crt_printf, ADDR debug_num, eax
		;popad

		mov edx, 0
        div ebx
        mov p, edx
        
        mov row, 0
        mov col, 0

        mov ax, WORD PTR p
		mov bl, BYTE PTR w_N
        div bl
        mov BYTE PTR row, al
        mov BYTE PTR col, ah

		

		Get2dArr canvas, row, col, al
		
        .IF al == ' '
			Mov2dArr canvas, row, col, '.'
            .BREAK
        .ENDIF
    .ENDW
	
	; g_hdc = myGetDC(hwnd);
	INVOKE myGetDC, hwnd
	mov g_hdc, eax
	
	; calc width / N 
	mov eax, w_WIDTH
	div BYTE PTR w_N
	movzx ebx, al
	mov widthDivN, ebx

	popad
	; g_hfoodBitmap
	INVOKE myloadFood
	mov g_hfoodBitmap, HBITMAP ptr eax

	; g_hsnake1Bitmap
	INVOKE myloadSnake1
	mov g_hsnake1Bitmap,HBITMAP ptr eax

	INVOKE myloadSnake2
	mov g_hsnake2Bitmap,HBITMAP ptr eax

	INVOKE myloadWall
	mov g_hwallBitmap,HBITMAP ptr eax

	INVOKE myCreateCompatibleDC@4, g_hdc
	mov g_mdc, eax
	INVOKE myCreateCompatibleDC@4, g_hdc
	mov g_bufdc, eax
	INVOKE myReleaseDC, hwnd, g_hdc

	mov eax, 1000
	mov ebx, FPS
	div ebx
	INVOKE SetTimer, hwnd, 1, eax, 0

	INVOKE GamePaint, hwnd

	RET
GameInit ENDP


END WinMain