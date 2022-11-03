/*
    debug only: ascii table
          2 3 4 5 6 7       30 40 50 60 70 80 90 100 110 120
        -------------      ---------------------------------
       0:   0 @ P ` p     0:    (  2  <  F  P  Z  d   n   x
       1: ! 1 A Q a q     1:    )  3  =  G  Q  [  e   o   y
       2: " 2 B R b r     2:    *  4  >  H  R  \  f   p   z
       3: # 3 C S c s     3: !  +  5  ?  I  S  ]  g   q   {
       4: $ 4 D T d t     4: "  ,  6  @  J  T  ^  h   r   |
       5: % 5 E U e u     5: #  -  7  A  K  U  _  i   s   }
       6: & 6 F V f v     6: $  .  8  B  L  V  `  j   t   ~
       7: ' 7 G W g w     7: %  /  9  C  M  W  a  k   u  DEL
       8: ( 8 H X h x     8: &  0  :  D  N  X  b  l   v
       9: ) 9 I Y i y     9: '  1  ;  E  O  Y  c  m   w
       A: * : J Z j z
       B: + ; K [ k {
       C: , < L \ l |
       D: - = M ] m }
       E: . > N ^ n ~
       F: / ? O _ o DEL

    从 A 到 Z：蛇1
        A 蛇的头
        B 蛇身上的第二节 以此类推
    . 食物
    ' ' 空地
    * 墙

    地图更新的策略：给表中所有字符+1，这样蛇的每个节都会变成下一节。蛇头蛇尾要特殊处理。

*/
#ifndef UNICODE
#define UNICODE
#endif

#include <stdio.h>
#include <conio.h>
#include <Windows.h>
#include <time.h>
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "Gdi32.lib")
#pragma comment(lib, "WS2_32.lib")
#pragma comment(lib, "Shell32.lib")
#include <stdlib.h>
#define N 80
#define WIDTH 800
//#define HEIGHT 1000

int FPS = 4;

char canvas[N][N];

//=================================SERVER==========================================

WSAData wasData;

// receive
SOCKET recvSocket;
SOCKADDR_IN myAddr;

u_short LISTENPORT;
u_short RECEIVERPORT;
char RECEIVERADDR[32] = {0};

// send
SOCKET sendSocket;

void initWSA(WSAData wasData)
{
    WSAStartup(MAKEWORD(2, 2), &wasData);
}

int init_recvSocket(unsigned short port)
{
    int iResult;

    // create receive socket
    recvSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (recvSocket == SOCKET_ERROR)
        goto recv_init_err;

    // bind receive socket
    myAddr.sin_family = AF_INET;
    myAddr.sin_port = htons(port);
    myAddr.sin_addr.S_un.S_addr = htonl(INADDR_ANY);

    // timeout
    int iTimeout = 1000 / FPS - 10; // 200ms

    if (setsockopt(recvSocket, SOL_SOCKET, SO_RCVTIMEO, (char *)&iTimeout, sizeof(int)) < 0)
    {
        printf("socket option  SO_RCVTIMEO not support\n");
        return -1;
    }

    iResult = bind(recvSocket, (SOCKADDR *)&myAddr, sizeof(myAddr));
    if (0 != iResult)
    {
        int errnoo = WSAGetLastError();
        goto recv_init_err;
    }

    return recvSocket;

recv_init_err:
    printf("recvSocketErr!\n");
    return -1;
}

int init_sendSocket()
{
    int iResult;

    sendSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (SOCKET_ERROR == sendSocket)
    {
        printf("Create Socket Error!");
        goto send_init_err;
    }

    return 0;

send_init_err:
    printf("sendSocketErr!\n");

    return -1;
}

//=================================================================================================

/**
 *  g_hdc ---
 *
 */

HDC g_hdc = NULL, g_mdc = NULL, g_bufdc = NULL;
HBITMAP g_hfoodBitmap = NULL, g_hsnake1Bitmap = NULL, g_hsnake2Bitmap = NULL, g_hwallBitmap = NULL;
void game_paint(HWND hwnd);
void game_clean(HWND hwnd);

