\@echo off
setlocal enabledelayedexpansion

:: Initialize log file
set logFile=game_log.txt
echo Game Log > %logFile%
echo ==================== >> %logFile%

:StartPrompt
echo Press Enter to start the game...
set /p dummy=""

:MainMenu
echo Welcome to the D&D Adventure!
echo Developer: Leafii
echo Dedication: Unkva
echo.
echo 1. Create Account
echo 2. Load Account
echo 3. Start Game (No Account)
echo 4. Exit
set /p menuChoice="Choose an option (1-4): "

if "%menuChoice%"=="1" (call :CreateAccount)
if "%menuChoice%"=="2" (call :LoadAccount)
if "%menuChoice%"=="3" (call :StartGame)
if "%menuChoice%"=="4" exit /b

goto MainMenu

:CreateAccount
set /p username="Enter a username: "

:: Check for restricted usernames
if /i "%username%"=="Unkva" (
    set /p devCode="You got the game Unkva! Enter the dev code below: "
    if "%devCode%" NEQ "43526" (
        echo Access Denied. Cannot create account with that name.
        goto MainMenu
    )
)

if /i "%username%"=="DavHed" (
    set /p devCode="You got the game DavHed! Enter the dev code below: "
    if "%devCode%" NEQ "43526" (
        echo Access Denied. Cannot create account with that name.
        goto MainMenu
    )
)

set /p password="Enter a password: "
echo Username: %username%, Password: %password% > "%username%_account.txt"
echo Account created successfully!

:: Check if the username is "Leafii"
if /i "%username%"=="Leafii" (
    echo Woah! Unexpected. Are you a developer?
    set /p devCode="(Enter developer code here): "
    if "%devCode%"=="43526" (
        echo Access Granted. You are now in Developer Mode.
        set devMode=true
    ) else (
        echo Access Denied.
    )
)

goto MainMenu

:LoadAccount
set /p username="Enter your username: "
set /p password="Enter your password: "

:: Check if account file exists
if not exist "%username%_account.txt" (
    echo Account does not exist!
    set /p reset="Forgot your password? Type 'reset' to reset it, or anything else to return to main menu: "
    if /i "%reset%"=="reset" (
        call :ResetPassword
    ) else (
        goto MainMenu
    )
)

:: Verify password
for /f "tokens=2,3 delims=," %%a in ('type "%username%_account.txt"') do (
    if "%%b"=="%password%" (
        echo Password verified. Loading game...
        goto GameInit
    )
)

echo Incorrect password. Returning to main menu.
goto MainMenu

:ResetPassword
set /p username="Enter your username to reset the password: "
if not exist "%username%_account.txt" (
    echo Account does not exist! Returning to main menu.
    goto MainMenu
)

set /p newPassword="Enter your new password: "
for /f "tokens=1 delims=," %%a in ('type "%username%_account.txt"') do (
    echo %%a, Password: %newPassword% > "%username%_account.txt"
)
echo Password reset successfully!
goto MainMenu

:StartGame
echo You have chosen to start the game without an account.
set /p rewardCode="Enter code for a reward (or leave blank to skip): "

if "%rewardCode%"=="JoinedFromD&DDiscord" (
    echo Reward unlocked! Your code is: 53215
) else (
    echo No reward applied.
)

goto GameInit

:GameInit
echo You are starting the game.
set class=
set health=100
set experience=0
set godMode=false
set examining=false
set currentObject=

:CharacterSelection
echo Please choose your character class:
echo 1. Tech
echo 2. Explorer
echo 3. Excited
echo 4. DevLogIn
set /p classChoice="Choose your class (1-4): "

if "%classChoice%"=="1" (set class=Tech & set /a health=90 & set /a attackPower=20)
if "%classChoice%"=="2" (set class=Explorer & set /a health=100 & set /a attackPower=15)
if "%classChoice%"=="3" (set class=Excited & set /a health=80 & set /a attackPower=25)
if "%classChoice%"=="4" (
    call :DevLogIn
    if defined devMode (
        goto GameMode
    ) else (
        goto CharacterSelection
    )
)

:GameMode
echo You have chosen: !class!
echo Choose game mode:
echo 1. Violent
echo 2. Non-Violent
echo 3. Start Game with Account
set /p modeChoice="Choose your mode (1-3): "

if "%modeChoice%"=="3" (goto GameInitWithAccount)

:Quest
echo.
echo You can:
echo 1. Explore Forest
echo 2. Enter Cave
echo 3. Use Commands
echo 4. Save Game
echo 5. Return to Main Menu
set /p choice="Choose your action (1-5): "

