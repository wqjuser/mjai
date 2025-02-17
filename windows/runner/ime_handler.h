// windows/flutter/ime_handler.h
#ifndef IME_HANDLER_H_
#define IME_HANDLER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include "win32_window.h"

class ImeHandler {
public:
    ImeHandler(flutter::BinaryMessenger* messenger, Win32Window* window);
    ~ImeHandler() = default;

private:
    void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
    Win32Window* window_;
};

#endif  // IME_HANDLER_H_