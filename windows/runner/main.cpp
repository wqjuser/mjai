#include <iostream>
#include <fstream>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include "win32_window.h"
#include "flutter_window.h"
#include "resource.h"
#include "utils.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfobjects.h>
#include <mfreadwrite.h>
#include <shlwapi.h>
#include <wrl.h>
#include <codecvt>
#include <locale>
#include <wincodec.h>
#include <dwmapi.h>
#include <gdiplus.h>
#include <algorithm>
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "Msimg32.lib") // 用于 AlphaBlend
using std::max;
using std::min;
using namespace Microsoft::WRL;

// Debug logging function
void DebugLog(const char *message)
{
#ifdef _DEBUG
    OutputDebugStringA(message);
    OutputDebugStringA("\n");
#endif
    // 同时输出到控制台
    std::cout << message << std::endl;
}

#define MUTEX_NAME L"Global\\MJAI_SingleInstance_Mutex"
#define WINDOW_CLASS_NAME L"FLUTTER_RUNNER_WIN32_WINDOW"
const wchar_t *WINDOW_TITLE = L"\u9B54\u955C\x41\x49";
// 截图选择窗口类名
#define SCREENSHOT_WINDOW_CLASS L"MJAIScreenshotWindow"
LRESULT CALLBACK ScreenshotWindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

// 截图区域结构体
struct ScreenshotArea
{
    POINT start;
    POINT end;
    bool isSelecting;
    bool isDragging;
    int activeHandle; // 当前活动的拉伸点
    bool isMoving;    // 新增：是否在移动整个区域
    POINT lastMouse;  // 新增：上一次鼠标位置
    RECT confirmButton;
    RECT cancelButton;
};

#define BTN_NONE 0
#define BTN_CONFIRM 1
#define BTN_CANCEL 2
// 定义拉伸点的位置枚举
#define HANDLE_NONE -1
#define HANDLE_NW 0 // 左上角
#define HANDLE_N 1  // 上中
#define HANDLE_NE 2 // 右上角
#define HANDLE_W 3  // 左中
#define HANDLE_E 4  // 右中
#define HANDLE_SW 5 // 左下角
#define HANDLE_S 6  // 下中
#define HANDLE_SE 7 // 右下角
// 窗口相关全局变量
HDC g_screenDC = NULL;
HBITMAP g_screenBitmap = NULL;
HWND g_screenshotWindow = NULL;
ScreenshotArea g_area = {{0, 0}, {0, 0}, false};
std::function<void(const std::wstring &)> g_screenshotCallback;
void CaptureSelectedArea();
void DrawSelectionRect(HDC hdc);
HBITMAP CaptureScreen();
void CleanupScreenshot();
void SaveScreenshot();
std::string WideStringToUTF8(const std::wstring &wstr);

HANDLE g_hMutex = NULL;

// Enumerate windows callback
BOOL CALLBACK
EnumWindowsProc(HWND
                    hwnd,
                LPARAM lParam)
{
    WCHAR className[256];
    GetClassName(hwnd, className,
                 256);

    if (
        wcscmp(className,
               WINDOW_CLASS_NAME) == 0)
    {
        *((HWND *)lParam) =
            hwnd;
        return FALSE;
    }
    return TRUE;
}

