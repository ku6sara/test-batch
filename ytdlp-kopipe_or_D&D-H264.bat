@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: --- フォルダのパス設定 ---
set "BASE_DIR=%~dp0"
set "BIN_DIR=%BASE_DIR%bin"
set "ASSETS_DIR=%BASE_DIR%assets"

:: assetsフォルダが存在しない場合は自動で作成する
if not exist "%ASSETS_DIR%" mkdir "%ASSETS_DIR%"

:: 保存先をバッチファイルのある場所に固定
cd /d "%BASE_DIR%"

:: 引数がある場合はループ処理へ、ない場合はクリップボードモードへ
if "%~1" == "" goto clipboard_mode

:loop
if "%~1" == "" goto end
set "TARGET=%~1"

:: --- URLかローカルファイルか判定 ---
echo !TARGET! | findstr /i "http" >nul
if !errorlevel! equ 0 (
    echo -------------------------------------------------------
    echo  [DLモード] 単品ダウンロードを実行します
    echo -------------------------------------------------------
    call :download_proc "!TARGET!"
) else if exist "!TARGET!" (
    echo -------------------------------------------------------
    echo  [変換モード] H.264へ変換します
    echo -------------------------------------------------------
    call :convert_proc "!TARGET!"
)

shift
goto loop

:: --- ダウンロード実行部 ---
:download_proc
:: 引数が空の場合は戻る
if "%~1"=="" exit /b

:: binフォルダ内のyt-dlpを呼び出し、保存先をassetsフォルダに指定
"%BIN_DIR%\yt-dlp.exe" ^
 --ffmpeg-location "%BIN_DIR%\ffmpeg.exe" ^
 --no-playlist ^
 --ignore-errors ^
 --no-warnings ^
 -f "bv*[vcodec^=avc]+ba[ext=m4a]/b[ext=mp4] / bv+ba/b" ^
 --merge-output-format mp4 ^
 --recode-video mp4 ^
 --yes-overwrites ^
 --concurrent-fragments 5 ^
 --embed-thumbnail ^
 --embed-metadata ^
 --parse-metadata "uploader:(?P<artist>.+)" ^
 -o "%ASSETS_DIR%\%%(title)s-[%%(id)s].%%(ext)s" ^
 "%~1"
exit /b

:: --- ローカル変換実行部 ---
:convert_proc
echo 変換中: %~n1
:: binフォルダ内のffmpegを呼び出す（変換ファイルは元ファイルと同じ場所に出力）
"%BIN_DIR%\ffmpeg.exe" -y -i "%~1" -c:v libx264 -crf 20 -preset slow -c:a copy "%~dpn1_h264.mp4"
echo 変換完了: %~n1_h264.mp4
exit /b

:: --- クリップボード取得モード ---
:clipboard_mode
echo -------------------------------------------------------
echo  [クリップボードモード] 
echo -------------------------------------------------------
echo クリップボードからURLをチェック中...

for /f "usebackq tokens=*" %%a in (`powershell -command "Get-Clipboard"`) do set "CLIP_URL=%%a"

echo "!CLIP_URL!" | findstr /i "http" >nul
if !errorlevel! equ 0 (
    call :download_proc "!CLIP_URL!"
    goto end
)

echo [!] クリップボードに有効なURLが見つかりませんでした。
:: 元のコードで抜けていたURL手動入力の処理を追加
set /p "USER_URL=動画のURLを貼り付けてください (未入力で終了): "

if "!USER_URL!"=="" (
    echo 入力されていないため終了します。
    goto end
)

call :download_proc "!USER_URL!"
goto end

:end
echo -------------------------------------------------------
echo すべて完了！
pause
exit /b
