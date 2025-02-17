#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"
#include <flutter/binary_messenger.h>

// 前向声明 ImeHandler
class ImeHandler;

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
public:
    // Creates a new FlutterWindow hosting a Flutter view running |project|.
    explicit FlutterWindow(const flutter::DartProject &project);

    virtual ~FlutterWindow();

    flutter::BinaryMessenger *GetBinaryMessenger() {
        return flutter_controller_->engine()->messenger();
    }

protected:
    // Win32Window:
    bool OnCreate() override;

    void OnDestroy() override;

    LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                           LPARAM const lparam) noexcept override;

private:
    // The project to run.
    flutter::DartProject project_;

    // The Flutter instance hosted by this window.
    std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

    // IME handler instance
    std::unique_ptr<ImeHandler> ime_handler_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_