std::string WideStringToUTF8(const std::wstring &wstr)
{
    if (wstr.empty())
        return std::string();
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

// Find our application window
HWND FindApplicationWindow()
{
    HWND hwnd = NULL;
    EnumWindows(EnumWindowsProc, (LPARAM)&hwnd);
    return hwnd;
}

// 获取编码器CLSID
int GetEncoderClsid(const WCHAR *format, CLSID *pClsid)
{
    UINT num = 0;  // 编码器数量
    UINT size = 0; // 编码器数组大小

    // 获取图像编码器数量和大小
    Gdiplus::GetImageEncodersSize(&num, &size);
    if (size == 0)
    {
        DebugLog("获取图像编码器失败");
        return -1;
    }

    // 分配内存
    Gdiplus::ImageCodecInfo *pImageCodecInfo = (Gdiplus::ImageCodecInfo *)(malloc(size));
    if (pImageCodecInfo == NULL)
    {
        DebugLog("内存分配失败");
        return -1;
    }

    // 获取图像编码器信息
    Gdiplus::GetImageEncoders(num, size, pImageCodecInfo);

    // 查找指定格式的编码器
    for (UINT i = 0; i < num; ++i)
    {
        if (wcscmp(pImageCodecInfo[i].MimeType, format) == 0)
        {
            *pClsid = pImageCodecInfo[i].Clsid;
            free(pImageCodecInfo);
            return i;
        }
    }

    // 清理内存
    free(pImageCodecInfo);
    return -1;
}

// 添加获取拉伸点矩形的函数
RECT GetHandleRect(int x, int y, int size)
{
    int half = size / 2;
    return {x - half, y - half, x + half, y + half};
}

// 添加检查点是否在选择区域内的函数
bool IsPointInSelectionArea(int x, int y)
{
    int left = std::min<int>(g_area.start.x, g_area.end.x);
    int top = std::min<int>(g_area.start.y, g_area.end.y);
    int right = std::max<int>(g_area.start.x, g_area.end.x);
    int bottom = std::max<int>(g_area.start.y, g_area.end.y);

    return x > left && x < right && y > top && y < bottom;
}

bool SaveBitmapToFile(HBITMAP hBitmap, const std::wstring &filePath)
{
    DebugLog("开始保存图片...");

    // 初始化GDI+
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    Gdiplus::Status status = Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

    if (status != Gdiplus::Ok)
    {
        DebugLog("GDI+初始化失败");
        return false;
    }

    bool success = false;
    try
    {
        // 从HBITMAP创建Bitmap对象
        Gdiplus::Bitmap *bitmap = Gdiplus::Bitmap::FromHBITMAP(hBitmap, NULL);
        if (bitmap == NULL)
        {
            DebugLog("创建Bitmap对象失败");
            return false;
        }

        // 获取PNG编码器CLSID
        CLSID pngClsid;
        if (GetEncoderClsid(L"image/png", &pngClsid) == -1)
        {
            DebugLog("获取PNG编码器失败");
            delete bitmap;
            return false;
        }

        // 设置PNG编码参数（可选）
        Gdiplus::EncoderParameters encoderParameters;
        encoderParameters.Count = 1;
        encoderParameters.Parameter[0].Guid = Gdiplus::EncoderQuality;
        encoderParameters.Parameter[0].Type = Gdiplus::EncoderParameterValueTypeLong;
        encoderParameters.Parameter[0].NumberOfValues = 1;
        ULONG quality = 100; // 最高质量
        encoderParameters.Parameter[0].Value = &quality;

        // 保存图片
        status = bitmap->Save(filePath.c_str(), &pngClsid, &encoderParameters);
        success = (status == Gdiplus::Ok);

        if (!success)
        {
            DebugLog("保存图片失败");
        }
        else
        {
            DebugLog("图片保存成功");
        }

        // 清理Bitmap对象
        delete bitmap;
    }
    catch (const std::exception &e)
    {
        DebugLog(("保存图片时发生异常: " + std::string(e.what())).c_str());
        success = false;
    }

    // 关闭GDI+
    Gdiplus::GdiplusShutdown(gdiplusToken);

    return success;
}
// 获取临时文件路径
std::wstring GetTempScreenshotPath()
{
    wchar_t tempPath[MAX_PATH];
    GetTempPathW(MAX_PATH, tempPath);

    // 获取当前时间
    SYSTEMTIME st;
    GetLocalTime(&st);

    // 格式化时间字符串：年月日时分秒
    wchar_t timeStr[20];
    swprintf_s(timeStr, 20, L"%04d%02d%02d%02d%02d%02d",
               st.wYear,
               st.wMonth,
               st.wDay,
               st.wHour,
               st.wMinute,
               st.wSecond);

    std::wstring fileName = L"mjai_" + std::wstring(timeStr) + L".png";

    std::wstring fullPath = std::wstring(tempPath) + fileName;
    return fullPath;
}

Gdiplus::Image *LoadIconFromResource(UINT resourceID)
{
    Gdiplus::Image *image = nullptr;
    HICON hIcon = (HICON)LoadImage(
        GetModuleHandle(NULL),
        MAKEINTRESOURCE(resourceID),
        IMAGE_ICON,
        0, // 使用图标原始尺寸
        0, // 使用图标原始尺寸
        LR_SHARED);

    if (hIcon)
    {
        image = Gdiplus::Bitmap::FromHICON(hIcon);
        DestroyIcon(hIcon);
    }
    return image;
}

// 在窗口销毁时清理资源
void CleanupScreenshot()
{
    if (g_screenBitmap)
    {
        DeleteObject(g_screenBitmap);
        g_screenBitmap = NULL;
    }
    if (g_screenDC)
    {
        ReleaseDC(NULL, g_screenDC);
        g_screenDC = NULL;
    }
}

// 添加检测鼠标是否在拉伸点上的函数
int HitTest(int x, int y)
{
    if (!g_area.isSelecting)
    {
        int left = std::min<int>(g_area.start.x, g_area.end.x);
        int top = std::min<int>(g_area.start.y, g_area.end.y);
        int right = std::max<int>(g_area.start.x, g_area.end.x);
        int bottom = std::max<int>(g_area.start.y, g_area.end.y);

        const int handleSize = 8;
        POINT handles[] = {
            {left, top},                  // HANDLE_NW
            {(left + right) / 2, top},    // HANDLE_N
            {right, top},                 // HANDLE_NE
            {left, (top + bottom) / 2},   // HANDLE_W
            {right, (top + bottom) / 2},  // HANDLE_E
            {left, bottom},               // HANDLE_SW
            {(left + right) / 2, bottom}, // HANDLE_S
            {right, bottom}               // HANDLE_SE
        };

        for (int i = 0; i < 8; i++)
        {
            RECT handleRect = GetHandleRect(handles[i].x, handles[i].y, handleSize);
            if (x >= handleRect.left && x <= handleRect.right &&
                y >= handleRect.top && y <= handleRect.bottom)
            {
                return i;
            }
        }
    }
    return HANDLE_NONE;
}

// Cleanup mutex resources
void CleanupMutex()
{
    if (g_hMutex != NULL)
    {
        ReleaseMutex(g_hMutex);
        CloseHandle(g_hMutex);
        g_hMutex = NULL;
        DebugLog("Mutex cleaned up");
    }
}

// 添加捕获屏幕函数
HBITMAP CaptureScreen()
{
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    HDC screenDC = GetDC(NULL);
    HDC memDC = CreateCompatibleDC(screenDC);
    HBITMAP bitmap = CreateCompatibleBitmap(screenDC, screenWidth, screenHeight);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, bitmap);

    // 捕获整个屏幕
    BitBlt(memDC, 0, 0, screenWidth, screenHeight, screenDC, 0, 0, SRCCOPY);

    SelectObject(memDC, oldBitmap);
    DeleteDC(memDC);
    ReleaseDC(NULL, screenDC);

    return bitmap;
}

