#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <desktop_multi_window/desktop_multi_window_plugin.h>

namespace {

// Turn a sub-window into a frameless, always-on-top desktop widget that is
// hidden from the taskbar. (Dragging is initiated from Dart via a WM_NCLBUTTON-
// DOWN/HTCAPTION message — the Flutter content sits in a child window, so a
// top-level WM_NCHITTEST hook would never see the clicks.)
void StyleAsWidget(HWND hwnd) {
  if (!hwnd) return;
  LONG style = GetWindowLong(hwnd, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
  style |= WS_POPUP;
  SetWindowLong(hwnd, GWL_STYLE, style);

  // WS_EX_TOOLWINDOW keeps the widget out of the taskbar and Alt-Tab.
  LONG ex = GetWindowLong(hwnd, GWL_EXSTYLE);
  ex |= WS_EX_TOOLWINDOW;
  ex &= ~WS_EX_APPWINDOW;
  SetWindowLong(hwnd, GWL_EXSTYLE, ex);

  SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Register callback for desktop_multi_window plugin. Sub-windows are
  // lightweight floating widgets: register ONLY desktop_multi_window for them
  // (NOT the full plugin set) — registering window_manager / tray_manager
  // across multiple engines corrupts their shared native state and crashes the
  // app when the main window is closed. Then style the sub-window natively as a
  // frameless, always-on-top, draggable widget.
  DesktopMultiWindowSetWindowCreatedCallback(
      [](void *flutter_view_controller) {
        auto controller =
            reinterpret_cast<flutter::FlutterViewController *>(flutter_view_controller);
        DesktopMultiWindowPluginRegisterWithRegistrar(
            controller->engine()->GetRegistrarForPlugin("DesktopMultiWindowPlugin"));
        StyleAsWidget(GetAncestor(controller->view()->GetNativeWindow(), GA_ROOT));
      });

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
