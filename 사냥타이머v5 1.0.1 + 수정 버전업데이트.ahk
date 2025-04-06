; ft.ahk 포함 필요
#Include ft.ahk
#NoEnv
#SingleInstance, force
#Persistent
#HotKeyInterval 1
#MaxHotkeysPerInterval 127
DetectHiddenWindows, On
SetKeyDelay,-1, 1
SetControlDelay, -1
SetWinDelay,-1
SetBatchLines,-1
SetWorkingDir,%a_scriptdir%
PID := DllCall("GetCurrentProcessId")
Process, Priority, %PID%, High
huntStartDailyExp := 0  ; 사냥 시작 시점의 누적 경험치 저장용

; 최신 버전 확인 함수
CheckForUpdates() {
    global currentVersion, versionFileURL, scriptURL

    ; 현재 스크립트 버전 (수동으로 설정)
    currentVersion := "1.0.1"

    ; 버전 파일 다운로드
    versionFileURL := "https://pastes.io/raw/version-47"  ; 최신 버전 파일 URL
    scriptURL := "https://www.dropbox.com/scl/fi/82g4x54sm8g1xj0zsc35z/v5-1.0.1.ahk?rlkey=abfiv98dpp0ooi0mdsj0o8cdg&dl=0"  ; 최신 스크립트 URL

    ; 최신 버전 정보 가져오기
    latestVersion := GetLatestVersion(versionFileURL)

    ; 버전 비교
    if (CompareVersions(currentVersion, latestVersion) < 0) {
        MsgBox, 64, 업데이트 알림, 새로운 버전 %latestVersion%이(가) 출시되었습니다.`n업데이트를 진행합니다.
        DownloadAndUpdate(scriptURL)
    } else {
        MsgBox, 64, 업데이트 확인, 현재 버전 %currentVersion%는 최신 버전입니다.
    }
}

; 최신 버전 다운로드 함수
GetLatestVersion(url) {
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    try {
        WebRequest.Open("GET", url, false)
        WebRequest.Send()
        if (WebRequest.Status = 200)
            return WebRequest.ResponseText
        else
            return ""
    } catch e {
        return ""
    }
}

; 버전 비교 함수 (버전 형식: 1.0.0)
CompareVersions(v1, v2) {
    v1Parts := StrSplit(v1, ".")
    v2Parts := StrSplit(v2, ".")

    Loop, 3 {
        part1 := v1Parts[A_Index]
        part2 := v2Parts[A_Index]
        
        if (part1 > part2)
            return 1
        else if (part1 < part2)
            return -1
    }
    return 0
}

; 최신 스크립트 다운로드 및 교체 함수
DownloadAndUpdate(url) {
    ; 임시 파일로 최신 스크립트 다운로드
    tempFilePath := A_ScriptDir . "\new_script.ahk"
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    try {
        WebRequest.Open("GET", url, false)
        WebRequest.Send()
        if (WebRequest.Status = 200) {
            FileDelete, %tempFilePath%
            FileAppend, % WebRequest.ResponseText, %tempFilePath%
            ; 기존 스크립트 백업 후 새로운 스크립트로 교체
            BackupScript()
            FileMove, %tempFilePath%, %A_ScriptDir%\your_script.ahk, 1
            MsgBox, 64, 업데이트 완료, 스크립트가 최신 버전으로 업데이트되었습니다. 이제 다시 실행됩니다.
            Reload  ; 스크립트 재실행
        } else {
            MsgBox, 16, 다운로드 오류, 최신 버전을 다운로드할 수 없습니다.
        }
    } catch e {
        MsgBox, 16, 오류, 오류가 발생하여 최신 스크립트를 다운로드할 수 없습니다.
    }
}

; 기존 스크립트 백업
BackupScript() {
    backupPath := A_ScriptDir . "\backup\your_script_" . A_YYYY . A_MM . A_DD . ".ahk"
    FileCreateDir, % A_ScriptDir . "\backup"
    FileCopy, % A_ScriptDir . "\your_script.ahk", % backupPath, 1
}

; 스크립트 시작 시 업데이트 확인
CheckForUpdates()

; 같은 폴더에 있는 ft.ahk 파일 숨기기
filePath := A_ScriptDir . "\ft.ahk"
FileSetAttrib, +H, %filePath%

; 경험치 자동 상승 감지 추가 변수
lastDetectedEXP := 0

; 유저 정보 변수
username := A_UserName
computer := A_ComputerName

; 캐시 경로 정의
cachePath := A_AppData . "\..\Local\MapleAuth"
cacheFile := cachePath . "\auth_cache.ini"
dailyExpFile := cachePath . "\daily_exp.ini"
FileCreateDir, %cachePath%

; 배율 값 불러오기
IniRead, mult, %cacheFile%, Settings, mult, 2  ; 기본값은 2

; 배율 값 적용
UpdateScale(mult)

; 이전 경험치 불러오기
dailyExpTotal := 0
today := A_YYYY . "-" . A_MM . "-" . A_DD
checkDate := today  ; 자정 감지용 날짜 캐시

; 오늘 누적 경험치 불러오기
IniRead, readExp, %dailyExpFile%, DailyEXP, %today%, 0
dailyExpTotal := readExp + 0

; 날짜 관련 함수 정의 (위치 상단으로)
DateAdd(dateStr, days, unit := "Days") {
    EnvAdd, dateStr, % days, % unit
    return dateStr
}

ShowDailyExpLog() {
    global dailyExpFile
    log := "📅 최근 10일간 누적 경험치`n==============================="

    seen := {}  ; 중복 방지를 위한 Map
    Loop, 20 {
        dateObj := A_Now
        EnvAdd, dateObj, -%A_Index%+1, Days
        FormatTime, formattedDate, %dateObj%, yyyy-MM-dd

        ; 중복 방지
        if (seen.HasKey(formattedDate))
            continue
        seen[formattedDate] := true

        IniRead, value, %dailyExpFile%, DailyEXP, %formattedDate%, 0
        log .= "`n" . formattedDate . " = " . value

        ; 최대 10개만 출력
        if (seen.Count() >= 10)
            break
    }

    MsgBox, 64, 날짜별 누적 경험치, %log%
}

SendDiscordLog(msg) {
    webhookURL := "https://discord.com/api/webhooks/1357412343880876194/OZick3dcgy9JcuKbGAJ8JrsLcloJHq5kfWa6Qwp2hKExnqzOU6M_RCv1UGhZKWjLHd-N"
    msg := StrReplace(msg, "`n", "\n")
    jsonData := "{""content"":""" msg """}"

    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", webhookURL, false)
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(jsonData)
}

GetCurrentStatusText() {
    global hp, mp, exp, money
    return "❤️ 체력: " . (hp != "" ? hp : "-") . "`n💙 마력: " . (mp != "" ? mp : "-") . "`n🧪 경험치: " . (exp != "" ? exp : "-") . "`n💰 돈: " . (money != "" ? money : "-")
}

SendExitLog() {
    global username, computer, charName, dailyExpTotal, today, dailyExpFile
    FormatTime, now,, yyyy-MM-dd HH:mm:ss

    IniRead, finalEXP, %dailyExpFile%, DailyEXP, %today%, 0
    log := "📋 [누적 경험치 확인] " . charName . " 캐릭터가 경험치를 확인했습니다. (" . now . ")"
    log .= "`n👤 계정명: " . username
    log .= "`n💻 PC이름: " . computer
    log .= "`n📅 오늘 누적 경험치: +" . finalEXP
    log .= "`n`n" . GetCurrentStatusText()
    SendDiscordLog(log)
}

; 캐시 인증 여부 확인
IniRead, cachedName, %cacheFile%, Auth, %computer%, 0
if (cachedName != 0) {
    charName := cachedName
    MsgBox, 64, 인증 확인, 인증된 문파원입니다.
    goto AuthSuccess
}

allowedURL := "https://pastes.io/raw/1-75965-75"
allowedNames := FetchAllowedNames(allowedURL)
if (!IsObject(allowedNames)) {
    MsgBox, 16, 오류, 문파 리스트를 불러오지 못했습니다.`n인터넷 연결 또는 서버 상태를 확인해주세요.
    ExitApp
}

InputBox, charName, 문파 확인, 캐릭터명을 입력해주세요(문파 가입자만 실행), , 300, 130
if (ErrorLevel || !IsNameAllowed(charName, allowedNames)) {
    FormatTime, now,, yyyy-MM-dd HH:mm:ss
    log := "🔴 [실행 실패] " . charName . " 캐릭터는 문파 인증에 실패했습니다. (" . now . ")`n👤 계정명: " . username . "`n💻 PC이름: " . computer
    SendDiscordLog(log)
    MsgBox, 16, 접근 불가, [ %charName% ] 문파에 가입되어 있지 않습니다.`n프로그램을 종료합니다.
    ExitApp
}

; 인증 성공 시 캐시 기록
IniWrite, %charName%, %cacheFile%, Auth, %computer%

; 인증 통과 후 실행 로그
AuthSuccess:
FormatTime, now,, yyyy-MM-dd HH:mm:ss
log := "🟢 [실행] " . charName . " 캐릭터가 프로그램을 실행했습니다. (" . now . ")`n👤 계정명: " . username . "`n💻 PC이름: " . computer . "`n\n" . GetCurrentStatusText()
SendDiscordLog(log)

IsNameAllowed(name, list) {
    for _, n in list
        if (n = name)
            return true
    return false
}

FetchAllowedNames(url) {
    WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    try {
        WebRequest.Open("GET", url, false)
        WebRequest.Send()
        if (WebRequest.Status != 200)
            return ""
        list := StrSplit(WebRequest.ResponseText, "`n", "`r")
        final := []
        for index, line in list {
            line := Trim(line)
            if (line != "")
                final.Push(line)
        }
        return final
    } catch e {
        return ""
    }
}

win := "MapleStory Worlds"
mult := 2

size_w := 16 + (854 * mult)
size_h := 39 + (480 * mult)
xy_sx := 640 * mult, xy_sy := 456 * mult, xy_dx := xy_sx + 88 * mult, xy_dy := xy_sy + 12 * mult
hp_sx := 650 * mult, hp_sy := 403 * mult, hp_dx := hp_sx + 82 * mult, hp_dy := hp_sy + 12 * mult
mp_sx := 650 * mult, mp_sy := 416 * mult, mp_dx := mp_sx + 82 * mult, mp_dy := mp_sy + 12 * mult
exp_sx := 642 * mult, exp_sy := 429 * mult, exp_dx := exp_sx + 90 * mult, exp_dy := exp_sy + 12 * mult
money_sx := 642 * mult, money_sy := 442 * mult, money_dx := money_sx + 90 * mult, money_dy := money_sy + 12 * mult

; 목표 경험치 기본값 설정 (10억)
expTarget := 1000000000
expReached := false
WinMove, %win%, , , , %size_w%, %size_h%

Text := "<0>*0$8.62F2aNaNaNZ291W"
Text .= "|<1>*0$8.62F4V6EY92N1Ubm"
Text .= "|<2>*0$9.714EImOEG4VCEA2TY"
Text .= "|<3>*0$9.7l1E9m4V44FmEI4T4"
Text .= "|<4>*0$8.1UYF8IaNUM5t2EO"
Text .= "|<5>*0$9.7l18GQEW2CFWEY8S4"
Text .= "|<6>*0$8.3V4WH4+NaN62F3W"
Text .= "|<7>*0$8.DY61SF8YG8WEY62"
Text .= "|<8>*0$9.7V2H+F8G4aImYG4D4"
Text .= "|<9>*0$8.7299aNa1EX94W72"

; 경험치 타겟 매핑 (10억 ~ 100억)
global expMap := Object()
expOptions := ""
Loop, 10 {
    label := A_Index * 10 . "억"
    value := A_Index * 1000000000
    expMap[label] := value
    expOptions .= (A_Index = 1 ? "" : "|") . label
}

UpdateScale(mult) {
    global win, size_w, size_h
    global xy_sx, xy_sy, xy_dx, xy_dy
    global hp_sx, hp_sy, hp_dx, hp_dy
    global mp_sx, mp_sy, mp_dx, mp_dy
    global exp_sx, exp_sy, exp_dx, exp_dy
    global money_sx, money_sy, money_dx, money_dy

    ; 배율에 맞춰 좌표 계산
    size_w := 16 + (854 * mult)
    size_h := 39 + (480 * mult)
    xy_sx := 640 * mult, xy_sy := 456 * mult, xy_dx := xy_sx + 88 * mult, xy_dy := xy_sy + 12 * mult
    hp_sx := 650 * mult, hp_sy := 403 * mult, hp_dx := hp_sx + 82 * mult, hp_dy := hp_sy + 12 * mult
    mp_sx := 650 * mult, mp_sy := 416 * mult, mp_dx := mp_sx + 82 * mult, mp_dy := mp_sy + 12 * mult
    exp_sx := 642 * mult, exp_sy := 429 * mult, exp_dx := exp_sx + 90 * mult, exp_dy := exp_sy + 12 * mult
    money_sx := 642 * mult, money_sy := 442 * mult, money_dx := money_sx + 90 * mult, money_dy := money_sy + 12 * mult

    ; 윈도우 크기 조정
    WinMove, %win%, , , , %size_w%, %size_h%
}

Gui, +AlwaysOnTop +ToolWindow
Gui, Margin, 10, 10
Gui, Font, s14, Consolas
Gui, Add, GroupBox, x10 y10 w330 h310, 　　　　🔴 실시간 정보 🔴　　　　
Gui, Font, Bold
Gui, Add, Text, x30 y40 vHPText w290, ❤️ 체력 : -
Gui, Add, Text, x30 y70 vMPText w290, 💙 마력 : -
Gui, Add, Text, x30 y100 vEXPText w290, 🧪 경험치 : -
Gui, Add, Text, x30 y130 vMoneyText w290, 💰 돈 : -

Gui, Font, s13 Bold
Gui, Add, GroupBox, x10 y190 w330 h190, ⏱ 사냥 타이머
Gui, Add, Text, x30 y220 vHuntTimeText w290 +cDefault, 🕓 사냥 시간 : 00:00:00
Gui, Add, Text, x30 y250 vExpGainText w290 +cDefault, 📈 경험치 증가 : +0
Gui, Add, Text, x30 y280 vExpRemainText w290 +cDefault, 🎯 남은 경험치 : -

Gui, Font, s12 norm
Gui, Add, Text, x30 y315 w130, 🎯 목표 경험치:
Gui, Add, DropDownList, x170 y312 w140 vExpTargetList gUpdateExpTarget, %expOptions%
Gui, Font, s12 Bold  ; 추가
Gui, Add, Text, x30 y345 vDailyExpText w290 +cGreen, 📅 오늘 누적 경험치 : +%dailyExpTotal%

Gui, Font, s12
Gui, Add, Button, x10 y390 w150 h35 gOpenScaleSettings, 🔧 배율 설정
Gui, Add, Button, x170 y390 w150 h35 gShowDailyExpLog, 📋 날짜별 경험치 (F8)
Gui, Add, Button, x10 y430 w310 h35 gToggleHuntTimer vHuntTimerBtn Disabled, 🕒 사냥타이머 ON (F5)
Gui, Add, Button, x10 y470 w310 h35 gResetHuntTimer vResetHuntTimerBtn Disabled, 🧹 사냥타이머 초기화 및 저장 (F6)

Gui, Show, AutoSize, 🦌 사슴 바클 상태창
Gosub, StartOCR
return

F12::Gosub, StartOCR
F5::Gosub, ToggleHuntTimer
F11::Reload
F8::
ShowDailyExpLog()
return
F6::Gosub, ResetHuntTimer

GuiClose:
SendExitLog()
ExitApp

OpenScaleSettings:
Gui, Scale:New, +AlwaysOnTop +ToolWindow
Gui, Scale:Add, Text,, 창 크기 배율을 선택하세요:
Gui, Scale:Add, Radio, vScaleChoice Group, 1배율
Gui, Scale:Add, Radio,, 2배율
Gui, Scale:Add, Button, Default gSaveScale, 확인

; 기존 설정된 mult 값에 따라 라디오 버튼 체크
if (mult = 1)
    GuiControl, Scale:, ScaleChoice, 1
else if (mult = 2)
    GuiControl, Scale:, ScaleChoice, 2

Gui, Scale:Show,, 배율 설정
return

SaveScale:
Gui, Scale:Submit
if (ScaleChoice = 1)
    mult := 1
else if (ScaleChoice = 2)
    mult := 2

; 배율을 INI 파일에 저장
IniWrite, %mult%, %cacheFile%, Settings, mult

; 배율 적용
UpdateScale(mult)

Gui, Scale:Destroy
return


return

; OnExit 핸들러 등록 (선택 사항)
OnExit("SendExitLog")

if (newDate != checkDate && !midnightResetDone) {
    midnightResetDone := true
    ; 초기화 코드 실행
} else if (newDate = checkDate) {
    midnightResetDone := false
}

; 자정 자동 초기화 루프 안에도 있음
StartOCR:
if (ocrRunning)
    return
ocrRunning := true
FindText().BindWindow(WinExist(win), 4)

GuiControl, Disable, StartOCR
GuiControl, Enable, StopOCR
GuiControl, Enable, HuntTimerBtn

; 기존 OCR 루프 부분 수정
Loop {
    if (!ocrRunning)
        break

    start_time := A_TickCount
    WinGetPos, pX, pY, pW, pH, %win%
    FindText().ScreenShot()

    ; 날짜가 바뀌었는지 확인
    newDate := A_YYYY . "-" . A_MM . "-" . A_DD
    if (newDate != checkDate) {
    ; 날짜 변경 시 로그 발송
    FormatTime, now,, yyyy-MM-dd HH:mm:ss
    log := "🌙 [자정 초기화] " . charName . "의 누적 경험치가 자정 기준으로 초기화되었습니다. (" . now . ")"
    log .= "`n📅 " . today . " 누적 경험치: +" . dailyExpTotal
    SendDiscordLog(log)

    today := newDate
    checkDate := newDate
    dailyExpTotal := 0
    IniRead, readExp, %dailyExpFile%, DailyEXP, %today%, 0
    dailyExpTotal := readExp + 0
    GuiControl,, DailyExpText, 📅 오늘 누적 경험치 : +%dailyExpTotal%
}

    xy := searchsort(win, xy_sx + pX, xy_sy + pY, xy_dx + pX, xy_dy + pY, Text,,,mult,mult)
    hp := searchsort(win, hp_sx + pX, hp_sy + pY, hp_dx + pX, hp_dy + pY, Text,,0.7,mult,mult)
    mp := searchsort(win, mp_sx + pX, mp_sy + pY, mp_dx + pX, mp_dy + pY, Text,,0.7,mult,mult)
    exp := searchsort(win, exp_sx + pX, exp_sy + pY, exp_dx + pX, exp_dy + pY, Text,,0.7,mult,mult)
    money := searchsort(win, money_sx + pX, money_sy + pY, money_dx + pX, money_dy + pY, Text,,,mult,mult)

    hp    := hp    != "" ? hp    : "-"
    mp    := mp    != "" ? mp    : "-"
    exp   := exp   != "" ? exp   : "-"
    money := money != "" ? money : "-"
    last_time := A_TickCount - start_time

    GuiControl,, HPText, 체력 : %hp%
    GuiControl,, MPText, 마력 : %mp%
    GuiControl,, EXPText, 경험치 : %exp%
    GuiControl,, MoneyText, 돈 : %money%
    GuiControl,, TimeText, 인식 시간 : %last_time% ms

    currentDetectedEXP := SafeNumber(exp)

    ; 경험치 상승 감지 -> 사냥 타이머 자동 ON
    if (!huntTimerRunning && lastDetectedEXP != 0 && currentDetectedEXP > lastDetectedEXP && currentDetectedEXP > 0) {
    Gosub, AutoStartHuntTimer
}

    ; 경험치가 정상적으로 인식된 경우만 기록
    if (currentDetectedEXP > 0)
        lastDetectedEXP := currentDetectedEXP

    if (huntTimerRunning && !huntPaused)
        Gosub, UpdateHuntTime

    Sleep, 200
}

; 자동 시작 라벨 추가
AutoStartHuntTimer:
    huntTimerRunning := true
    huntPaused := false
    huntStartTime := A_TickCount
    huntStartEXP := SafeNumber(exp)
    huntStartDailyExp := dailyExpTotal   ; ✅ 누적 경험치 백업
    expReached := false

    ; 최초 경험치 증가값을 계산하여 반영
    currentEXP := SafeNumber(exp)
    deltaEXP := currentEXP - huntStartEXP
    if (deltaEXP < 0)
        deltaEXP := 0  ; 음수 값은 무시하고 0으로 설정

    ; 최초 경험치 증가값을 누적 경험치에 반영
    dailyExpTotal := deltaEXP + huntStartDailyExp
    IniWrite, %dailyExpTotal%, %dailyExpFile%, DailyEXP, %today%

    ; 화면에 최초 경험치 증가값 표시
    GuiControl,, ExpGainText, 경험치 증가 : +%deltaEXP%
    GuiControl,, ExpRemainText, 남은 경험치 : 계산 중...

    SetTimer, UpdateHuntTime, 1000

    GuiControl,, HuntTimerBtn, ⏸ 사냥 타이머 일시정지 (F5)
    GuiControl, +cRed, HuntTimeText
    GuiControl, +cRed, ExpGainText
    GuiControl, +cRed, ExpRemainText
    GuiControl, Enable, ResetHuntTimerBtn
return

FindText().BindWindow(0)
return

StopOCR:
ocrRunning := false
SetTimer, UpdateHuntTime, Off
GuiControl, Enable, StartOCR
GuiControl, Disable, StopOCR
return

ToggleHuntTimer:
if (!huntTimerRunning) {
    huntTimerRunning := true
    huntPaused := false
    huntStartTime := A_TickCount
    huntStartEXP := SafeNumber(exp)
    huntStartDailyExp := dailyExpTotal   ; ✅ 누적 경험치 백업
    expReached := false
    GuiControl,, ExpGainText, 경험치 증가 : 계산 중...
    GuiControl,, ExpRemainText, 남은 경험치 : 계산 중...
    SetTimer, UpdateHuntTime, 1000
    GuiControl,, HuntTimerBtn, ⏸ 사냥 타이머 일시정지 (F5)
    GuiControl, +cRed, HuntTimeText
    GuiControl, +cRed, ExpGainText
    GuiControl, +cRed, ExpRemainText
    GuiControl, Enable, ResetHuntTimerBtn
} else if (!huntPaused) {
    huntPaused := true
    pauseTime := A_TickCount
    SetTimer, UpdateHuntTime, Off
    GuiControl,, HuntTimerBtn, ▶ 사냥 타이머 재개 (F5)
	GuiControl,, HuntTimeText, 사냥 시간  : ⏸ 일시정지 중
    GuiControl,, ExpGainText, 경험치 증가 : ⏸ 일시정지 중
    GuiControl,, ExpRemainText, 남은 경험치 : ⏸ 일시정지 중
} else {
    huntPaused := false
    resumeTime := A_TickCount
    huntStartTime += (resumeTime - pauseTime)
    SetTimer, UpdateHuntTime, 1000
    GuiControl,, HuntTimerBtn, ⏸ 사냥 타이머 일시정지 (F5)
    GuiControl,, HuntTimeText, 사냥 시간 : 계산 중...
    GuiControl,, ExpGainText, 경험치 증가 : 계산 중...
    GuiControl,, ExpRemainText, 남은 경험치 : 계산 중...
}
return

ResetHuntTimer:
huntTimerRunning := false
huntPaused := false
SetTimer, UpdateHuntTime, Off

; 사냥 시간 계산
elapsed := A_TickCount - huntStartTime
hours := Floor(elapsed / 3600000)
minutes := Floor(Mod(elapsed, 3600000) / 60000)
seconds := Floor(Mod(elapsed, 60000) / 1000)

; 두 자리 수로 포맷팅
SetFormat, Integer, D
hours := (hours < 10 ? "0" . hours : hours)
minutes := (minutes < 10 ? "0" . minutes : minutes)
seconds := (seconds < 10 ? "0" . seconds : seconds)
formattedTime := hours ":" minutes ":" seconds

; 경험치 증가량 계산
currentEXP := SafeNumber(exp)
deltaEXP := currentEXP - huntStartEXP
if (deltaEXP < 0)
    deltaEXP := 0  ; 음수 값은 무시하고 0으로 설정

; ✅ 누적 경험치 저장 (정확한 기준으로)
dailyExpTotal := deltaEXP + huntStartDailyExp
IniWrite, %dailyExpTotal%, %dailyExpFile%, DailyEXP, %today%
GuiControl,, DailyExpText, 📅 오늘 누적 경험치 : +%dailyExpTotal%

; 디스코드 로그 전송
FormatTime, now,, yyyy-MM-dd HH:mm:ss
log := "🧹 [타이머 초기화] " . charName . " 캐릭터가 사냥 타이머를 초기화했습니다. (" . now . ")`n"
log .= "🕓 사냥 시간: " . formattedTime . "`n📈 경험치 증가: +" . deltaEXP
log .= "`n❤️ 체력: " . hp
log .= "`n💙 마력: " . mp
log .= "`n🧪 경험치: " . exp
log .= "`n💰 돈: " . money
SendDiscordLog(log)

; GUI 초기화
huntStartTime := ""
huntStartEXP := ""
huntStartDailyExp := 0
expReached := false
GuiControl,, HuntTimeText, 사냥 시간 : 00:00:00
GuiControl,, ExpGainText, 경험치 증가 : +0
GuiControl,, ExpRemainText, 남은 경험치 : -
GuiControl,, HuntTimerBtn, 🕒 사냥타이머 ON(F5)
GuiControl, +cDefault, HuntTimeText
GuiControl, +cDefault, ExpGainText
GuiControl, +cDefault, ExpRemainText
GuiControl, Disable, ResetHuntTimerBtn

readExp := dailyExpTotal  ; ✅ 다음 타이머 기준 갱신
return

; 전체 스크립트 (사냥 타이머 일시정지 시 시간/경험치 관련 멈춤 반영)

; ...[생략된 부분은 이전과 동일]...

UpdateHuntTime:
if (!huntTimerRunning || huntPaused)
    return

elapsed := A_TickCount - huntStartTime
h := Floor(elapsed / 3600000)
m := Floor(Mod(elapsed, 3600000) / 60000)
s := Floor(Mod(elapsed, 60000) / 1000)
formatted := Format("{:02}:{:02}:{:02}", h, m, s)
GuiControl,, HuntTimeText, 사냥 시간 : %formatted%

if (exp != "") {
    currentEXP := SafeNumber(exp)
    deltaEXP := currentEXP - huntStartEXP
    remainEXP := expTarget - deltaEXP
    if (remainEXP < 0)
        remainEXP := 0

    if (deltaEXP >= 0) {
        GuiControl,, ExpGainText, 경험치 증가 : +%deltaEXP%
        dailyExpTotal := deltaEXP + readExp
        IniWrite, %dailyExpTotal%, %dailyExpFile%, DailyEXP, %today%
        GuiControl,, DailyExpText, 📅 오늘 누적 경험치 : +%dailyExpTotal%

        if (deltaEXP >= 1000000000) {
            GuiControl, +cPurple, ExpGainText
        } else if (deltaEXP >= 100000000) {
            GuiControl, +cGreen, ExpGainText
        } else if (deltaEXP >= 10000000) {
            GuiControl, +cBlue, ExpGainText
        } else {
            GuiControl, +cDefault, ExpGainText
        }

        GuiControl,, ExpRemainText, 남은 경험치 : %remainEXP%
    } else {
        GuiControl,, ExpGainText, 경험치 증가 : 오류
        GuiControl,, ExpRemainText, 남은 경험치 : 오류
        GuiControl, +cDefault, ExpGainText
    }
}
return


UpdateExpTarget:
GuiControlGet, ExpTargetList
global expTarget := expMap[ExpTargetList]
expReached := false
GuiControl,, ExpRemainText, 남은 경험치 : 계산 중...
return

searchsort(win, a, b, c, d, e, f := 0.000001, g := 0.000001, h := 1, i := 1)
{
    n := ""
    if (obj := FindText(X, Y, a, b, c, d, f, g, e, 0,,,,,,h,i))
    {
        obj := FindText().sort(obj)
        for k, v in obj
            n .= v.id "|"
    }
    return RegExReplace(SubStr(n, 1, StrLen(n) - 1), "\|")
}

SafeNumber(str) {
    cleaned := RegExReplace(str, "[^\d]", "")
    if (cleaned = "")
        return 0
    return cleaned + 0
}
