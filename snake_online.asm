TITLE Greedy Snake                   (snake.asm)
; Runnable version of Greedy Snake

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
include 		wsock32.inc
includelib		wsock32.lib
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
GamePaint 	PROTO :HWND
GameInit	PROTO :HWND
GameClean   PROTO :HWND
win 		PROTO :DWORD
lose 		PROTO :DWORD, :DWORD
InitRecvSocket		PROTO :WORD
InitSendSocket		PROTO
SendOperation		PROTO :DWORD, :DWORD
GetCanvas			PROTO
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

ErrorTitle  BYTE "Error",0
WindowName  BYTE "Greedy Snake",0
className   BYTE "GSnake",0
debug_num BYTE "%d", 10, 13, 0
message1 BYTE "im alive", 10, 13, 0
player2wintxt db "Player2 win!", 0
player1wintxt db "Player1 win!", 0
drawtxt db "Draw!", 0
gameovertxt db "Game over", 0

;------------------------------------------------------------
; Some Names
foodAssetPath		BYTE "food.bmp", 0
snake1AssetPath		BYTE "snake1.bmp", 0
snake2AssetPath		BYTE "snake2.bmp", 0
wallAssetPath		BYTE "wall.bmp", 0

;------------------------------------------------------------
; Game Config&State Global Vars
w_WIDTH				DWORD 800
w_N					DWORD 80
FPS 				DWORD 5
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
init_foodnum		DWORD 8

;------------------------------------------------------------
; for test
testmsg				BYTE "test", 10, 13, 0
keyboardMsgFmt		BYTE "You have entered %c", 10, 13, 0
charmsg             BYTE "%c ", 0
intmsg             	BYTE "%d ", 0
strmsg				BYTE "%s ", 0
endl                BYTE 10, 13, 0

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
; Server Vars
wsaData				WSADATA <>
recvSocket			SOCKET	0
sendSocket			SOCKET  0
myAddr				sockaddr_in	<>
iTimeout			DWORD 0
LISTENPORT			WORD 0
LISTENPORTDWORD		DWORD 0
RECEIVERPORT		WORD 0
RECEIVERADDR		BYTE 32 DUP(0), 0

sendBuf				BYTE 320 DUP(0), 0
sendBufLength		DWORD 320
recvBuf				BYTE 7000 DUP(0), 0
recvBufLength		DWORD 7000

;send_operation
sendMessage			BYTE "%d_0_%d_%d", 0
sendGetCanvas		BYTE "%d_1", 0
pl					DWORD 0
dir					DWORD 0

msg	      MSGStruct <>
winRect   RECT <>
hMainWnd  DWORD ?
hInstance DWORD ?

;-------------------------------------------------------------
; WinMain Vars
usageMessage		BYTE "usage: snake_online.exe server_ip server_port listen_port", 10, 13, 0
pauseMessage		BYTE "pause", 0
scanFormat			BYTE "%s %s %s", 0
opt1				BYTE 32 DUP(0), 0
opt2				BYTE 32 DUP(0), 0
opt3				BYTE 32 DUP(0), 0


; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

;=================== CODE =========================
.code
WinMain PROC
	LOCAL argc	:DWORD
	LOCAL lpszArgv	:LPWSTR

; Get args
	INVOKE crt_scanf, ADDR scanFormat, ADDR opt1, ADDR opt2, ADDR opt3
	;INVOKE crt_printf, ADDR scanFormat, ADDR opt1, ADDR opt2, ADDR opt3
	INVOKE crt_memcpy, ADDR RECEIVERADDR, ADDR opt1, 32
	INVOKE crt_atoi, ADDR opt2
	MOV RECEIVERPORT, ax
	INVOKE crt_atoi, ADDR opt3
	MOV LISTENPORT, ax


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

; Init the game
	INVOKE GameInit, hMainWnd

	INVOKE WSAStartup, 0202h, ADDR wsaData
	INVOKE InitRecvSocket, LISTENPORT
	INVOKE InitSendSocket

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

	.IF eax == WM_PAINT			; paint?
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
		.IF (wParam == 'w' || wParam == 'W')
			MOV pl, 1
			MOV dir, 0
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'a' || wParam == 'A')
			MOV pl, 1
			MOV dir, 2
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 's' || wParam == 'S')
			MOV pl, 1
			MOV dir, 1
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'd' || wParam == 'D')
			MOV pl, 1
			MOV dir, 3
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'i' || wParam == 'I')
			MOV pl, 2
			MOV dir, 0
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'j' || wParam == 'J')
			MOV pl, 2
			MOV dir, 2
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'k' || wParam == 'K')
			MOV pl, 2
			MOV dir, 1
			INVOKE SendOperation, pl, dir
		.ELSEIF (wParam == 'l' || wParam == 'L')
			MOV pl, 2
			MOV dir, 3
			INVOKE SendOperation, pl, dir
		.ENDIF
		INVOKE GamePaint, hWnd
		jmp WinProcExit
	.ELSEIF eax == WM_TIMER
		INVOKE GetCanvas
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