HANDLE g_hOutput;
void game_init(HWND hwnd)
{
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            canvas[i][j] = ' ';
            if (i == 0 || i == N - 1 || j == 0 || j == N - 1)
                canvas[i][j] = '*';
        }
    }

    g_hdc = GetDC(hwnd);
    g_hfoodBitmap = (HBITMAP)LoadImage(NULL, L"food.bmp", IMAGE_BITMAP, (WIDTH) / N, (WIDTH) / N, LR_LOADFROMFILE);
    g_hsnake1Bitmap = (HBITMAP)LoadImage(NULL, L"snake1.bmp", IMAGE_BITMAP, (WIDTH) / N, (WIDTH) / N, LR_LOADFROMFILE);
    g_hsnake2Bitmap = (HBITMAP)LoadImage(NULL, L"snake2.bmp", IMAGE_BITMAP, (WIDTH) / N, (WIDTH) / N, LR_LOADFROMFILE);
    g_hwallBitmap = (HBITMAP)LoadImage(NULL, L"wall.bmp", IMAGE_BITMAP, (WIDTH) / N, (WIDTH) / N, LR_LOADFROMFILE);
    g_mdc = CreateCompatibleDC(g_hdc);
    g_bufdc = CreateCompatibleDC(g_hdc);
    ReleaseDC(hwnd, g_hdc);

    SetTimer(hwnd, 1, 1000 / FPS, (TIMERPROC)NULL);

    game_paint(hwnd);
}

