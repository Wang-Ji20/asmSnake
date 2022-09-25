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
        
    从 A 到 z：蛇 
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
#pragma comment(lib,"user32.lib");
#include <stdlib.h>
#define N 25
#define FPS 4

volatile int changed = 1;

char canvas[N][N];
int head_pos_x = 1;
int head_pos_y = 1;
int length = 1;
enum Direction{NORTH, SOUTH, WEST, EAST} direction;

int lose(int x, int y){
    if (x >= N || y >= N || x < 0 || y < 0 ) return 1;
    return 0;
}

int win(){
    return (length >= 5);
}

/* this function reads from keyboard, and set the direction for snake head. */
void read_command(){
    char cmd;
    if(!kbhit()) return;
    cmd = getch();
    switch (cmd)
    {
        case 'w':
            direction = NORTH;
            break;

        case 's':
            direction = SOUTH;
            break;

        case 'a':
            direction = WEST;
            break;
            
        case 'd':
            direction = EAST;
            break;

        default:
            break;

    }
}

void ascii_strategy(){
    /* ver 1.0 debug-only: ascii represented canvas */
    if (!changed)
    {
        return;
    }
    changed = 0;
    system("cls");
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            printf(" %c ", canvas[i][j]);
        }
        printf("\n");
    }
}

void gui_strategy(){}

void update_view(){
    #ifndef GUI
        ascii_strategy();
    #endif
    #ifdef GUI
        gui_strategy();
    #endif
}

void snake_move(){
    read_command();
    int o_head_pos_x = head_pos_x;
    int o_head_pos_y = head_pos_y;
    changed = 1;
    if (direction == NORTH)
    {
        head_pos_x--;
    }
    else if (direction == SOUTH)
    {
        head_pos_x++;
    }
    else if (direction == WEST)
    {
        head_pos_y--;
    }
    else if (direction == EAST)
    {
        head_pos_y++;
    }
    else{
        changed = 0;
    }
    
    if (lose(head_pos_x, head_pos_y))
    {
        printf("you lose");
        Sleep(1000);
        exit(0);
    }

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            if (i == head_pos_x && j == head_pos_y)
            {
                if (canvas[i][j] == '.')
                {
                    length++;
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
            
            if (canvas[i][j] <= 'z' && canvas[i][j] >= '@')
            {
                canvas[i][j] += 1; 
                if (canvas[i][j] - '@' > length)
                    canvas[i][j] = ' ';
            }
        }
    }

    if (win())
    {
        update_view();
        printf("you win");
        Sleep(1000);
        exit(0);
    }
    

}
#ifndef GUI
int main(void){
    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            canvas[i][j] = ' ';
        }
    }
    direction = SOUTH;
    canvas[10][10] = '.';
    canvas[head_pos_x][head_pos_y] = 'A';

    while (1)
    {
        update_view();
        snake_move();
        Sleep(1000/FPS);
    }
    return 0;
}
#endif

#ifdef GUI
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR pCmdLine, int nCmdShow)
{

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
        L"Learn to Program Windows",    // Window text
        WS_OVERLAPPEDWINDOW,            // Window style

        // Size and position
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,

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
    switch (uMsg)
    {
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);

            // All painting occurs here, between BeginPaint and EndPaint.
            FillRect(hdc, &ps.rcPaint, (HBRUSH) (COLOR_WINDOW+1));
            EndPaint(hwnd, &ps);
        }
        return 0;
    }

    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

#endif