// 保存截图的辅助函数
void SaveScreenshot()
{
    int left = std::min<int>(g_area.start.x, g_area.end.x);
    int top = std::min<int>(g_area.start.y, g_area.end.y);
    int right = std::max<int>(g_area.start.x, g_area.end.x);
    int bottom = std::max<int>(g_area.start.y, g_area.end.y);
    int width = right - left;
    int height = bottom - top;

    if (width <= 0 || height <= 0)
    {
        if (g_screenshotCallback)
        {
            g_screenshotCallback(L"");
        }
        DestroyWindow(g_screenshotWindow);
        return;
    }

    // 创建位图
    HDC screenDC = GetDC(NULL);
    HDC memDC = CreateCompatibleDC(screenDC);
    HBITMAP bitmap = CreateCompatibleBitmap(screenDC, width, height);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, bitmap);

    // 复制选定区域
    BitBlt(memDC, 0, 0, width, height, screenDC, left, top, SRCCOPY);

    // 保存图片
    std::wstring tempPath = GetTempScreenshotPath();
    SaveBitmapToFile(bitmap, tempPath);

    // 清理资源
    SelectObject(memDC, oldBitmap);
    DeleteObject(bitmap);
    DeleteDC(memDC);
    ReleaseDC(NULL, screenDC);

    // 回调返回路径
    if (g_screenshotCallback)
    {
        g_screenshotCallback(tempPath.c_str());
    }

    DestroyWindow(g_screenshotWindow);
}

// 创建半透明分层窗口
HWND CreateOverlayWindow(HINSTANCE hInstance)
{
    WNDCLASSEX wc = {0};
    wc.cbSize = sizeof(WNDCLASSEX);
    wc.lpfnWndProc = ScreenshotWindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = SCREENSHOT_WINDOW_CLASS;
    wc.hCursor = LoadCursor(NULL, IDC_CROSS); // 设置十字光标
    RegisterClassEx(&wc);

    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    HWND hwnd = CreateWindowEx(
        WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
        SCREENSHOT_WINDOW_CLASS,
        L"Screenshot",
        WS_POPUP,
        0, 0, screenWidth, screenHeight,
        NULL,
        NULL,
        hInstance,
        NULL);

    if (hwnd)
    {
        // 捕获整个屏幕的静态图像
        g_screenDC = GetDC(NULL);
        g_screenBitmap = CaptureScreen();

        // 创建和设置分层窗口
        HDC hdcScreen = GetDC(hwnd);
        HDC memDC = CreateCompatibleDC(hdcScreen);
        HBITMAP memBitmap = CreateCompatibleBitmap(hdcScreen, screenWidth, screenHeight);
        HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

        // 绘制捕获的屏幕图像
        HDC screenMemDC = CreateCompatibleDC(hdcScreen);
        HBITMAP oldScreenBitmap = (HBITMAP)SelectObject(screenMemDC, g_screenBitmap);
        BitBlt(memDC, 0, 0, screenWidth, screenHeight, screenMemDC, 0, 0, SRCCOPY);
        SelectObject(screenMemDC, oldScreenBitmap);
        DeleteDC(screenMemDC);

        // 更新分层窗口
        BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, 0};
        POINT ptSrc = {0, 0};
        SIZE sizeWnd = {screenWidth, screenHeight};
        UpdateLayeredWindow(hwnd, hdcScreen, NULL, &sizeWnd,
                            memDC, &ptSrc, 0, &blend, ULW_ALPHA);

        // 清理资源
        SelectObject(memDC, oldBitmap);
        DeleteObject(memBitmap);
        DeleteDC(memDC);
        ReleaseDC(hwnd, hdcScreen);

        ShowWindow(hwnd, SW_SHOW);
        UpdateWindow(hwnd);
        SetForegroundWindow(hwnd);
    }

    return hwnd;
}

