#include <Windows.h>
#include <stdlib.h>

extern "C" int __cdecl printf(char* format, ...);

extern "C" HBITMAP myloadFood(){
    return (HBITMAP) LoadImage(NULL, "food.bmp", IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE);
}

extern "C" HBITMAP myloadWall(){
    return (HBITMAP) LoadImage(NULL, "wall.bmp", IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE);
}

extern "C" HBITMAP myloadSnake1(){
    return (HBITMAP) LoadImage(NULL, "snake1.bmp", IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE);
}

extern "C" HBITMAP myloadSnake2(){
    return (HBITMAP) LoadImage(NULL, "snake2.bmp", IMAGE_BITMAP, 10, 10, LR_LOADFROMFILE);
}

extern "C" HGDIOBJ mySelectObject(HDC hdc, HGDIOBJ h){
    return SelectObject(hdc, h);
}

extern "C" BOOL myBitBlt(HDC hdc, int x, int y, int cx, int cy, HDC hdcSrc, int x1, int y1, DWORD rop){
    return BitBlt(hdc, x, y, cx, cy, hdcSrc, x1, y1, rop);
}

extern "C" HDC __stdcall myCreateCompatibleDC(HDC hdc){
    return CreateCompatibleDC(hdc);
}

extern "C" HBITMAP myCreateCompatibleBitmap(HDC hdc, int cx, int cy){
    return CreateCompatibleBitmap(hdc, cx, cy);
}

extern "C" HDC myGetDC(HWND hWnd){
    return GetDC(hWnd);
}

extern "C" int myReleaseDC(HWND hWnd, HDC hDC){
    return ReleaseDC(hWnd, hDC);
}

extern "C" void debug_canvas(char* canvas){
    for (int i = 0; i < 80; i++)
    {
        for (int j = 0; j < 80; j++)
        {
            printf("%c ", canvas[i*80 + j]);
        }
        printf("\n");
    }
    return;   
}

extern "C" int getoffset(int i, int j){
    printf("i = %d, j = %d, product  = %d \n", i, j, 80 * i + j);
    return 80 * i + j;
}

extern "C" int randomNumber(){
    return rand();
}