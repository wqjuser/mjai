#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>
#include <imm.h>

#include <functional>
#include <memory>
#include <string>

class Win32Window {
public:
    static std::string GetScreenResolution();

    // 快捷窗口相关的静态方法
    static HWND CreateQuickWindow(const std::wstring& title);
    static void ShowQuickWindow();
    static void HideQuickWindow();
    static void DestroyQuickWindow();
    static LRESULT CALLBACK QuickWndProc(HWND const window,
    UINT const message,
            WPARAM const wparam,
    LPARAM const lparam) noexcept;

public:
    struct Point {
        unsigned int x;
        unsigned int y;
        Point(unsigned int x, unsigned int y) : x(x), y(y) {}
    };

    struct Size {
        unsigned int width;
        unsigned int height;
        Size(unsigned int width, unsigned int height)
                : width(width), height(height) {}
    };

    Win32Window();
    virtual ~Win32Window();

    bool Create(const std::wstring& title, const Point& origin, const Size& size);
    bool Show();
    void Destroy();
    void SetChildContent(HWND content);
    HWND GetHandle();
    void SetQuitOnClose(bool quit_on_close);
    RECT GetClientArea();
    void UpdateImePosition(int x, int y, int width, int height);

protected:
    virtual LRESULT MessageHandler(HWND window,
                                   UINT const message,
                                   WPARAM const wparam,
                                   LPARAM const lparam) noexcept;

    virtual bool OnCreate();
    virtual void OnDestroy();

private:
    friend class WindowClassRegistrar;

    static LRESULT CALLBACK WndProc(HWND const window,
    UINT const message,
            WPARAM const wparam,
    LPARAM const lparam) noexcept;

    static Win32Window* GetThisFromHandle(HWND const window) noexcept;
    static void UpdateTheme(HWND const window);

    bool quit_on_close_ = false;
    HWND window_handle_ = nullptr;
    HWND child_content_ = nullptr;

    // IME state structure
    struct {
        int x = 0;
        int y = 0;
        int width = 0;
        int height = 0;
    } ime_state_;

    // 快捷窗口相关的静态成员
    static HWND quick_window_handle_;
};

#endif  // RUNNER_WIN32_WINDOW_H_