// DrawSelectionRect 实现
void DrawSelectionRect(HDC hdc)
{
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);

    int left = std::min<int>(g_area.start.x, g_area.end.x);
    int top = std::min<int>(g_area.start.y, g_area.end.y);
    int right = std::max<int>(g_area.start.x, g_area.end.x);
    int bottom = std::max<int>(g_area.start.y, g_area.end.y);

    HDC memDC = CreateCompatibleDC(hdc);
    HBITMAP memBitmap = CreateCompatibleBitmap(hdc, screenWidth, screenHeight);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

    // 绘制原始截图
    HDC screenMemDC = CreateCompatibleDC(hdc);
    HBITMAP oldScreenBitmap = (HBITMAP)SelectObject(screenMemDC, g_screenBitmap);
    BitBlt(memDC, 0, 0, screenWidth, screenHeight, screenMemDC, 0, 0, SRCCOPY);
    SelectObject(screenMemDC, oldScreenBitmap);
    DeleteDC(screenMemDC);

    if (right > left && bottom > top)
    {
        // 创建暗色遮罩DC
        HDC darkDC = CreateCompatibleDC(hdc);
        HBITMAP darkBitmap = CreateCompatibleBitmap(hdc, screenWidth, screenHeight);
        HBITMAP oldDarkBitmap = (HBITMAP)SelectObject(darkDC, darkBitmap);

        // 填充黑色遮罩
        HBRUSH blackBrush = CreateSolidBrush(RGB(0, 0, 0));
        RECT fullRect = {0, 0, screenWidth, screenHeight};
        FillRect(darkDC, &fullRect, blackBrush);
        DeleteObject(blackBrush);

        // 将暗色遮罩以半透明方式覆盖到主DC上
        BLENDFUNCTION darkBlend = {AC_SRC_OVER, 0, 120, 0}; // 降低透明度值使遮罩更暗
        AlphaBlend(memDC, 0, 0, screenWidth, screenHeight, 
                  darkDC, 0, 0, screenWidth, screenHeight, darkBlend);

        // 清理暗色遮罩资源
        SelectObject(darkDC, oldDarkBitmap);
        DeleteObject(darkBitmap);
        DeleteDC(darkDC);

        // 恢复选区的原始图像
        HDC originalDC = CreateCompatibleDC(hdc);
        SelectObject(originalDC, g_screenBitmap);
        BitBlt(memDC, left, top, right - left, bottom - top,
               originalDC, left, top, SRCCOPY);
        DeleteDC(originalDC);

        // 绘制边框
        HPEN borderPen = CreatePen(PS_SOLID, 2, RGB(30, 144, 255));
        HPEN oldPen = (HPEN)SelectObject(memDC, borderPen);
        SelectObject(memDC, GetStockObject(NULL_BRUSH));
        Rectangle(memDC, left, top, right, bottom);
        SelectObject(memDC, oldPen);
        DeleteObject(borderPen);

        // 显示尺寸信息
        wchar_t sizeText[64];
        swprintf_s(sizeText, L"%dx%d", right - left, bottom - top);
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, RGB(255, 255, 255));

        // 计算文本尺寸
        RECT textRect = {0};
        DrawText(memDC, sizeText, -1, &textRect, DT_CALCRECT);
        int textWidth = textRect.right - textRect.left;
        int textHeight = textRect.bottom - textRect.top;

        // 确定文本显示位置
        int textX = left + 5;
        int textY = top - textHeight - 5;
        if (textY < 0) {
            textY = bottom + 5;
        }

        // 绘制文本背景
        RECT bgRect = {textX - 2, textY - 2, textX + textWidth + 2, textY + textHeight + 2};
        HBRUSH bgBrush = CreateSolidBrush(RGB(0, 0, 0));
        FillRect(memDC, &bgRect, bgBrush);
        DeleteObject(bgBrush);

        // 绘制文本
        TextOut(memDC, textX, textY, sizeText, static_cast<int>(wcslen(sizeText)));

        // 如果选择完成，绘制拉伸点和按钮
        if (!g_area.isSelecting)
        {
            // 绘制拉伸点
            const int handleSize = 8;
            HBRUSH handleBrush = CreateSolidBrush(RGB(30, 144, 255));

            POINT handles[] = {
                {left, top},                   // 左上
                {(left + right) / 2, top},     // 上中
                {right, top},                  // 右上
                {left, (top + bottom) / 2},    // 左中
                {right, (top + bottom) / 2},   // 右中
                {left, bottom},                // 左下
                {(left + right) / 2, bottom},  // 下中
                {right, bottom}                // 右下
            };

            for (const auto& handle : handles)
            {
                RECT handleRect = GetHandleRect(handle.x, handle.y, handleSize);
                FillRect(memDC, &handleRect, handleBrush);
            }
            DeleteObject(handleBrush);

            // 绘制确认和取消按钮
            const int btnSize = 30;
            const int margin = 10;
            const int padding = 10; // 背景额外的内边距
            const int cornerRadius = 8; // 圆角半径

            // 计算按钮位置（确保在选区范围内）
            g_area.confirmButton = {
                right - btnSize * 2 - margin * 2,
                bottom + margin,
                right - btnSize - margin * 2,
                bottom + btnSize + margin
            };

            g_area.cancelButton = {
                right - btnSize - margin,
                bottom + margin,
                right - margin,  // 修改这里，确保不超出右边界
                bottom + btnSize + margin
            };

            // 计算背景矩形区域
            RECT backgroundRect = {
                g_area.confirmButton.left - padding,
                g_area.confirmButton.top - padding,
                g_area.cancelButton.right + padding,
                g_area.cancelButton.bottom + padding
            };

            // 创建背景DC和位图用于绘制半透明背景
            HDC bgDC = CreateCompatibleDC(hdc);
            HBITMAP bgBitmap = CreateCompatibleBitmap(hdc, screenWidth, screenHeight);
            HBITMAP oldBgBitmap = (HBITMAP)SelectObject(bgDC, bgBitmap);

            // 清除背景
            RECT clearRect = {0, 0, screenWidth, screenHeight};
            FillRect(bgDC, &clearRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
            
            // 创建并设置圆角区域
            HRGN roundRectRegion = CreateRoundRectRgn(
                backgroundRect.left,
                backgroundRect.top,
                backgroundRect.right + 1,  // +1 是因为 CreateRoundRectRgn 是右下角独占的
                backgroundRect.bottom + 1,
                cornerRadius * 2,
                cornerRadius * 2
            );

            // 设置裁剪区域
            SelectClipRgn(bgDC, roundRectRegion);

            // 填充黑色背景
            HBRUSH buttonBlackBrush = CreateSolidBrush(RGB(0, 0, 0));
            FillRect(bgDC, &backgroundRect, buttonBlackBrush);
            DeleteObject(buttonBlackBrush);
            
            // 重置裁剪区域
            SelectClipRgn(bgDC, NULL);

            // 将半透明背景混合到主DC
            BLENDFUNCTION blend = {AC_SRC_OVER, 0, 192, 0}; // 75% 透明度
            AlphaBlend(memDC,
                      backgroundRect.left, backgroundRect.top,
                      backgroundRect.right - backgroundRect.left,
                      backgroundRect.bottom - backgroundRect.top,
                      bgDC,
                      backgroundRect.left, backgroundRect.top,
                      backgroundRect.right - backgroundRect.left,
                      backgroundRect.bottom - backgroundRect.top,
                      blend);

            // 清理背景资源
            SelectObject(bgDC, oldBgBitmap);
            DeleteObject(bgBitmap);
            DeleteDC(bgDC);
            DeleteObject(roundRectRegion);

            // 加载并绘制图标
            HICON hCheckIcon = (HICON)LoadImage(
                GetModuleHandle(NULL),
                MAKEINTRESOURCE(IDI_CHECK),
                IMAGE_ICON,
                btnSize,
                btnSize,
                LR_SHARED);

            HICON hCrossIcon = (HICON)LoadImage(
                GetModuleHandle(NULL),
                MAKEINTRESOURCE(IDI_CROSS),
                IMAGE_ICON,
                btnSize,
                btnSize,
                LR_SHARED);

            if (hCheckIcon && hCrossIcon)
            {
                DrawIconEx(
                    memDC,
                    g_area.confirmButton.left,
                    g_area.confirmButton.top,
                    hCheckIcon,
                    btnSize,
                    btnSize,
                    0,
                    NULL,
                    DI_NORMAL);

                DrawIconEx(
                    memDC,
                    g_area.cancelButton.left,
                    g_area.cancelButton.top,
                    hCrossIcon,
                    btnSize,
                    btnSize,
                    0,
                    NULL,
                    DI_NORMAL);

                DestroyIcon(hCheckIcon);
                DestroyIcon(hCrossIcon);
            }
        }
    }

    // 将完整内容更新到窗口
    BLENDFUNCTION finalBlend = {AC_SRC_OVER, 0, 255, 0};
    POINT ptSrc = {0, 0};
    SIZE sizeWnd = {screenWidth, screenHeight};
    UpdateLayeredWindow(WindowFromDC(hdc), hdc, NULL, &sizeWnd,
                       memDC, &ptSrc, 0, &finalBlend, ULW_ALPHA);

    // 清理资源
    SelectObject(memDC, oldBitmap);
    DeleteObject(memBitmap);
    DeleteDC(memDC);
}

