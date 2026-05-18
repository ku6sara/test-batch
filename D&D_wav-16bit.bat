@echo off
rem 文字コードをUTF-8に設定
chcp 65001 >nul

rem 1. バッチファイルのある場所に移動
set "BASE_DIR=%~dp0"
set "BIN_DIR=%BASE_DIR%bin"
cd /d "%BASE_DIR%"

echo 起動中...

rem 2. binフォルダ内の ffmpeg.exe の存在チェック
if not exist "%BIN_DIR%\ffmpeg.exe" (
    echo [ERROR] %BIN_DIR%\ffmpeg.exe が見つかりません！
    echo bin フォルダの中に "ffmpeg.exe" を配置してください。
    pause
    exit /b
)

rem 3. ドラッグされたファイルがあるかチェック
if "%~1"=="" (
    echo [INFO] ファイルがドラッグ＆ドロップされていません。
    echo 変換したいmp4ファイルをこのバッチに重ねてください。
    pause
    exit /b
)

:loop
if "%~1"=="" goto end

echo ---------------------------------------------------
echo 処理中: "%~nx1"

rem 4. ffmpeg 実行 (binフォルダ内のffmpegを指定)
rem -y : 同名ファイルがあれば上書き
rem -vn: 映像なし
rem -c:a pcm_s16le: 16bit指定
rem -ar 44100: サンプリングレート(ここをお好みで変更)
"%BIN_DIR%\ffmpeg.exe" -i "%~1" -vn -c:a pcm_s16le -ar 44100 -y "%~dpn1.wav"

if %errorlevel% neq 0 (
    echo [ERROR] 変換に失敗しました: "%~nx1"
)

shift
goto loop

:end
echo ---------------------------------------------------
echo すべての処理が完了しました。
pause
exit