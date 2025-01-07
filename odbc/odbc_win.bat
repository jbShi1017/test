@echo on

set ODBC_BRANCH=%1
set SERVER_VERSION=%2
set WORK_DIR=E:\jbshi\odbc_auto_test

set "dotCount=0"
for %%i in (%SERVER_VERSION:.= %) do set /A dotCount+=1
if %dotCount% geq 2 (
    for /F "tokens=1,2 delims=." %%i in ("%SERVER_VERSION%") do (
        set "SERVER_VERSION_SPLIT=%%i.%%j"
    )
) else (
    set "SERVER_VERSION_SPLIT=%SERVER_VERSION%"
)

::准备测试目录
if exist %WORK_DIR%\workdir (rd /s /q %WORK_DIR%\workdir)
mkdir %WORK_DIR%\workdir %WORK_DIR%\workdir\single\web %WORK_DIR%\workdir\single\tzdb
::准备server
if exist %WORK_DIR%\..\prepare\server\%SERVER_VERSION% (
    xcopy /s /y %WORK_DIR%\..\prepare\server\%SERVER_VERSION% %WORK_DIR%\workdir\single
) else (
    for %%i in (dolphindb.exe libDolphinDB.dll libeay32.dll libgcc_s_seh-1.dll libstdc++-6.dll libtcmalloc_minimal-4.dll libwinpthread-1.dll ssleay32.dll libclucene-contribs-lib.dll libclucene-core.dll libclucene-shared.dll) do (
         curl "ftp://ftp.dolphindb.cn/origin/release%SERVER_VERSION%/Release/ALL/WIN/cmake_release_all/%%i" --user "ftpuser:DolphinDB123" -o %WORK_DIR%\workdir\single\%%i
    )
    curl "ftp://ftp.dolphindb.cn/origin/release%SERVER_VERSION_SPLIT%/dolphindb.dos" --user "ftpuser:DolphinDB123" -o %WORK_DIR%\workdir\single\dolphindb.dos
)
xcopy /s /y %WORK_DIR%\..\prepare\server\tzdb %WORK_DIR%\workdir\single\tzdb
xcopy /s /y %WORK_DIR%\..\prepare\server\web %WORK_DIR%\workdir\single\web
xcopy /s /y %WORK_DIR%\..\prepare\odbc\config\single %WORK_DIR%\workdir\single
curl "ftp://ftp.dolphindb.cn/License/internal/dolphindb.lic" --user "ftpuser:DolphinDB123" -o %WORK_DIR%\workdir\single\dolphindb.lic
::启动server
cd %WORK_DIR%\workdir\single && .\backgroundSingle.vbs
::拉取代码
git clone -b %ODBC_BRANCH% https://jianbo.shi%%40dolphindb.com:%%21s1017539527@dolphindb.net/dolphindb/dolphindb-odbc.git %WORK_DIR%\workdir\codes
::获取lib
curl "ftp://ftp.dolphindb.cn/origin/%ODBC_BRANCH%/Release/dolphindb-odbc/Windows/ddbodbc.dll" --user "ftpuser:DolphinDB123" -o %WORK_DIR%\workdir\ddbodbc.dll
::修改配置
odbcconf /A  {INSTALLDRIVER "DolphinDBDriver|Driver=%WORK_DIR%\workdir\ddbodbc.dll|Setup=%WORK_DIR%\workdir\ddbodbc.dll"}
odbcconf /A {CONFIGSYSDSN "DolphinDBDriver" "DSN=dolphindb|SERVER=192.168.100.4|PORT=35998|UID=admin|PWD=123456|DATABASE=dfs://testdb"}
::编译
mkdir %WORK_DIR%\workdir\codes\build
cd %WORK_DIR%\workdir\codes\build && cmake .. -G "Visual Studio 17 2022" -A x64 -DRUN_GTEST=ON -DBUILD_ONLY_GTEST=ON -DCMAKE_CONFIGURATION_TYPES="Release" -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=TRUE && cmake --build . --config Release
cd %WORK_DIR%\workdir\codes\build\Release && .\BasicTest.exe --gtest_output=xml:output.xml
call %WORK_DIR%\..\kill.bat 35998
copy /y %WORK_DIR%\workdir\codes\build\Release\output.xml %WORK_DIR%\workdir\output.xml
copy /y %WORK_DIR%\..\prepare\odbc\gtest.xsl %WORK_DIR%\workdir\gtest.xsl
copy /y %WORK_DIR%\..\prepare\odbc\report.py %WORK_DIR%\workdir\report.py
cd %WORK_DIR%\workdir && E:\Miniconda\envs\python312\python.exe .\report.py
