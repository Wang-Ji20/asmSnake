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
#pragma comment(lib,"user32.lib");
#pragma comment(lib, "Gdi32.lib")
#include <stdlib.h>
#define N 80
#define WIDTH 800
//#define HEIGHT 1000
#define INIT_FOODNUM 5
#define INIT_LENGTH 3
#define WINNING_LENGTH 20

int FPS = 15;

char canvas[N][N];
int head_pos_x1 = 1, head_pos_y1 = 1;
int head_pos_x2 = N - 2, head_pos_y2 = N - 2;
int length1 = INIT_LENGTH, length2 = INIT_LENGTH;
enum Direction{NORTH, SOUTH, WEST, EAST} direction1, direction2, dtmp1, dtmp2;

/**
 *  g_hdc --- 
 * 
 */

HDC g_hdc = NULL, g_mdc = NULL, g_bufdc = NULL;
HBITMAP g_hfoodBitmap = NULL, g_hsnake1Bitmap = NULL, g_hsnake2Bitmap = NULL, g_hwallBitmap = NULL;
void game_paint(HWND hwnd);
void game_clean(HWND hwnd);

bool lose(int x, int y){
    if (x >= N || y >= N || x < 0 || y < 0) return true;
    if (canvas[x][y] == '*' || canvas[x][y] >= '@') return true;
    return false;
}

bool win(int length){
    return (length >= WINNING_LENGTH);
}

void snake_creep(HWND hwnd){
    direction1 = dtmp1;
    direction2 = dtmp2;
    if (direction1 == NORTH)
    {
        head_pos_x1--;
    }
    else if (direction1 == SOUTH)
    {
        head_pos_x1++;
    }
    else if (direction1 == WEST)
    {
        head_pos_y1--;
    }
    else if (direction1 == EAST)
    {
        head_pos_y1++;
    }
    if (direction2 == NORTH)
    {
        head_pos_x2--;
    }
    else if (direction2 == SOUTH)
    {
        head_pos_x2++;
    }
    else if (direction2 == WEST)
    {
        head_pos_y2--;
    }
    else if (direction2 == EAST)
    {
        head_pos_y2++;
    }
    
    if (lose(head_pos_x1, head_pos_y1))
    {
        game_clean(hwnd);
        int msgboxID = MessageBox(
            NULL,
            (LPCWSTR)L"Player2 win!",
            (LPCWSTR)L"Game over",
            0
        );
        exit(0);
    }
    if (lose(head_pos_x2, head_pos_y2))
    {
        game_clean(hwnd);
        int msgboxID = MessageBox(
            NULL,
            (LPCWSTR)L"Player1 win!",
            (LPCWSTR)L"Game over",
            0
        );
        exit(0);
    }

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            if (i == head_pos_x1 && j == head_pos_y1)
            {
                if (canvas[i][j] == '.')
                {
                    length1++;
                    while(1)
                    {
                        int p = rand() % (N*N);
                        if (canvas[p / N][p % N] == ' ')
                        {
                            canvas[p / N][p % N] = '.';
                            break;
                        }
                    }
                }
                canvas[i][j] = '@';
            }
            if (i == head_pos_x2 && j == head_pos_y2)
            {
                if (canvas[i][j] == '.')
                {
                    length2++;
                    while(1)
                    {
                        int p = rand() % (N*N);
                        if (canvas[p / N][p % N] == ' ')
                        {
                            canvas[p / N][p % N] = '.';
                            break;
                        }
                    }
                }
                if (canvas[i][j] == '@')
                {
                    game_clean(hwnd);
                    if (length1 > length2)
                    {
                        int msgboxID = MessageBox(
                            NULL,
                            (LPCWSTR)L"Player1 win!",
                            (LPCWSTR)L"Game over",
                            0
                        );
                    }
                    else if (length1 < length2)
                    {
                        int msgboxID = MessageBox(
                            NULL,
                            (LPCWSTR)L"Player2 win!",
                            (LPCWSTR)L"Game over",
                            0
                        );
                    }
                    else
                    {
                        int msgboxID = MessageBox(
                            NULL,
                            (LPCWSTR)L"Draw!",
                            (LPCWSTR)L"Game over",
                            0
                        );
                    }
                    exit(0);
                }
                canvas[i][j] = '`';
            }
            
            if (canvas[i][j] <= 'Z' && canvas[i][j] >= '@')
            {
                canvas[i][j] += 1; 
                if (canvas[i][j] - '@' > length1)
                    canvas[i][j] = ' ';
            }
            if (canvas[i][j] <= 'z' && canvas[i][j] >= '`')
            {
                canvas[i][j] += 1; 
                if (canvas[i][j] - '`' > length2)
                    canvas[i][j] = ' ';
            }
        }
    }

    if (win(length1))
    {
        game_clean(hwnd);
        int msgboxID = MessageBox(
            NULL,
            (LPCWSTR)L"Player1 win!",
            (LPCWSTR)L"Game over",
            0
        );
        exit(0);
    }
    if (win(length2))
    {
        game_clean(hwnd);
        int msgboxID = MessageBox(
            NULL,
            (LPCWSTR)L"Player2 win!",
            (LPCWSTR)L"Game over",
            0
        );
        exit(0);
    }

}

HANDLE g_hOutput;

// void console_init(void){
//     AllocConsole();
//     SetConsoleTitle(L"debug");
//     g_hOutput = GetStdHandle(STD_OUTPUT_HANDLE);
// }

