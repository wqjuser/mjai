// windows/flutter/ime_handler.cpp
#include "ime_handler.h"

ImeHandler::ImeHandler(flutter::BinaryMessenger* messenger, Win32Window* window)
        : window_(window) {
    channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            messenger, "ime_fix",
                    &flutter::StandardMethodCodec::GetInstance());

    channel_->SetMethodCallHandler(
            [this](const auto& call, auto result) {
                HandleMethodCall(call, std::move(result));
            });
}

void ImeHandler::HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue>& method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    if (method_call.method_name() == "updateImePosition") {
        if (!method_call.arguments()) {
            result->Error("Bad Arguments", "Argument map is null");
            return;
        }

        const auto* arguments =
                std::get_if<flutter::EncodableMap>(method_call.arguments());

        if (!arguments) {
            result->Error("Bad Arguments", "Arguments are not a map");
            return;
        }

        auto x_it = arguments->find(flutter::EncodableValue("x"));
        auto y_it = arguments->find(flutter::EncodableValue("y"));
        auto width_it = arguments->find(flutter::EncodableValue("width"));
        auto height_it = arguments->find(flutter::EncodableValue("height"));

        if (x_it == arguments->end() || y_it == arguments->end() ||
            width_it == arguments->end() || height_it == arguments->end()) {
            result->Error("Bad Arguments", "Missing required position arguments");
            return;
        }

        int x = static_cast<int>(std::get<double>(x_it->second));
        int y = static_cast<int>(std::get<double>(y_it->second));
        int width = static_cast<int>(std::get<double>(width_it->second));
        int height = static_cast<int>(std::get<double>(height_it->second));

        window_->UpdateImePosition(x, y, width, height);
        result->Success();
    } else {
        result->NotImplemented();
    }
}