@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
:: --- 設定エリア ---
:: 先ほどの構成に合わせて bin フォルダのパスを設定
set "BASE_DIR=%~dp0"
set "BIN_DIR=%BASE_DIR%bin"

:: ターゲットサイズ（9.5MB狙い / 単位: kbits）
set "TARGET_KB=76000"

echo ==================================================
echo      動画を圧縮するよ（進捗表示モード）
echo ==================================================

if "%~1" == "" (
    echo.
    echo 【使い方】
    echo 圧縮したい動画をこのバッチファイルアイコンにドラッグアンドドロップしてね。
    echo.
    pause
    exit
)

:drag_loop
if "%~1" == "" goto :finish
call :process "%~1"
shift
goto :drag_loop

:finish
echo.
echo --------------------------------------------------
echo すべての処理が終了しました。
pause
exit

:process
set "FULL_PATH=%~1"
set "DEST_DIR=%~dp1"
set "FILE_NAME=%~n1"
set "FILE_EXT=%~x1"

if /i not "!FILE_EXT!"==".mp4" (
    echo [スキップ] .mp4 以外のファイルです: %~nx1
    exit /b
)

echo.
echo --------------------------------------------------
echo 処理中: %~nx1

:: 1. 動画の総再生時間を秒単位で取得 (binフォルダのffprobeを指定)
set "DURATION=0"
for /f "usebackq" %%A in (`powershell -ExecutionPolicy Bypass -command "& { (& '%BIN_DIR%\ffprobe.exe' -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 '%FULL_PATH%') }"`) do set "DURATION=%%A"

:: 2. ビットレート計算
for /f "usebackq" %%A in (`powershell -ExecutionPolicy Bypass -command "& { if (%DURATION% -gt 0) { $v = [math]::Floor(%TARGET_KB% / %DURATION%) - 64; if ($v -lt 100) { 100 } else { $v } } else { 800 } }"`) do set "V_BITRATE=%%A"

:: 3. 解像度の決定
set "SCALE_W=1920"
if !V_BITRATE! LSS 2000 set "SCALE_W=1280"
if !V_BITRATE! LSS 800 set "SCALE_W=854"

echo       - 推定ビットレート: !V_BITRATE!k
echo       - リサイズ幅      : !SCALE_W!px

REM 4. 進捗表示をしながらのエンコード実行 (binフォルダのffmpegを指定)
"%BIN_DIR%\ffmpeg.exe" -y -i "%FULL_PATH%" ^
    -vf "scale=!SCALE_W!:-2" ^
    -c:v h264_nvenc -b:v !V_BITRATE!k -maxrate !V_BITRATE!k -bufsize !V_BITRATE!k ^
    -c:a aac -b:a 64k -ar 16000 -ac 1 ^
    "!DEST_DIR!!FILE_NAME!_圧縮.mp4" 2>&1 | powershell -ExecutionPolicy Bypass -command "$dur=[double]'%DURATION%'; if($dur -le 0){$dur=1}; $input | ForEach-Object { $l=$_.TrimEnd(); if($l -match 'frame=\s*\d+') { $pct=0; if($l -match 'time=(\d+):(\d+):(\d+\.\d+)') { $curr=[int]$matches[1]*3600+[int]$matches[2]*60+[double]$matches[3]; $pct=[math]::Min(99, [math]::Floor(($curr/$dur)*100)) }; Write-Host (\"`r[$pct%%] $l   \") -NoNewline } else { Write-Host $l } }; Write-Host \"`n[100%%] 完了！      \""

if exist "!DEST_DIR!!FILE_NAME!_圧縮.mp4" (
    echo.
    echo [完了] 出力先: "!DEST_DIR!!FILE_NAME!_圧縮.mp4"
) else (
    echo.
    echo [エラー] 失敗しました: %~nx1
)
exit /b