// 截图窗口消息处理
LRESULT CALLBACK ScreenshotWindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg)
    {
    case WM_ERASEBKGND:
        return 1;

    case WM_CREATE:
    {
        // 初始状态
        g_area = {};
        SetForegroundWindow(hwnd);
        return 0;
    }

    case WM_KEYDOWN:
    {
        if (wParam == VK_ESCAPE)
        {
            if (g_screenshotCallback)
            {
                g_screenshotCallback(L"");
            }
            DestroyWindow(hwnd);
        }
        return 0;
    }

    case WM_MOUSEMOVE:
    {
        int x = LOWORD(lParam);
        int y = HIWORD(lParam);
        int screenWidth = GetSystemMetrics(SM_CXSCREEN);
        int screenHeight = GetSystemMetrics(SM_CYSCREEN);

        // 限制坐标在屏幕范围内
        x = max(0, min(x, screenWidth));
        y = max(0, min(y, screenHeight));

        if (g_area.isDragging && g_area.activeHandle != HANDLE_NONE)
        {
            // 计算新的坐标
            int newStartX = g_area.start.x;
            int newStartY = g_area.start.y;
            int newEndX = g_area.end.x;
            int newEndY = g_area.end.y;

            // 根据拖动的拉伸点更新矩形尺寸
            switch (g_area.activeHandle)
            {
            case HANDLE_NW: // 左上角
                newStartX = x;
                newStartY = y;
                break;
            case HANDLE_N: // 上中
                newStartY = y;
                break;
            case HANDLE_NE: // 右上角
                newEndX = x;
                newStartY = y;
                break;
            case HANDLE_W: // 左中
                newStartX = x;
                break;
            case HANDLE_E: // 右中
                newEndX = x;
                break;
            case HANDLE_SW: // 左下角
                newStartX = x;
                newEndY = y;
                break;
            case HANDLE_S: // 下中
                newEndY = y;
                break;
            case HANDLE_SE: // 右下角
                newEndX = x;
                newEndY = y;
                break;
            }

            // 更新坐标
            g_area.start.x = newStartX;
            g_area.start.y = newStartY;
            g_area.end.x = newEndX;
            g_area.end.y = newEndY;

            // 直接重绘而不是等待WM_PAINT
            HDC hdc = GetDC(hwnd);
            DrawSelectionRect(hdc);
            ReleaseDC(hwnd, hdc);
        }
        else if (g_area.isMoving)
        {
            int dx = x - g_area.lastMouse.x;
            int dy = y - g_area.lastMouse.y;

            // 计算选区的宽度和高度
            int width = abs(g_area.end.x - g_area.start.x);
            int height = abs(g_area.end.y - g_area.start.y);

            // 计算新位置
            int newStartX = g_area.start.x + dx;
            int newStartY = g_area.start.y + dy;
            int newEndX = newStartX + width;
            int newEndY = newStartY + height;

            // 检查并调整以确保不超出屏幕边界
            if (newStartX < 0) {
                newStartX = 0;
                newEndX = width;
            }
            if (newStartY < 0) {
                newStartY = 0;
                newEndY = height;
            }
            if (newEndX > screenWidth) {
                newEndX = screenWidth;
                newStartX = screenWidth - width;
            }
            if (newEndY > screenHeight) {
                newEndY = screenHeight;
                newStartY = screenHeight - height;
            }

            // 更新选择区域位置
            g_area.start.x = newStartX;
            g_area.start.y = newStartY;
            g_area.end.x = newEndX;
            g_area.end.y = newEndY;

            // 更新上一次鼠标位置
            g_area.lastMouse.x = x;
            g_area.lastMouse.y = y;

            // 直接重绘而不是等待WM_PAINT
            HDC hdc = GetDC(hwnd);
            DrawSelectionRect(hdc);
            ReleaseDC(hwnd, hdc);
        }
        else if (g_area.isSelecting)
        {
            g_area.end.x = x;
            g_area.end.y = y;

            HDC hdc = GetDC(hwnd);
            DrawSelectionRect(hdc);
            ReleaseDC(hwnd, hdc);
        }

        // 更新鼠标光标
        if (!g_area.isSelecting && !g_area.isDragging && !g_area.isMoving)
        {
            int handle = HitTest(x, y);
            LPTSTR cursor = IDC_ARROW;

            if (handle != HANDLE_NONE)
            {
                // 在拉伸点上时显示调整大小的光标
                switch (handle)
                {
                case HANDLE_NW:
                case HANDLE_SE:
                    cursor = IDC_SIZENWSE;
                    break;
                case HANDLE_NE:
                case HANDLE_SW:
                    cursor = IDC_SIZENESW;
                    break;
                case HANDLE_N:
                case HANDLE_S:
                    cursor = IDC_SIZENS;
                    break;
                case HANDLE_E:
                case HANDLE_W:
                    cursor = IDC_SIZEWE;
                    break;
                }
            }
            else if (IsPointInSelectionArea(x, y))
            {
                cursor = IDC_SIZEALL; // 在选择区域内显示移动光标
            }
            SetCursor(LoadCursor(NULL, cursor));
        }
        else if (g_area.isDragging)
        {
            // 在拖动过程中保持对应的调整大小光标
            LPTSTR cursor = IDC_ARROW;
            switch (g_area.activeHandle)
            {
            case HANDLE_NW:
            case HANDLE_SE:
                cursor = IDC_SIZENWSE;
                break;
            case HANDLE_NE:
            case HANDLE_SW:
                cursor = IDC_SIZENESW;
                break;
            case HANDLE_N:
            case HANDLE_S:
                cursor = IDC_SIZENS;
                break;
            case HANDLE_E:
            case HANDLE_W:
                cursor = IDC_SIZEWE;
                break;
            }
            SetCursor(LoadCursor(NULL, cursor));
        }
        else if (g_area.isMoving)
        {
            SetCursor(LoadCursor(NULL, IDC_SIZEALL)); // 移动时保持移动光标
        }
        else
        {
            SetCursor(LoadCursor(NULL, IDC_CROSS)); // 选择过程中保持十字光标
        }

        return 0;
    }

    case WM_LBUTTONDOWN:
    {
        int x = LOWORD(lParam);
        int y = HIWORD(lParam);

        // 检查是否点击了按钮
        if (!g_area.isSelecting && !g_area.isDragging)
        {
            POINT pt = {x, y};
            if (PtInRect(&g_area.confirmButton, pt))
            {
                SaveScreenshot();
                return 0;
            }
            if (PtInRect(&g_area.cancelButton, pt))
            {
                if (g_screenshotCallback)
                {
                    g_screenshotCallback(L"");
                }
                DestroyWindow(hwnd);
                return 0;
            }
        }

        // 检查是否点击了拉伸点
        g_area.activeHandle = HitTest(x, y);
        if (g_area.activeHandle != HANDLE_NONE)
        {
            g_area.isDragging = true;
            SetCapture(hwnd);
        }
        else if (IsPointInSelectionArea(x, y))
        {
            // 开始移动整个区域
            g_area.isMoving = true;
            g_area.lastMouse.x = x;
            g_area.lastMouse.y = y;
            SetCapture(hwnd);
        }
        else
        {
            // 开始新的选择
            g_area.isSelecting = true;
            g_area.start.x = g_area.end.x = x;
            g_area.start.y = g_area.end.y = y;
            SetCapture(hwnd);
        }

        HDC hdc = GetDC(hwnd);
        DrawSelectionRect(hdc);
        ReleaseDC(hwnd, hdc);
        return 0;
    }

    case WM_LBUTTONUP:
    {
        if (g_area.isSelecting || g_area.isDragging || g_area.isMoving)
        {
            g_area.isSelecting = false;
            g_area.isDragging = false;
            g_area.isMoving = false;
            g_area.activeHandle = HANDLE_NONE;
            ReleaseCapture();

            // 确保选择区域有效
            if (g_area.start.x != g_area.end.x && g_area.start.y != g_area.end.y)
            {
                HDC hdc = GetDC(hwnd);
                DrawSelectionRect(hdc);
                ReleaseDC(hwnd, hdc);
            }
            else
            {
                if (g_screenshotCallback)
                {
                    g_screenshotCallback(L"");
                }
                DestroyWindow(hwnd);
            }
        }
        return 0;
    }

    case WM_RBUTTONDOWN:
    {
        // 右键点击取消截图
        if (g_screenshotCallback)
        {
            g_screenshotCallback(L"");
        }
        DestroyWindow(hwnd);
        return 0;
    }

    case WM_PAINT:
    {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        DrawSelectionRect(hdc);
        EndPaint(hwnd, &ps);
        return 0;
    }

    case WM_DESTROY:
        CleanupScreenshot();
        g_screenshotWindow = NULL;
        return 0;
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}

