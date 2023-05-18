@echo off
chcp 65001
title wgcloudAgent安装
(cd/d "%~dp0")&(cacls "%SystemDrive%\System Volume Information" >nul 2>&1)||(start "" mshta vbscript:CreateObject^("Shell.Application"^).ShellExecute^("%~snx0"," %*","","runas",1^)^(window.close^)&exit /b)
:: 解析命令行参数以获取设置信息
set "url=%~1"
set "installDir=%~2"
set "alias=%~3"
set "token=%~4"
set "version=3.4.7"
:: 这里填写token的md5值
set "jktoken=token_md5"
:: 检查是否提供了必要的参数
if not defined url (
    echo URL parameter is missing. Aborting.
    echo installAgent.bat URL installDIR bindIP token
    exit /b 1
)

if not defined installDir (
    echo Install directory parameter is missing. Aborting.
    echo installAgent.bat URL installDIR bindIP token
    exit /b 1
)

if not defined alias (
    echo Alias parameter is missing. Aborting.
    echo installAgent.bat URL installDIR bindIP token
    exit /b 1
)
if not defined token (
    echo Token parameter is missing. Aborting.
    echo installAgent.bat URL installDIR bindIP token
    exit /b 1
)
:: agent安装目录可能不存在
if not exist "%installDir%" (
    md "%installDir%"
)

:: 构建下载压缩包所需的文件路径和 URL
set "tempDir=%TEMP%\wggcloudAgent_%TIME::=%"
set "zipFile=%tempDir%\wgcloudAgent.zip"
set "downloadUrl=%url%/resources/agent/agent-win64-v%version%.zip"

:: 下载压缩包并解压到指定目录
if not exist "%tempDir%" md "%tempDir%"
powershell -Command "Invoke-WebRequest '%downloadUrl%' -OutFile '%zipFile%'"
powershell -Command "Expand-Archive '%zipFile%' -DestinationPath '%tempDir%'"
xcopy /y /E /I "%tempDir%\agent-win64-v%version%\*" "%installDir%"

:: 逐项修改配置文件中的内容
set "configFile=%installDir%\config\application.properties"
echo "修改config\application.properties的配置项------"
echo serverUrl=%url% >"%configFile%"
echo bindIp=%alias% >>"%configFile%"
echo wgToken=%token% >>"%configFile%"
echo submitSeconds=120 >>"%configFile%"
echo hostAttachSeconds=300 >>"%configFile%"
echo smartOn=no >>"%configFile%"
echo shellToRun=yes >>"%configFile%"
echo logDays=30 >>"%configFile%"
echo logCheckSeconds=600 >>"%configFile%"
echo customDataSeconds=600 >>"%configFile%"
echo netInterface= >>"%configFile%"

cd %installDir%
:: 创建服务并启动
.\nssm.exe install wgcloudAgent "%installDir%\wgcloud-agent-release.exe"
echo "Agent registration service completed. "
echo "Please view the service [wgcloudAgent] in the system service and start it"
ping -n 3 127.0.0.1 > nul
net start wgcloudAgent

if %errorlevel% equ 0 (
    set "msg=%alias%:successful!"
    echo %msg%
    :: 删除临时文件
    rd /s /q "%tempDir%"
) else (
    set "msg=%alias%:failed!"
    echo %msg%
    :: 删除临时文件
    rd /s /q "%tempDir%"
)
:: 构造包含信息的 JSON 数据
set "json={\"wgToken\": \"%jktoken%\", \"title\": \"来自%alias%的agent安装信息\",\"content\":\"%msg%\"}"
:: 调用接口通知安装失败
powershell -Command "(New-Object System.Net.WebClient).UploadString('%url%/systemInfoOpen/commonWarnHandle', '%json%')"
echo "agent服务名：wgcloudAgent"
