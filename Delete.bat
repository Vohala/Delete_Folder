:: Point this to where your name folders live.
set "TARGET_DIR=D:\Blackbox"

echo Enter current date in dd-mm-yyyy format (e.g. 05-02-2025):
set /p "CURDATE=Current date: "

:: --- Use PowerShell to compute cutoff date (current date - 2 days)
powershell -NoProfile -Command ^
  "$refDate = [datetime]::ParseExact('%CURDATE%', 'dd-MM-yyyy', $null);" ^
  "$cutoff  = $refDate.AddDays(-1);" ^
  "$cutoff.ToString('yyyyMMdd')" > "%temp%\cutoff_date.txt"

if errorlevel 1 (
    echo [ERROR] Could not parse the date. Check dd-mm-yyyy format.
    pause
    exit /b 1
)

set /p "CUTOFF_YYYYMMDD=" < "%temp%\cutoff_date.txt"
del "%temp%\cutoff_date.txt" >nul 1>nul

echo [INFO] Cutoff date (current date - 2 days): %CUTOFF_YYYYMMDD%
echo.

pushd "%TARGET_DIR%" || (
    echo [ERROR] Cannot access folder: %TARGET_DIR%
    pause
    exit /b 1
)

setlocal enabledelayedexpansion

:: Loop through each name folder
for /d %%N in (*) do (
    pushd "%%N"
    echo Processing name folder: %%N

    :: Loop through date subfolders within the name folder
    for /d %%F in (*) do (
        for /f "tokens=1-3 delims=-" %%a in ("%%~F") do (
            set "DD=%%a"
            set "MM=%%b"
            set "YYYY=%%c"
        )

        if "!YYYY!"=="" (
            echo [SKIP] "%%N\%%F" does not match dd-mm-yyyy.
            set "DD=" & set "MM=" & set "YYYY="
            goto NextDateFolder
        )

        set "FOLDER_YYYYMMDD=!YYYY!!MM!!DD!"

        if "!FOLDER_YYYYMMDD!" LSS "%CUTOFF_YYYYMMDD%" (
            echo [DELETE] "%%N\%%F" is older than cutoff. Deleting...
            rd /s /q "%%F"
        ) else (
            echo [KEEP]   "%%N\%%F" is >= cutoff.
        )

        :NextDateFolder
        set "DD=" & set "MM=" & set "YYYY="
    )
    popd
)

popd
endlocal
echo.
echo [DONE] Operation complete!
pause
exit /b 0