// 捕获选定区域
void CaptureSelectedArea()
{
    // 计算选择区域
    int left = std::min<int>(g_area.start.x, g_area.end.x);
    int top = std::min<int>(g_area.start.y, g_area.end.y);
    int width = abs(g_area.end.x - g_area.start.x);
    int height = abs(g_area.end.y - g_area.start.y);

    // 创建屏幕DC和兼容DC
    HDC screenDC = GetDC(NULL);
    HDC memDC = CreateCompatibleDC(screenDC);

    // 创建位图
    HBITMAP hBitmap = CreateCompatibleBitmap(screenDC, width, height);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, hBitmap);

    // 复制屏幕内容
    BitBlt(memDC, 0, 0, width, height, screenDC, left, top, SRCCOPY);

    // 保存位图
    std::wstring savePath = GetTempScreenshotPath();
    bool saveSuccess = false;

    if (!savePath.empty())
    {
        saveSuccess = SaveBitmapToFile(hBitmap, savePath);
    }

    // 清理资源
    SelectObject(memDC, oldBitmap);
    DeleteObject(hBitmap);
    DeleteDC(memDC);
    ReleaseDC(NULL, screenDC);

    // 回调结果
    if (g_screenshotCallback)
    {
        g_screenshotCallback(saveSuccess ? savePath : L"");
    }
}

