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

#include <string.h>
#include <stdio.h>
#include <conio.h>
#include <Windows.h>
#include <time.h>
#include <thread>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "Gdi32.lib")
#pragma comment(lib, "WS2_32.lib")
#include <stdlib.h>
#define N 80
#define WIDTH 800
#define INIT_FOODNUM 5
#define INIT_LENGTH 3
#define WINNING_LENGTH 20

int FPS = 5;

char canvas[N][N];
int head_pos_x1 = 1, head_pos_y1 = 1;
int head_pos_x2 = N - 2, head_pos_y2 = N - 2;
int length1 = INIT_LENGTH, length2 = INIT_LENGTH;
enum Direction
{
    NORTH,
    SOUTH,
    WEST,
    EAST
} direction1,
    direction2, dtmp1, dtmp2;

int player1win = 0;
int player2win = 0;
//=================================SERVER==========================================

WSAData wasData;

// receive
SOCKET recvSocket;
SOCKADDR_IN myAddr;

// send
SOCKET sendSocket;

void initWSA(WSAData wasData)
{
    WSAStartup(MAKEWORD(2, 2), &wasData);
}

int init_recvSocket(u_short port)
{
    int iResult;
    // SOCKET recvSocket;

    // create receive socket
    recvSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (recvSocket == SOCKET_ERROR)
        goto recv_init_err;

    // bind receive socket
    myAddr.sin_family = AF_INET;
    myAddr.sin_port = htons(port);
    myAddr.sin_addr.S_un.S_addr = htonl(INADDR_ANY);
    iResult = bind(recvSocket, (SOCKADDR *)&myAddr, sizeof(myAddr));
    if (0 != iResult)
    {
        int errnoo = WSAGetLastError();
        goto recv_init_err;
    }

    return recvSocket;

recv_init_err:
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
    return -1;
}

int send_data(SOCKET sendSocket, u_short port, char *address, char *sendBuf, int sendBufLen)
// return -1 when err
{
    int iRes;
    SOCKADDR_IN receiverAddr;
    memset(&receiverAddr, 0, sizeof(receiverAddr));

    receiverAddr.sin_family = AF_INET;
    receiverAddr.sin_port = htons(port);
    receiverAddr.sin_addr.S_un.S_addr = inet_addr(address);

    iRes = sendto(sendSocket, sendBuf, sendBufLen, 0, (SOCKADDR *)&receiverAddr, sizeof(receiverAddr));
    if (iRes <= 0)
    {
        return -1;
    }
    return iRes;
}

//==============================================================================


bool lose(int x, int y)
{
    if (x >= N || y >= N || x < 0 || y < 0)
        return true;
    if (canvas[x][y] == '*' || canvas[x][y] >= '@')
        return true;
    return false;
}

bool win(int length)
{
    return (length >= WINNING_LENGTH);
}

void snake_creep()
{
    //printf("creep!\n");
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
        player2win = 1;
    }
    if (lose(head_pos_x2, head_pos_y2))
    {
        player1win = 1;
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
                    while (1)
                    {
                        int p = rand() % (N * N);
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
                    while (1)
                    {
                        int p = rand() % (N * N);
                        if (canvas[p / N][p % N] == ' ')
                        {
                            canvas[p / N][p % N] = '.';
                            break;
                        }
                    }
                }
                if (canvas[i][j] == '@')
                {
                    if (length1 > length2)
                    {
                    }
                    else if (length1 < length2)
                    {
                    }
                    else
                    {
                    }
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
        player1win = 1;
    }
    if (win(length2))
    {
        player2win = 1;
    }
}

void game_init()
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
    dtmp1 = SOUTH;
    canvas[head_pos_x1][head_pos_y1] = 'A';
    canvas[head_pos_x2][head_pos_y2] = 'a';
    srand(time(0));
    for (int i = 0; i < INIT_FOODNUM; i++)
        while (1)
        {
            int p = rand() % (N * N);
            if (canvas[p / N][p % N] == ' ')
            {
                canvas[p / N][p % N] = '.';
                break;
            }
        }
}