void game_paint(HWND hwnd)
{
    g_hdc = GetDC(hwnd);
    HBITMAP bmp = CreateCompatibleBitmap(g_hdc, WIDTH, WIDTH);
    SelectObject(g_mdc, bmp);

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            if (canvas[i][j] == '.')
            {
                SelectObject(g_bufdc, g_hfoodBitmap);
                BitBlt(g_mdc, (WIDTH) / N * j, (WIDTH) / N * i, (WIDTH) / N, (WIDTH) / N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if (canvas[i][j] == '*')
            {
                SelectObject(g_bufdc, g_hwallBitmap);
                BitBlt(g_mdc, (WIDTH) / N * j, (WIDTH) / N * i, (WIDTH) / N, (WIDTH) / N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if (canvas[i][j] >= 'A' && canvas[i][j] <= 'Z')
            {
                SelectObject(g_bufdc, g_hsnake1Bitmap);
                BitBlt(g_mdc, (WIDTH) / N * j, (WIDTH) / N * i, (WIDTH) / N, (WIDTH) / N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if (canvas[i][j] >= 'a' && canvas[i][j] <= 'z')
            {
                SelectObject(g_bufdc, g_hsnake2Bitmap);
                BitBlt(g_mdc, (WIDTH) / N * j, (WIDTH) / N * i, (WIDTH) / N, (WIDTH) / N, g_bufdc, 0, 0, SRCCOPY);
            }
        }
    }
    BitBlt(g_hdc, 0, 0, WIDTH, WIDTH, g_mdc, 0, 0, SRCCOPY);
    ReleaseDC(hwnd, g_hdc);
}

void game_clean(HWND hwnd)
{
    KillTimer(hwnd, 1);
    DeleteObject(g_hsnake1Bitmap);
    DeleteObject(g_hfoodBitmap);
    DeleteDC(g_mdc);
    DeleteDC(g_bufdc);
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

void send_operation(int player, int direction)
{
    SOCKADDR_IN receiverAddr;
    int iRes;
    char sendBuf[32] = {0};
    int sendBufLength = sizeof(sendBuf);

    memset(sendBuf, 0, sizeof(sendBuf));
    memset(&receiverAddr, 0, sizeof(receiverAddr));

    receiverAddr.sin_port = htons(RECEIVERPORT);
    receiverAddr.sin_family = AF_INET;
    receiverAddr.sin_addr.S_un.S_addr = inet_addr(RECEIVERADDR);

    sprintf(sendBuf, "%d_0_%d_%d\0", LISTENPORT, player, direction);
    printf("send info:%s\n", sendBuf);

    iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&receiverAddr, sizeof(receiverAddr));
    if (iRes == 0)
    {
        printf("fail to send\n");
    }
}

void get_canvas()
{
    SOCKADDR_IN receiverAddr;
    int iRes;
    char sendBuf[32] = {0};
    int sendBufLength = sizeof(sendBuf);
    char recvBuf[7000] = {0};
    int recvBufLength = sizeof(recvBuf);

    memset(sendBuf, 0, sizeof(sendBuf));
    memset(&receiverAddr, 0, sizeof(receiverAddr));

    receiverAddr.sin_port = htons(RECEIVERPORT);
    receiverAddr.sin_family = AF_INET;
    receiverAddr.sin_addr.S_un.S_addr = inet_addr(RECEIVERADDR);

    sprintf(sendBuf, "%d_1\0", LISTENPORT);
    printf("send info:%s\n", sendBuf);

    iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&receiverAddr, sizeof(receiverAddr));
    if (iRes == 0)
    {
        printf("fail to send\n");
    }

    iRes = recvfrom(recvSocket, recvBuf, recvBufLength, 0, 0, 0);
    printf("iRes:%d\n", iRes);
    if (iRes > 0)
    {
        memset(canvas, 0, sizeof(canvas));
        memcpy(canvas, recvBuf, sizeof(canvas));
        for (int i = 0; i < 80; i++)
        {
            for (int j = 0; j < 80; j++)
            {
                printf("%c", recvBuf[80 * i + j]);
            }
            printf("\n");
        }
    }
}

/* char *ConvertLPWSTRToLPSTR(LPWSTR lpwszStrIn)
{
    LPSTR pszOut = NULL;
    if (lpwszStrIn != NULL)
    {
        int nInputStrLen = wcslen(lpwszStrIn);

        // Double NULL Termination
        int nOutputStrLen = WideCharToMultiByte(CP_ACP, 0, lpwszStrIn, nInputStrLen, NULL, 0, 0, 0) + 2;
        pszOut = new char[nOutputStrLen];

        if (pszOut)
        {
            memset(pszOut, 0x00, nOutputStrLen);
            WideCharToMultiByte(CP_ACP, 0, lpwszStrIn, nInputStrLen, pszOut, nOutputStrLen, 0, 0);
        }
    }
    return pszOut;
} */

BOOL addConsole(HWND hWnd)
{
    HANDLE hStdin;
    DWORD mode;

    if (AllocConsole() == 0)
    {
        MessageBox(hWnd, L"AllocConsole failed!", NULL, MB_OK);
        return false;
    }
    hStdin = GetStdHandle(STD_INPUT_HANDLE);
    GetConsoleMode(hStdin, &mode);
    mode &= ~ENABLE_QUICK_EDIT_MODE;
    mode &= ~ENABLE_INSERT_MODE;
    mode &= ~ENABLE_MOUSE_INPUT;
    SetConsoleMode(hStdin, mode);

    if (freopen("conout$", "w", stdout) == NULL)
    {
        MessageBox(hWnd, L"freopen stdout failed!", NULL, MB_OK);
        return false;
    }
    if (freopen("conin$", "r", stdin) == NULL)
    {
        MessageBox(hWnd, L"freopen stdin failed!", NULL, MB_OK);
        return false;
    }
    if (freopen("conerr$", "w", stderr) == NULL)
    {
        MessageBox(hWnd, L"freopen stderr failed!", NULL, MB_OK);
        return false;
    }

    printf("success adding console\n");
    return true;
}

void ready_for_start()
{
    SOCKADDR_IN receiverAddr;
    int iRes;
    char sendBuf[32] = {0};
    int sendBufLength = sizeof(sendBuf);
    char recvBuf[7000] = {0};
    int recvBufLength = sizeof(recvBuf);

    memset(sendBuf, 0, sizeof(sendBuf));
    memset(&receiverAddr, 0, sizeof(receiverAddr));

    receiverAddr.sin_port = htons(RECEIVERPORT);
    receiverAddr.sin_family = AF_INET;
    receiverAddr.sin_addr.S_un.S_addr = inet_addr(RECEIVERADDR);

    sprintf(sendBuf, "%d_2\0", LISTENPORT);
    printf("send info:%s\n", sendBuf);

    iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&receiverAddr, sizeof(receiverAddr));
    if (iRes == 0)
    {
        printf("fail to send\n");
    }
    iRes = recvfrom(recvSocket, recvBuf, recvBufLength, 0, 0, 0);
    if (iRes > 0)
    {
        printf("recv:%s\n", recvBuf);
    }
    return;
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR pCmdLine, int nCmdShow)
{

    // console_init();
    //  Register the window class.
    const wchar_t CLASS_NAME[] = L"Sample Window Class";

    WNDCLASS wc = {};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
        0,                   // Optional window styles.
        CLASS_NAME,          // Window class
        L"Greedy Snake",     // Window text
        WS_OVERLAPPEDWINDOW, // Window style

        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, WIDTH + 15, WIDTH + 40,

        NULL,      // Parent window
        NULL,      // Menu
        hInstance, // Instance handle
        NULL       // Additional application data
    );

    if (hwnd == NULL)
    {
        return 0;
    }

    addConsole(hwnd);

    // handle args
    int argc = 0;
    LPWSTR *lpszArgv = NULL;
    lpszArgv = CommandLineToArgvW(pCmdLine, &argc);
    if (argc == 3)
    {
        char opt1[32] = {0};
        char opt2[32] = {0};
        char opt3[32] = {0};
        WideCharToMultiByte(CP_OEMCP, NULL, lpszArgv[0], -1, opt1, wcslen(lpszArgv[0]), NULL, FALSE);
        WideCharToMultiByte(CP_OEMCP, NULL, lpszArgv[1], -1, opt2, wcslen(lpszArgv[1]), NULL, FALSE);
        WideCharToMultiByte(CP_OEMCP, NULL, lpszArgv[2], -1, opt3, wcslen(lpszArgv[2]), NULL, FALSE);

        printf("opt1:%s\n", opt1);
        printf("opt2:%s\n", opt2);
        printf("opt3:%s\n", opt3);

        memcpy(RECEIVERADDR, opt1, sizeof(RECEIVERADDR));
        RECEIVERPORT = atoi(opt2);
        LISTENPORT = atoi(opt3);

        printf("%s\n", RECEIVERADDR);
        printf("%d\n", RECEIVERPORT);
        printf("%d\n", LISTENPORT);
    }
    else
    {
        printf("usage: xxx server_ip server_port listen_port\n");
        system("pause");
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);

    game_init(hwnd);

    initWSA(wasData);
    init_recvSocket(LISTENPORT);
    init_sendSocket();

    // ready_for_start();

    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    switch (uMsg)
    {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        g_hdc = BeginPaint(hwnd, &ps);
        game_paint(hwnd);
        EndPaint(hwnd, &ps);
        ValidateRect(hwnd, NULL);
        return 0;
    }
    case WM_CHAR:
    {
        switch (wParam)
        {
        case 'W':
        case 'w':
            send_operation(1, 0);
            break;
        case 'S':
        case 's':
            send_operation(1, 1);
            break;
        case 'A':
        case 'a':
            send_operation(1, 2);
            break;
        case 'D':
        case 'd':
            send_operation(1, 3);
            break;
        case 'I':
        case 'i':
            send_operation(2, 0);
            break;
        case 'K':
        case 'k':
            send_operation(2, 1);
            break;
        case 'J':
        case 'j':
            send_operation(2, 2);
            break;
        case 'L':
        case 'l':
            send_operation(2, 3);
            break;
        default:
            break;
        }
        game_paint(hwnd);
        return 0;
    }
    case WM_TIMER:
    {
        get_canvas();
        game_paint(hwnd);
        return 0;
    }
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}