if "%choice%"=="1" (call :ExploreForest)
if "%choice%"=="2" (call :EnterCave)
if "%choice%"=="3" (call :UseCommands)
if "%choice%"=="4" (call :SaveGame)
if "%choice%"=="5" (goto MainMenu)

:: Check for restart command
if "%choice%"=="r" (
    set /p dummy="Press Shift + R + S to restart and wipe data... "
    if "%dummy%"=="Shift + R + S" (
        echo WARNING: This will wipe any unsaved data. Do you want to continue? (Y/N)
        set /p confirm="Enter Y to confirm: "
        if /i "%confirm%"=="Y" (
            echo Restarting and wiping unsaved data...
            goto StartPrompt
        ) else (
            echo Restart canceled.
        )
    )
)

goto Quest

:SaveGame
set playerData=class=!class! health=!health! experience=!experience! godMode=!godMode!
echo !playerData! > "%username%_data.txt"
echo Game saved successfully!
goto Quest

:ExploreForest
echo You venture into the forest...
set /a encounter=!random! %% 2
if !encounter! == 0 (
    call :EnemyEncounter
) else (
    echo You found some treasure!
    set /a experience+=50
    call :LogAction "found treasure"
)

goto Quest

:EnterCave
echo You enter the cave...
set /a encounter=!random! %% 2
if !encounter! == 0 (
    echo You found a magical artifact!
    set /a experience+=100
    call :LogAction "found a magical artifact"
) else (
    call :EnemyEncounter
)

goto Quest

:UseCommands
set /p commandInput="Command Input: "
call :ProcessCommand "!commandInput!"
goto Quest

:ProcessCommand
set command=%1
if "%command%"=="/find" (
    echo Example usage: /find {food} [Meat]
) else if "%command%"=="/look" (
    echo Example usage: /look {toandfrom} [at] \object\
) else if "%command%"=="/logs" (
    type %logFile%
) else if "%command%"=="/viewcommands" (
    echo Available commands:
    echo /find {category} [item] - Find an item in a category
    echo /look {toandfrom} [at] \object\ - Examine an object/being
    echo /logs - View your action logs
    echo /GodModeEnable - Enable God Mode
    echo /GodModeDisable - Disable God Mode
) else if "%command%"=="/GodModeEnable" (
    if defined devMode (
        set godMode=true
        echo God Mode enabled!
        call :LogAction "enabled God Mode"
    ) else (
        echo You must be in Developer Mode to use this command.
    )
) else if "%command%"=="/GodModeDisable" (
    if defined devMode (
        set godMode=false
        echo God Mode disabled!
        call :LogAction "disabled God Mode"
    ) else (
        echo You must be in Developer Mode to use this command.
    )
) else (
    echo Invalid command.
)
goto Quest

:LogAction
set action=%1
for /f "tokens=*" %%a in ('echo %username%') do set user=%%a
echo (%user%) used %action% at %time% >> %logFile%
goto :eof

:EnemyEncounter
echo A goblin appears! Health: 30
set /a enemyHealth=30

:Combat
if defined godMode (
    echo You are in God Mode! Instakill activated!
    set /a damage=30
) else (
    if defined devMode (
        set /a damage=!attackPower! + 10
    ) else (
        set /a damage=!attackPower!
    )
)

set /a enemyHealth-=damage
echo You dealt !damage! damage! Goblin health is now !enemyHealth!.

if !enemyHealth! LEQ 0 (
    echo You defeated the goblin!
    set /a experience+=100
    call :LogAction "defeated a goblin"
    goto Quest
)

:: Enemy attacks back
set /a playerDamage=5
set /a health-=playerDamage
echo The goblin attacked you! You took !playerDamage! damage! Your health is now !health!.

if !health! LEQ 0 (
    echo You have perished. Game Over.
    exit /b
)

goto Combat

:GameInitWithAccount
echo Loading your saved game...
if exist "%username%_data.txt" (
    for /f "tokens=*" %%a in ('type "%username%_data.txt"') do (
        set "line=%%a"
        for /f "tokens=1,2 delims==" %%b in ("!line!") do (
            set %%b
        )
    )
    echo Game loaded. Class: !class!, Health: !health!, Experience: !experience!
) else (
    echo No saved game found. Starting a new game.
    goto CharacterSelection
)

goto Quest

:DevLogIn
set /p devCode="Enter developer code: "
echo You entered: [%devCode%]
if "%devCode%"=="43526" (
    echo Access Granted. You are now in Developer Mode.
    set devMode=true
) else (
    echo Access Denied.
)
goto CharacterSelection