/* void transAddrToBuf(SOCKADDR_IN sockAddr, char *buffer)
{
    if (!buffer)
    {
        return;
    }
    sprintf(buffer, "%s:%d", inet_ntoa(sockAddr.sin_addr), ntohs(sockAddr.sin_port));
} */

void player_move(int player, int operation)
{
    if (player == 1)
    {
        if (operation == 0 && dtmp1 != SOUTH)
            dtmp1 = NORTH;
        else if (operation == 1 && dtmp1 != NORTH)
            dtmp1 = SOUTH;
        else if (operation == 2 && dtmp1 != EAST)
            dtmp1 = WEST;
        else if (operation == 3 && dtmp1 != WEST)
            dtmp1 = EAST;
    }
    else
    {
        if (operation == 0 && dtmp2 != SOUTH)
            dtmp2 = NORTH;
        else if (operation == 1 && dtmp2 != NORTH)
            dtmp2 = SOUTH;
        else if (operation == 2 && dtmp2 != EAST)
            dtmp2 = WEST;
        else if (operation == 3 && dtmp2 != WEST)
            dtmp2 = EAST;
    }
}

void canvasThread()
{
    while (1)
    {
        snake_creep();
        Sleep(1000 / FPS);
    }
}

int main()
{
    char portStr[32] = {0};
    printf("listen port:\n");
    scanf("%s", &portStr);
    u_long listenport = atoi(portStr);

    initWSA(wasData);
    init_recvSocket(listenport);
    init_sendSocket();

    int iRes;

    char recvBuf[128] = {0};
    int recvBufLength = 128;

    char sendBuf[7000] = {0};
    int sendBufLength = 7000;

    SOCKADDR_IN playerAddr;
    memset(&playerAddr, 0, sizeof(playerAddr));
    int playerAddrLength = sizeof(playerAddr);

    const char *split = "_";

    game_init();

    u_long readyAddr = 0;
    u_short readyPort = 0;

    std::thread canvas_thread(canvasThread);
    canvas_thread.detach();
    printf("game start!\n");
    while (1)
    {
        memset(recvBuf, 0, recvBufLength);
        iRes = recvfrom(recvSocket, recvBuf, recvBufLength, 0, (SOCKADDR *)&playerAddr, &playerAddrLength);
        if (iRes > 0)
        {
            
            int cmd, player, operation;
            char *tok;

            tok = strtok(recvBuf, split);
            playerAddr.sin_port = htons(atoi(tok));
            playerAddr.sin_family = AF_INET;
            playerAddr.sin_addr.S_un.S_addr = inet_addr(inet_ntoa(playerAddr.sin_addr));
            tok = strtok(NULL, split);
            cmd = atoi(tok);
            if (cmd == 0)
            {
                printf("recv: %s", recvBuf);
                tok = strtok(NULL, split);
                player = atoi(tok);
                tok = strtok(NULL, split);
                operation = atoi(tok);
                player_move(player, operation);
            }
            else if (cmd == 1)
            {
                if (player1win)
                {
                    char tmp[] = "w_0";
                    memcpy(sendBuf, tmp, sizeof(tmp));
                    iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&playerAddr, sizeof(playerAddr));
                    break;
                }
                if (player2win)
                {
                    char tmp[] = "w_1";
                    memcpy(sendBuf, tmp, sizeof(tmp));
                    iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&playerAddr, sizeof(playerAddr));
                    break;
                }
                memcpy(sendBuf, canvas, sizeof(canvas));
                iRes = sendto(sendSocket, sendBuf, sendBufLength, 0, (SOCKADDR *)&playerAddr, sizeof(playerAddr));
                printf("send to %d\n", htons(playerAddr.sin_port));
            }
        }
    }
    printf("Game over!");
}