;---------------------------------------------------
InitRecvSocket PROC,
	port:WORD
;---------------------------------------------------
	LOCAL iRes	:DWORD

	INVOKE socket, AF_INET, SOCK_DGRAM, IPPROTO_UDP
	MOV recvSocket, eax
	.IF recvSocket == SOCKET_ERROR
		jmp init_recv_err
	.ENDIF

	MOV myAddr.sin_family, AF_INET

	;myAddr.sin_port = htons(port)
	INVOKE htons, port
	MOV myAddr.sin_port, ax

    ;myAddr.sin_addr.S_un.S_addr = htonl(INADDR_ANY)
	INVOKE htonl, INADDR_ANY
	MOV myAddr.sin_addr.S_un.S_addr, eax

	MOV eax, 1000
	MOV edx, 0
	DIV FPS
	SUB eax, 10
	MOV iTimeout, eax

	;setsockopt(recvSocket, SOL_SOCKET, SO_RCVTIMEO, (char *)&iTimeout, sizeof(int))
	INVOKE setsockopt, recvSocket, SOL_SOCKET, SO_RCVTIMEO, ADDR iTimeout, 4
	MOV iRes, eax

	;iResult = bind(recvSocket, (SOCKADDR *)&myAddr, sizeof(myAddr));
	INVOKE bind, recvSocket, ADDR myAddr, 16
	MOV iRes, eax

init_recv_err:

	RET
InitRecvSocket ENDP	

;------------------------------------------------
InitSendSocket PROC
;------------------------------------------------
	LOCAL iRes	:DWORD

	INVOKE socket, AF_INET, SOCK_DGRAM, IPPROTO_UDP
	MOV sendSocket, eax
	;INVOKE crt_printf, ADDR intmsg, sendSocket

send_init_err:

	RET
InitSendSocket ENDP

;------------------------------------------------
SendOperation PROC,
	player:DWORD, direction:DWORD
;------------------------------------------------
	LOCAL receiverAddr	:sockaddr_in
	LOCAL iRes			:DWORD
	
	INVOKE crt_memset, ADDR sendBuf, 0, 320
	INVOKE crt_memset, ADDR receiverAddr, 0, 16

	;receiverAddr.sin_port = htons(RECEIVERPORT);
    ;receiverAddr.sin_family = AF_INET;
    ;receiverAddr.sin_addr.S_un.S_addr = inet_addr(RECEIVERADDR);

	INVOKE htons, RECEIVERPORT
	MOV receiverAddr.sin_port, ax
	MOV receiverAddr.sin_family, AF_INET
	INVOKE inet_addr, ADDR RECEIVERADDR
	MOV receiverAddr.sin_addr.S_un.S_addr, eax

	xchg eax, ebx
	xchg ebx, eax

	INVOKE crt_printf, ADDR intmsg, pl
	INVOKE crt_printf, ADDR intmsg, dir

	push eax
	xor eax, eax
	mov ax, LISTENPORT
	mov LISTENPORTDWORD, eax
	pop eax

	INVOKE crt_sprintf, ADDR sendBuf, ADDR sendMessage, LISTENPORTDWORD, pl, dir
	INVOKE crt_printf, ADDR strmsg, ADDR sendBuf

	xchg eax, ebx
	xchg ebx, eax

	INVOKE sendto, sendSocket, ADDR sendBuf, sendBufLength, 0, ADDR receiverAddr, 16

	RET
SendOperation ENDP

;------------------------------------------------
GetCanvas PROC
;------------------------------------------------
	LOCAL receiverAddr	:sockaddr_in
	LOCAL iRes			:DWORD

	INVOKE crt_memset, ADDR sendBuf, 0, 320
	INVOKE crt_memset, ADDR recvBuf, 0, 7000
	INVOKE crt_memset, ADDR receiverAddr, 0, 16

	INVOKE htons, RECEIVERPORT
	MOV receiverAddr.sin_port, ax
	MOV receiverAddr.sin_family, AF_INET
	INVOKE inet_addr, ADDR RECEIVERADDR
	MOV receiverAddr.sin_addr.S_un.S_addr, eax

	
	INVOKE crt_sprintf, ADDR sendBuf, ADDR sendGetCanvas, LISTENPORT

	INVOKE sendto, sendSocket, ADDR sendBuf, sendBufLength, 0, ADDR receiverAddr, 16
	;INVOKE WSAGetLastError
	;MOV iRes, eax
	;INVOKE crt_printf, ADDR intmsg, iRes

	INVOKE recvfrom, recvSocket, ADDR recvBuf, recvBufLength, 0, 0, 0
	MOV iRes, eax
	.IF iRes > 0
		INVOKE crt_memset, ADDR canvas, 0, 6400
		INVOKE crt_memcpy, ADDR canvas, ADDR recvBuf, 6400
	.ENDIF
	RET
