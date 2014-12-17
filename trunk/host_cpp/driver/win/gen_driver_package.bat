:: get current date 
    @ECHO off
    SETLOCAL ENABLEEXTENSIONS
    if "%date%A" LSS "A" (set toks=1-3) else (set toks=2-4)
    for /f "tokens=2-4 delims=(-)" %%a in ('echo:^|date') do (
      for /f "tokens=%toks% delims=.-/ " %%i in ('date/t') do (
        set '%%a'=%%i
        set '%%b'=%%j
        set '%%c'=%%k))
    if %'yy'% LSS 100 set 'yy'=20%'yy'%
    set Today=%'yy'%-%'mm'%-%'dd'% 
    ENDLOCAL & SET year=%'yy'%& SET month=%'mm'%& SET day=%'dd'%

:: set date & version string in inf file
%WINDDK7%\bin\x86\stampinf -f silabusb.inf -d %Month%/%Day%/%Year% -v 2.0.1.7

:: generate catalog file(s)
%WINDDK7%\bin\selfsign\Inf2cat.exe /driver:. /os:7_X64,7_X86,XP_X86,XP_X64



PAUSE