// Try to activate existing window
bool ActivateExistingWindow(HWND
                                existingWindow)
{
    if (existingWindow == NULL)
    {
        DebugLog("No existing window found");
        return false;
    }

    DebugLog("Found existing window, attempting to activate");

    HWND foregroundWindow = GetForegroundWindow();
    DWORD foregroundThreadID = GetWindowThreadProcessId(foregroundWindow, NULL);
    DWORD currentThreadID = GetCurrentThreadId();

    AttachThreadInput(currentThreadID, foregroundThreadID, TRUE);

    if (
        IsIconic(existingWindow))
    {
        DebugLog("Window was minimized, restoring");
        ShowWindow(existingWindow, SW_RESTORE);
    }

    SetWindowPos(existingWindow, HWND_TOPMOST,
                 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    SetWindowPos(existingWindow, HWND_NOTOPMOST,
                 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);

    SetForegroundWindow(existingWindow);
    ShowWindow(existingWindow, SW_SHOW);
    SetActiveWindow(existingWindow);

    AttachThreadInput(currentThreadID, foregroundThreadID, FALSE);

    DebugLog("Window activation attempted");
    return true;
}

// Check if another instance is already running
bool IsAnotherInstanceRunning()
{
    DebugLog("Checking for another instance");

    g_hMutex = CreateMutex(NULL, TRUE, MUTEX_NAME);

    if (g_hMutex == NULL)
    {
        DebugLog("Failed to create mutex");
        return false;
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS)
    {
        DebugLog("Found existing mutex, looking for window");
        HWND existingWindow = FindApplicationWindow();
        if (existingWindow)
        {
            ActivateExistingWindow(existingWindow);
        }
        else
        {
            DebugLog("Existing window not found");
        }

        CleanupMutex();
        return true;
    }

    DebugLog("No other instance found");
    return false;
}

int APIENTRY
wWinMain(_In_
             HINSTANCE instance,
         _In_opt_
             HINSTANCE prev,
         _In_ wchar_t *command_line, _In_ int show_command)
{
    if (

        IsAnotherInstanceRunning()

    )
    {
        DebugLog("Another instance is running, exiting");
        return EXIT_SUCCESS;
    }

    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
    {
        CreateAndAttachConsole();

        DebugLog("Console attached");
    }

    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    flutter::DartProject project(L"data");

    std::vector<std::string> command_line_arguments = GetCommandLineArguments();
    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(WINDOW_TITLE, origin, size))
    {
        DebugLog("Failed to create window");

        CleanupMutex();

        return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);
    auto messenger = window.GetBinaryMessenger();

    // 屏幕分辨率通道
    auto screenChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger,
        "com.htx.nativeChannel/screenResolution",
        &flutter::StandardMethodCodec::GetInstance());

    // 剪切板通道
    auto clipboardChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger,
        "clipboard_listener",
        &flutter::StandardMethodCodec::GetInstance());

    // 截图channel
    auto screenshotChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger,
        "com.htx.nativeChannel/screenshot",
        &flutter::StandardMethodCodec::GetInstance());

    // 屏幕分辨率处理器
    std::function<void(const flutter::MethodCall<flutter::EncodableValue> &,
                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>
        screenHandler =
            [](const flutter::MethodCall<flutter::EncodableValue> &call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        if (call.method_name().compare("getSystemScreenResolution") == 0)
        {
            std::string resolution = Win32Window::GetScreenResolution();
            result->Success(flutter::EncodableValue(resolution));
        }
        else
        {
            result->NotImplemented();
        }
    };

    // 剪切板处理器
    std::function<void(const flutter::MethodCall<flutter::EncodableValue> &,
                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>
        clipboardHandler =
            [](const flutter::MethodCall<flutter::EncodableValue> &call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        if (call.method_name().compare("getClipboardFiles") == 0)
        {
            std::vector<std::string> filePaths;

            if (!OpenClipboard(nullptr))
            {
                result->Error("CLIPBOARD_ERROR", "Failed to open clipboard");
                return;
            }

            HANDLE hData = GetClipboardData(CF_HDROP);
            if (hData != nullptr)
            {
                HDROP hDrop = static_cast<HDROP>(GlobalLock(hData));
                if (hDrop != nullptr)
                {
                    UINT fileCount = DragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0);

                    for (UINT i = 0; i < fileCount; i++)
                    {
                        TCHAR filePath[MAX_PATH];
                        DragQueryFile(hDrop, i, filePath, MAX_PATH);

                        // 将 TCHAR 转换为 std::string
                        int size_needed = WideCharToMultiByte(CP_UTF8, 0, filePath, -1, NULL, 0, NULL, NULL);
                        std::string strPath(size_needed, 0);
                        WideCharToMultiByte(CP_UTF8, 0, filePath, -1, &strPath[0], size_needed, NULL, NULL);

                        // 移除末尾的空字符
                        if (!strPath.empty() && strPath.back() == '\0')
                        {
                            strPath.pop_back();
                        }

                        filePaths.push_back(strPath);
                    }
                    GlobalUnlock(hData);
                }
            }

            CloseClipboard();

            if (!filePaths.empty())
            {
                flutter::EncodableList list;
                for (const auto &path : filePaths)
                {
                    list.push_back(flutter::EncodableValue(path));
                }
                result->Success(flutter::EncodableValue(list));
            }
            else
            {
                result->Success(flutter::EncodableValue(nullptr));
            }
        }
        else
        {
            result->NotImplemented();
        }
    };

    // 截图处理器
    std::function<void(const flutter::MethodCall<flutter::EncodableValue> &,
                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>)>
        screenshotHandler =
            [](const flutter::MethodCall<flutter::EncodableValue> &call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        if (call.method_name().compare("captureScreen") == 0)
        {
            // 如果已经有截图窗口在运行，直接返回
            if (g_screenshotWindow != NULL)
            {
                result->Error("SCREENSHOT_IN_PROGRESS", "截图正在进行中");
                return;
            }

            auto *resultPtr = result.release();
            g_screenshotCallback = [resultPtr](const std::wstring &path)
            {
                std::string utf8Path = WideStringToUTF8(path);
                if (!path.empty())
                {
                    resultPtr->Success(flutter::EncodableValue(utf8Path));
                }
                else
                {
                    resultPtr->Error("SCREENSHOT_CANCELLED", "截图已取消");
                }
                delete resultPtr;
            };

            g_screenshotWindow = CreateOverlayWindow(GetModuleHandle(NULL));
            if (g_screenshotWindow)
            {
                ShowWindow(g_screenshotWindow, SW_SHOW);
                UpdateWindow(g_screenshotWindow);
            }
            else
            {
                g_screenshotCallback(L"");
            }
        }
        else
        {
            result->NotImplemented();
        }
    };

    screenChannel->SetMethodCallHandler(screenHandler);
    clipboardChannel->SetMethodCallHandler(clipboardHandler);
    screenshotChannel->SetMethodCallHandler(screenshotHandler);

    ::MSG msg;
    while (
        ::GetMessage(&msg, nullptr,
                     0, 0))
    {
        ::TranslateMessage(&msg);
        ::DispatchMessage(&msg);
    }

    CleanupMutex();

    ::CoUninitialize();
    return EXIT_SUCCESS;
}