GetCanvas ENDP


lose PROC x :DWORD, y :DWORD
	mov edx, w_N
	.IF (x >= edx) || (y >= edx) || (x < 0) || (y < 0)
		mov eax, 1
		ret
	.ENDIF
	Get2dArr canvas, x, y, al
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

PAINT1 PROC
	LOCAL i:DWORD
	LOCAL j:DWORD
	mov i, 0
	.WHILE i < 80
		mov j, 0
		.WHILE j < 80
			Get2dArr canvas, i, j, al
			INVOKE crt_printf, offset charmsg, al
			inc j
		.ENDW
		INVOKE crt_printf, offset endl
		inc i
	.ENDW
ret
PAINT1 ENDP


GameClean PROC hwnd :HWND
    INVOKE KillTimer, hwnd, 1
    INVOKE DeleteObject, g_hsnake1Bitmap
    INVOKE DeleteObject, g_hfoodBitmap
    INVOKE DeleteDC, g_mdc
    INVOKE DeleteDC, g_bufdc
	ret
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

	INVOKE GetDC, hwnd
	mov g_hdc, eax

	INVOKE CreateCompatibleBitmap, g_hdc, w_WIDTH, w_WIDTH
	mov bmp, eax
	
	INVOKE SelectObject, g_mdc, bmp
	
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
                INVOKE SelectObject, g_bufdc, g_hfoodBitmap
				;--------------------------------------
				; calculate (WIDTH)/N*i and (WIDTH)/N*j
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
				;--------------------------------------
                INVOKE BitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad
            .ELSEIF cl == 42
                pushad
                INVOKE SelectObject, g_bufdc, g_hwallBitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE BitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
				popad
            .ELSEIF cl >= 41h && cl <= 90
                pushad
                INVOKE SelectObject, g_bufdc, g_hsnake1Bitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE BitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad              
            .ELSEIF cl >= 61h && cl <= 122
                pushad
                INVOKE SelectObject, g_bufdc, g_hsnake2Bitmap
				mov eax, widthDivN
				mul i
				mov ebx, eax 	; (WIDTH)/N*i
				mov eax, widthDivN
				mul j			; (WIDTH)/N*j
                INVOKE BitBlt, g_mdc, eax, ebx, widthDivN, widthDivN, g_bufdc, 0, 0, SRCCOPY
                popad
            .ENDIF
			inc j
        .ENDW
		inc i
    .ENDW
	;
	;------------------------------------------

	INVOKE BitBlt, g_hdc, 0, 0, w_WIDTH, w_WIDTH, g_mdc, 0, 0, SRCCOPY
    INVOKE ReleaseDC, hwnd, g_hdc
	RET
GamePaint ENDP

;----------------------------------------------------------
GameInit PROC,
	hwnd :HWND
; I dont know what it really does. I just try to make it work.
;----------------------------------------------------------
LOCAL i			:DWORD
LOCAL j			:DWORD
local p 		:DWORD
local row 		:DWORD
local col 		:DWORD
LOCAL widthDivN	:DWORD
local food		:DWORD

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

	; GetDC
	INVOKE GetDC, hwnd
	mov g_hdc, eax
	
	; g_hfoodBitmap
	INVOKE LoadImage, NULL, ADDR foodAssetPath, IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE
	mov g_hfoodBitmap, HBITMAP ptr eax

	; g_hsnake1Bitmap
	INVOKE LoadImage, NULL, ADDR snake1AssetPath, IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE
	mov g_hsnake1Bitmap,HBITMAP ptr eax

	INVOKE LoadImage, NULL, ADDR snake2AssetPath, IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE
	mov g_hsnake2Bitmap,HBITMAP ptr eax

	INVOKE LoadImage, NULL, ADDR wallAssetPath, IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE
	mov g_hwallBitmap,HBITMAP ptr eax

	INVOKE CreateCompatibleDC, g_hdc
	mov g_mdc, eax
	INVOKE CreateCompatibleDC, g_hdc
	mov g_bufdc, eax
	INVOKE ReleaseDC, hwnd, g_hdc

	mov eax, 1000
	mov ebx, FPS
	div ebx
	INVOKE SetTimer, hwnd, 1, eax, 0

	INVOKE GamePaint, hwnd

	RET
GameInit ENDP


END WinMain