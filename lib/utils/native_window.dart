import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Minimal Win32 bindings to drag a frameless window. window_manager can't be
// used in a widget sub-window (it corrupts shared native state across engines),
// so we replicate its `startDragging` trick directly: release the mouse capture
// and post WM_NCLBUTTONDOWN/HTCAPTION to the foreground (widget) window, which
// puts Windows into its normal window-move loop.

typedef _GetForegroundWindowNative = IntPtr Function();
typedef _GetForegroundWindowDart = int Function();

typedef _ReleaseCaptureNative = Int32 Function();
typedef _ReleaseCaptureDart = int Function();

typedef _SendMessageNative = IntPtr Function(
    IntPtr hWnd, Uint32 msg, IntPtr wParam, IntPtr lParam);
typedef _SendMessageDart = int Function(
    int hWnd, int msg, int wParam, int lParam);

typedef _FindWindowNative = IntPtr Function(
    Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef _FindWindowDart = int Function(
    Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef _ShowWindowNative = Int32 Function(IntPtr hWnd, Int32 nCmdShow);
typedef _ShowWindowDart = int Function(int hWnd, int nCmdShow);

final class _Rect extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

typedef _GetWindowRectNative = Int32 Function(IntPtr hWnd, Pointer<_Rect> rect);
typedef _GetWindowRectDart = int Function(int hWnd, Pointer<_Rect> rect);

typedef _SetWindowPosNative = Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter,
    Int32 x, Int32 y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef _SetWindowPosDart = int Function(int hWnd, int hWndInsertAfter, int x,
    int y, int cx, int cy, int uFlags);

const int _wmNcLButtonDown = 0x00A1;
const int _htCaption = 2;
const int _swHide = 0;
const int _swpNoMove = 0x0002;
const int _swpNoZOrder = 0x0004;
const int _swpNoActivate = 0x0010;

final DynamicLibrary? _user32 =
    Platform.isWindows ? DynamicLibrary.open('user32.dll') : null;

final _getForegroundWindow = _user32
    ?.lookupFunction<_GetForegroundWindowNative, _GetForegroundWindowDart>(
        'GetForegroundWindow');
final _releaseCapture = _user32
    ?.lookupFunction<_ReleaseCaptureNative, _ReleaseCaptureDart>(
        'ReleaseCapture');
final _sendMessage =
    _user32?.lookupFunction<_SendMessageNative, _SendMessageDart>('SendMessageW');
final _findWindow =
    _user32?.lookupFunction<_FindWindowNative, _FindWindowDart>('FindWindowW');
final _showWindow =
    _user32?.lookupFunction<_ShowWindowNative, _ShowWindowDart>('ShowWindow');
final _getWindowRect = _user32
    ?.lookupFunction<_GetWindowRectNative, _GetWindowRectDart>('GetWindowRect');
final _setWindowPos = _user32
    ?.lookupFunction<_SetWindowPosNative, _SetWindowPosDart>('SetWindowPos');

/// Begin dragging the current (foreground) frameless window. No-op off Windows.
void startWindowDrag() {
  if (!Platform.isWindows) return;
  final hwnd = _getForegroundWindow?.call() ?? 0;
  if (hwnd == 0) return;
  _releaseCapture?.call();
  _sendMessage?.call(hwnd, _wmNcLButtonDown, _htCaption, 0);
}

/// Hide (not destroy) the widget window whose OS window title equals
/// [titleToken]. Returns true if a matching window was found and hidden.
///
/// Each widget window is tagged (by the main window, via `setTitle`) with a
/// unique token like `cdtwidget_<windowId>`; the title is invisible because the
/// window is frameless and kept off the taskbar. We look the window up by that
/// exact token and `ShowWindow(SW_HIDE)` it.
///
/// Why HIDE instead of close/destroy: destroying a sub-window's Flutter engine
/// in desktop_multi_window 0.2.1 leaves its render threads spinning (CPU pegs at
/// several cores) and can take the whole app down. Hiding keeps the engine alive
/// and stable; the main window re-`show()`s the same window when the user
/// reopens the timer. Windows are only truly destroyed on process exit.
///
/// Why by title token and not `GetForegroundWindow`: right after creating a
/// timer the *main* window can still be foreground, so acting on "the foreground
/// window" could hide the main window instead of the widget.
bool hideWidgetWindow(String titleToken) {
  if (!Platform.isWindows) return false;
  final titlePtr = titleToken.toNativeUtf16();
  try {
    final hwnd = _findWindow?.call(nullptr, titlePtr) ?? 0;
    if (hwnd == 0) return false;
    _showWindow?.call(hwnd, _swHide);
    return true;
  } finally {
    malloc.free(titlePtr);
  }
}

/// Physical-pixel size of the widget window tagged [titleToken], or null off
/// Windows / on failure. Used as the anchor when a resize drag starts. We look
/// the window up by its unique token rather than using `GetForegroundWindow`:
/// the widget is not always foreground during its own grip drag, and resizing
/// the wrong window (e.g. the main window, which shares this UI thread) crashes
/// the app.
({int width, int height})? widgetWindowSize(String titleToken) {
  if (!Platform.isWindows) return null;
  final titlePtr = titleToken.toNativeUtf16();
  try {
    final hwnd = _findWindow?.call(nullptr, titlePtr) ?? 0;
    if (hwnd == 0) return null;
    final rect = calloc<_Rect>();
    try {
      if ((_getWindowRect?.call(hwnd, rect) ?? 0) == 0) return null;
      return (
        width: rect.ref.right - rect.ref.left,
        height: rect.ref.bottom - rect.ref.top,
      );
    } finally {
      calloc.free(rect);
    }
  } finally {
    malloc.free(titlePtr);
  }
}

/// Resize the widget window tagged [titleToken] to [width]x[height] physical
/// pixels, keeping its top-left corner and z-order (stays topmost). Targets the
/// exact widget by token (never the foreground window). SetWindowPos resizes any
/// window regardless of style, so the window stays frameless. No-op off Windows.
///
/// Call this OFF the gesture/build stack (e.g. from a throttling timer), never
/// directly inside `onPanUpdate`: SetWindowPos delivers WM_SIZE synchronously,
/// and resizing the engine's own window while it is mid-pointer-event re-enters
/// the renderer and can white-out / crash the widget.
void resizeWidgetWindow(String titleToken, int width, int height) {
  if (!Platform.isWindows) return;
  final titlePtr = titleToken.toNativeUtf16();
  try {
    final hwnd = _findWindow?.call(nullptr, titlePtr) ?? 0;
    if (hwnd == 0) return;
    _setWindowPos?.call(
        hwnd, 0, 0, 0, width, height, _swpNoMove | _swpNoZOrder | _swpNoActivate);
  } finally {
    malloc.free(titlePtr);
  }
}