void game_paint(HWND hwnd){
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
                BitBlt(g_mdc, (WIDTH)/N*j, (WIDTH)/N*i, (WIDTH)/N, (WIDTH)/N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if(canvas[i][j] == '*'){
                SelectObject(g_bufdc, g_hwallBitmap);
                BitBlt(g_mdc, (WIDTH)/N*j, (WIDTH)/N*i, (WIDTH)/N, (WIDTH)/N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if(canvas[i][j] >= 'A' && canvas[i][j] <= 'Z'){
                SelectObject(g_bufdc, g_hsnake1Bitmap);
                BitBlt(g_mdc, (WIDTH)/N*j, (WIDTH)/N*i, (WIDTH)/N, (WIDTH)/N, g_bufdc, 0, 0, SRCCOPY);
            }
            else if(canvas[i][j] >= 'a' && canvas[i][j] <= 'z'){
                SelectObject(g_bufdc, g_hsnake2Bitmap);
                BitBlt(g_mdc, (WIDTH)/N*j, (WIDTH)/N*i, (WIDTH)/N, (WIDTH)/N, g_bufdc, 0, 0, SRCCOPY);
            }
            //wchar_t tmp = canvas[i][j];
            //WriteConsole(g_hOutput, &tmp, 1, 0, 0);
        }
        //wchar_t tmp = '\n';
        //WriteConsole(g_hOutput, &tmp, 1, 0, 0);
    }
    //wchar_t tmp[10] = L"=========";
    //WriteConsole(g_hOutput, &tmp, 10, 0, 0);
    BitBlt(g_hdc, 0, 0, WIDTH, WIDTH, g_mdc, 0, 0, SRCCOPY);
    //MessageBox(hwnd, L"aa", L"aa", MB_OK);
    ReleaseDC(hwnd, g_hdc);
}

void game_init(HWND hwnd){
    
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            canvas[i][j] = ' ';
            if (i == 0 || i == N - 1 || j == 0 || j == N - 1) canvas[i][j] = '*';
        }
    }
    dtmp1 = SOUTH;
    canvas[head_pos_x1][head_pos_y1] = 'A';
    canvas[head_pos_x2][head_pos_y2] = 'a';
    srand(time(0));
    for (int i = 0; i < INIT_FOODNUM; i++)
    while(1)
    {
        int p = rand() % (N*N);
        if (canvas[p / N][p % N] == ' ')
        {
            canvas[p / N][p % N] = '.';
            break;
        }
    }
    g_hdc = GetDC(hwnd);
    g_hfoodBitmap = (HBITMAP) LoadImage(NULL, L"food.bmp", IMAGE_BITMAP, (WIDTH)/N, (WIDTH)/N, LR_LOADFROMFILE);
    g_hsnake1Bitmap = (HBITMAP) LoadImage(NULL, L"snake1.bmp", IMAGE_BITMAP, (WIDTH)/N, (WIDTH)/N, LR_LOADFROMFILE);
    g_hsnake2Bitmap = (HBITMAP) LoadImage(NULL, L"snake2.bmp", IMAGE_BITMAP, (WIDTH)/N, (WIDTH)/N, LR_LOADFROMFILE);
    g_hwallBitmap = (HBITMAP) LoadImage(NULL, L"wall.bmp", IMAGE_BITMAP, (WIDTH)/N, (WIDTH)/N, LR_LOADFROMFILE);
    g_mdc = CreateCompatibleDC(g_hdc);
    g_bufdc = CreateCompatibleDC(g_hdc);
    ReleaseDC(hwnd, g_hdc);
    
    SetTimer(hwnd, 1, 1000/FPS, (TIMERPROC) NULL);
    
    game_paint(hwnd);
}

void game_clean(HWND hwnd){
    KillTimer(hwnd, 1); 
    DeleteObject(g_hsnake1Bitmap);
    DeleteObject(g_hfoodBitmap);
    DeleteDC(g_mdc);
    DeleteDC(g_bufdc);
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR pCmdLine, int nCmdShow)
{

    //console_init();
    // Register the window class.
    const wchar_t CLASS_NAME[]  = L"Sample Window Class";
    
    WNDCLASS wc = { };

    wc.lpfnWndProc   = WindowProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;

    RegisterClass(&wc);

    // Create the window.

    HWND hwnd = CreateWindowEx(
        0,                              // Optional window styles.
        CLASS_NAME,                     // Window class
        L"Greedy Snake",    // Window text
        WS_OVERLAPPEDWINDOW,            // Window style

        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, WIDTH + 15, WIDTH + 40,

        NULL,       // Parent window    
        NULL,       // Menu
        hInstance,  // Instance handle
        NULL        // Additional application data
        );

    if (hwnd == NULL)
    {
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);

    game_init(hwnd);
    // Run the message loop.
    MSG msg = { };
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
                    if (direction1 == WEST || direction1 == EAST) dtmp1 = NORTH;
                    break;

                case 'S':
                case 's':
                    if (direction1 == WEST || direction1 == EAST) dtmp1 = SOUTH;
                    break;

                case 'A':
                case 'a':
                    if (direction1 == NORTH || direction1 == SOUTH) dtmp1 = WEST;
                    break;

                case 'D':
                case 'd':
                    if (direction1 == NORTH || direction1 == SOUTH) dtmp1 = EAST;
                    break;

                case 'I':
                case 'i':
                    if (direction2 == WEST || direction2 == EAST) dtmp2 = NORTH;
                    break;

                case 'K':
                case 'k':
                    if (direction2 == WEST || direction2 == EAST) dtmp2 = SOUTH;
                    break;

                case 'J':
                case 'j':
                    if (direction2 == NORTH || direction2 == SOUTH) dtmp2 = WEST;
                    break;

                case 'L':
                case 'l':
                    if (direction2 == NORTH || direction2 == SOUTH) dtmp2 = EAST;
                    break;

                default:
                    break;

            }
            game_paint(hwnd);
            return 0;
        }
    case WM_TIMER:
        {
            snake_creep(hwnd);
            game_paint(hwnd);
            return 0;
        }
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}