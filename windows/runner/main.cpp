#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <dbghelp.h>
#include <string>

#include "flutter_window.h"
#include "utils.h"

static LONG WINAPI MusiclyUnhandledExceptionFilter(EXCEPTION_POINTERS* info) {
  wchar_t temp_path[MAX_PATH];
  DWORD len = GetTempPathW(MAX_PATH, temp_path);
  if (len == 0 || len > MAX_PATH) {
    return EXCEPTION_CONTINUE_SEARCH;
  }

  SYSTEMTIME st;
  GetLocalTime(&st);
  wchar_t file_name[MAX_PATH];
  swprintf_s(file_name, L"%sMusicly_crash_%04d%02d%02d_%02d%02d%02d.dmp",
             temp_path, st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute,
             st.wSecond);

  HANDLE hFile = CreateFileW(file_name, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                             FILE_ATTRIBUTE_NORMAL, nullptr);
  if (hFile == INVALID_HANDLE_VALUE) {
    return EXCEPTION_CONTINUE_SEARCH;
  }

  const std::wstring dump_path(file_name);
  const std::wstring txt_path = dump_path + L".txt";

  {
    HANDLE hTxt = CreateFileW(txt_path.c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hTxt != INVALID_HANDLE_VALUE) {
      wchar_t buffer[512];
      const DWORD code = info && info->ExceptionRecord
                             ? info->ExceptionRecord->ExceptionCode
                             : 0;
      const void* address = info && info->ExceptionRecord
                                ? info->ExceptionRecord->ExceptionAddress
                                : nullptr;
      swprintf_s(buffer,
                 L"Musicly native crash\r\n"
                 L"exception_code: 0x%08X\r\n"
                 L"exception_address: 0x%p\r\n"
                 L"dump: %s\r\n",
                 code, address, dump_path.c_str());
      DWORD bytes_written = 0;
      WriteFile(hTxt, buffer,
                static_cast<DWORD>(wcslen(buffer) * sizeof(wchar_t)),
                &bytes_written, nullptr);
      CloseHandle(hTxt);
    }
  }

  MINIDUMP_EXCEPTION_INFORMATION mei;
  mei.ThreadId = GetCurrentThreadId();
  mei.ExceptionPointers = info;
  mei.ClientPointers = FALSE;

  MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), hFile,
                    MiniDumpNormal, &mei, nullptr, nullptr);
  CloseHandle(hFile);

  return EXCEPTION_EXECUTE_HANDLER;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX |
               SEM_NOOPENFILEERRORBOX);
  SetUnhandledExceptionFilter(MusiclyUnhandledExceptionFilter);

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Musicly", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
