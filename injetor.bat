@echo off
setlocal enabledelayedexpansion

title Roblox Executor - Injetor DLL
color 0A

echo.
echo ========================================
echo    ROBLOX EXECUTOR - INJETOR
echo    (Educacional - DLL Injection)
echo ========================================
echo.

REM Detectar se Roblox esta rodando
tasklist /FI "IMAGENAME eq RobloxPlayerBeta.exe" 2>NUL | find /I /N "RobloxPlayerBeta.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [+] Roblox detectado!
    for /f "tokens=2" %%A in ('tasklist /FI "IMAGENAME eq RobloxPlayerBeta.exe" ^| findstr "RobloxPlayerBeta.exe"') do (
        set PID=%%A
    )
    echo [+] PID: !PID!
) else (
    echo [-] Roblox nao detectado. Abra Roblox primeiro.
    pause
    exit /b
)

REM Criar DLL injetor em C#
echo [*] Compilando injetor DLL...

set "CSHARP_CODE=%TEMP%\injector.cs"
set "DLL_OUTPUT=%TEMP%\RobloxExecutor.dll"

(
echo using System;
echo using System.Diagnostics;
echo using System.Runtime.InteropServices;
echo.
echo public class DLLInjector {
echo     [DllImport("kernel32.dll", SetLastError = true)]
echo     private static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId^);
echo.
echo     [DllImport("kernel32.dll", SetLastError = true)]
echo     private static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect^);
echo.
echo     [DllImport("kernel32.dll", SetLastError = true)]
echo     private static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten^);
echo.
echo     [DllImport("kernel32.dll", SetLastError = true)]
echo     private static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId^);
echo.
echo     [DllImport("kernel32.dll"^)]
echo     private static extern IntPtr GetModuleHandle(string lpModuleName^);
echo.
echo     [DllImport("kernel32.dll"^)]
echo     private static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName^);
echo.
echo     private const int PROCESS_ALL_ACCESS = 0x1F0FFF;
echo     private const uint MEM_COMMIT = 0x1000;
echo     private const uint MEM_RESERVE = 0x2000;
echo     private const uint PAGE_READWRITE = 0x04;
echo.
echo     public static void Inject(int processId, string dllPath^) {
echo         try {
echo             IntPtr hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, processId^);
echo             if (hProcess == IntPtr.Zero^) {
echo                 Console.WriteLine("[-] Falha ao abrir processo"^);
echo                 return;
echo             }
echo.
echo             IntPtr pDllPath = VirtualAllocEx(hProcess, IntPtr.Zero, (uint^)dllPath.Length, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE^);
echo             byte[] dllBytes = System.Text.Encoding.ASCII.GetBytes(dllPath^);
echo             WriteProcessMemory(hProcess, pDllPath, dllBytes, (uint^)dllBytes.Length, out UIntPtr bytesWritten^);
echo.
echo             IntPtr hLoadLib = GetProcAddress(GetModuleHandle("kernel32.dll"^), "LoadLibraryA"^);
echo             CreateRemoteThread(hProcess, IntPtr.Zero, 0, hLoadLib, pDllPath, 0, out uint threadId^);
echo.
echo             Console.WriteLine("[+] DLL injetada com sucesso!"^);
echo         } catch (Exception ex^) {
echo             Console.WriteLine("[-] Erro: " + ex.Message^);
echo         }
echo     }
echo }
) > "%CSHARP_CODE%"

csc.exe /out:"%DLL_OUTPUT:.dll=.exe%" "%CSHARP_CODE%" 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo [-] Erro ao compilar. Certifique-se que .NET Framework esta instalado.
    echo [*] Usando metodo alternativo com PowerShell...
    call :PSInjection
) else (
    echo [+] Injetor compilado!
    "%DLL_OUTPUT:.dll=.exe%" !PID!
)

pause
exit /b

:PSInjection
echo [*] Usando PowerShell para injecao...

set "PS_SCRIPT=%TEMP%\inject.ps1"

(
echo Add-Type -TypeDefinition @"
echo using System;
echo using System.Diagnostics;
echo using System.Runtime.InteropServices;
echo public class Injector {
echo     [DllImport("kernel32.dll")] private static extern IntPtr OpenProcess(int a, bool b, int c);
echo     [DllImport("kernel32.dll")] private static extern IntPtr VirtualAllocEx(IntPtr a, IntPtr b, uint c, uint d, uint e);
echo     [DllImport("kernel32.dll")] private static extern bool WriteProcessMemory(IntPtr a, IntPtr b, byte[] c, uint d, out UIntPtr e);
echo     [DllImport("kernel32.dll")] private static extern IntPtr CreateRemoteThread(IntPtr a, IntPtr b, uint c, IntPtr d, IntPtr e, uint f, out uint g);
echo     [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string a);
echo     [DllImport("kernel32.dll")] private static extern IntPtr GetProcAddress(IntPtr a, string b);
echo     public static void Go(int p, string d) { IntPtr h=OpenProcess(0x1F0FFF,false,p); IntPtr m=VirtualAllocEx(h,IntPtr.Zero,(uint)d.Length,0x3000,4); WriteProcessMemory(h,m,System.Text.Encoding.ASCII.GetBytes(d),(uint)d.Length,out _); CreateRemoteThread(h,IntPtr.Zero,0,GetProcAddress(GetModuleHandle("kernel32.dll"),"LoadLibraryA"),m,0,out _); }
echo }
echo "@
echo [Injector]::Go(%1, $args[0])
) > "%PS_SCRIPT%"

powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "RobloxExecutor.dll"
exit /b
