; =========================================
; BSS WEBSOCKET RELAY
; Communicates via bridge.js file relay
; =========================================

; ===== GLOBALS =====
global WSOutbox
global WSInbox
global WSRegistered      := false
global WSPollTimer       := 0
global WSHost            := "127.0.0.1"
global WSPort            := "8080"
global WSConnecting      := false
global WSConnected       := false
global RelayClients      := []
global RelayGui          := ""
global AltPendingCommand := ""
global AltMyRole
global AltMyMainVIP
global AltMyIdleVIP
global AltClientName
global BridgeRunning     := false
global RelayServerPID    := 0
global RelayBridgePID    := 0
global AttackPrepareSent := false
global AttackLeaveSent   := false
global RelayBFBActive    := false
global RelayClientStatus := Map()   ; clientID -> "online"/"offline"
global ReconnectLastDate := ""      ; "yyyyMMdd" of last daily reconnect

; ===== CONFIG GLOBALS =====
global CFG_ServerIP          := "127.0.0.1"
global CFG_Port              := "8080"
global CFG_MainVIP           := ""
global CFG_IdleVIP           := ""
global CFG_SubVIP            := ""
global CFG_ExtraVIP          := ""
global CFG_DiscordEnable     := false
global CFG_BotToken          := ""
global CFG_UserID            := ""
global CFG_ChannelID         := ""
global CFG_BotPrefix         := "?"
global CFG_AttackCycleStart  := "57"
global CFG_AttackTimeout     := "3"
global CFG_ReconnectEnable   := false
global CFG_ReconnectTime     := "06:30"
global CFG_ReconnectPer24h   := "1"
global CFG_ReconnectMainOnly := false
global CFG_GuideNonPineMins  := "5"
global CFG_GuideGatherField  := "Rose"
global CFG_GuideFieldBluf    := "Mushroom"
global CFG_GuideFieldBamb    := "Spider"
global CFG_TadReturnField    := "Pine Tree"
global CFG_TadPreTadEnable   := false
global CFG_TadPreTadClientID := ""
global CFG_TadPreTadField    := "Blue Flower"

; ===== FIELD LIST =====
global FieldList := ["Pine Tree", "Blue Flower", "Bamboo", "Sunflower", "Clover", "Dandelion",
                     "Mushroom", "Rose", "Strawberry", "Spider", "Pineapple", "Stump",
                     "Cactus", "Pumpkin", "Mountain Top", "Pepper", "Coconut"]

; =========================================
; CONFIG LOAD / SAVE
; =========================================

LoadConfig() {
    global CFG_INI, CFG_LOG, CFG_ServerIP, CFG_Port, CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    global CFG_DiscordEnable, CFG_BotToken, CFG_UserID, CFG_ChannelID, CFG_BotPrefix
    global CFG_AttackCycleStart, CFG_AttackTimeout
    global CFG_ReconnectEnable, CFG_ReconnectTime, CFG_ReconnectPer24h, CFG_ReconnectMainOnly
    global CFG_GuideNonPineMins, CFG_GuideGatherField, CFG_GuideFieldBluf, CFG_GuideFieldBamb
    global CFG_TadReturnField, CFG_TadPreTadEnable, CFG_TadPreTadClientID, CFG_TadPreTadField
    global WSHost, WSPort, WSOutbox, WSInbox, RelayClients
    global AltClientName, AltMyRole, AltMyMainVIP, AltMyIdleVIP, BridgeRunning

    SplitPath(A_WorkingDir, , &parentDir)

    CFG_INI  := A_WorkingDir "\settings\alt_config.ini"
    CFG_LOG  := A_WorkingDir "\logs\bss_relay.log"
    WSOutbox := parentDir "\BSSRelay\outbox.txt"
    WSInbox  := parentDir "\BSSRelay\inbox.txt"

    if !FileExist(A_WorkingDir "\settings")
        DirCreate(A_WorkingDir "\settings")
    if !FileExist(A_WorkingDir "\logs")
        DirCreate(A_WorkingDir "\logs")

    if !FileExist(CFG_INI)
        SaveConfig()

    CFG_ServerIP          := IniRead(CFG_INI, "Relay",     "ServerIP",          "127.0.0.1")
    CFG_Port              := IniRead(CFG_INI, "Relay",     "Port",              "8080")
    CFG_MainVIP           := IniRead(CFG_INI, "VIP",       "MainVIP",           "")
    CFG_IdleVIP           := IniRead(CFG_INI, "VIP",       "IdleVIP",           "")
    CFG_SubVIP            := IniRead(CFG_INI, "VIP",       "SubVIP",            "")
    CFG_ExtraVIP          := IniRead(CFG_INI, "VIP",       "ExtraVIP",          "")
    CFG_DiscordEnable     := IniRead(CFG_INI, "Discord",   "Enable",            "0")
    CFG_BotToken          := IniRead(CFG_INI, "Discord",   "BotToken",          "")
    CFG_UserID            := IniRead(CFG_INI, "Discord",   "UserID",            "")
    CFG_ChannelID         := IniRead(CFG_INI, "Discord",   "ChannelID",         "")
    CFG_BotPrefix         := IniRead(CFG_INI, "Discord",   "BotPrefix",         "?")
    CFG_AttackCycleStart  := IniRead(CFG_INI, "Attack",    "CycleStart",        "57")
    CFG_AttackTimeout     := IniRead(CFG_INI, "Attack",    "TimeoutPastMondo",  "3")
    CFG_ReconnectEnable   := IniRead(CFG_INI, "Reconnect", "Enable",            "0")
    CFG_ReconnectTime     := IniRead(CFG_INI, "Reconnect", "Time",              "06:30")
    CFG_ReconnectPer24h   := IniRead(CFG_INI, "Reconnect", "Per24h",            "1")
    CFG_ReconnectMainOnly := IniRead(CFG_INI, "Reconnect", "MainServerOnly",    "0")
    CFG_GuideNonPineMins  := IniRead(CFG_INI, "GuideAlt",  "NonPineMins",       "5")
    CFG_GuideGatherField  := IniRead(CFG_INI, "GuideAlt",  "GatherField",       "Rose")
    CFG_GuideFieldBluf    := IniRead(CFG_INI, "GuideAlt",  "GatherFieldBluf",   "Mushroom")
    CFG_GuideFieldBamb    := IniRead(CFG_INI, "GuideAlt",  "GatherFieldBamb",   "Spider")
    CFG_TadReturnField    := IniRead(CFG_INI, "TadAlt",    "ReturnField",       "Pine Tree")
    CFG_TadPreTadEnable   := IniRead(CFG_INI, "TadAlt",    "EnablePreTad",      "0")
    CFG_TadPreTadClientID := IniRead(CFG_INI, "TadAlt",    "PreTadClientID",    "")
    CFG_TadPreTadField    := IniRead(CFG_INI, "TadAlt",    "PreTadField",       "Blue Flower")

    WSHost := CFG_ServerIP
    WSPort := CFG_Port

    RelayClients := []
    clientCount  := IniRead(CFG_INI, "Clients", "Count", "0")
    loop clientCount {
        RelayClients.Push({
            id:      IniRead(CFG_INI, "Client" A_Index, "ID",      "client_" A_Index),
            userID:  IniRead(CFG_INI, "Client" A_Index, "UserID",  ""),
            role:    IniRead(CFG_INI, "Client" A_Index, "Role",    "Tad"),
            mainVIP: IniRead(CFG_INI, "Client" A_Index, "MainVIP", "Main VIP"),
            idleVIP: IniRead(CFG_INI, "Client" A_Index, "IdleVIP", "Idle VIP")
        })
    }

    AltClientName := IniRead(CFG_INI, "ThisPC", "ClientName", "")

    for client in RelayClients {
        if (client.id = AltClientName) {
            AltMyRole    := client.role
            AltMyMainVIP := client.mainVIP
            AltMyIdleVIP := client.idleVIP
            break
        }
    }

    try {
        RunWait('cmd.exe /c tasklist /fi "imagename eq node.exe" /fo csv /nh > "%TEMP%\nodechk.txt"', , "Hide")
        if InStr(FileRead(A_Temp "\nodechk.txt"), "node.exe")
            BridgeRunning := true
    }
}

SaveConfig() {
    global CFG_INI, CFG_ServerIP, CFG_Port, CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    global CFG_DiscordEnable, CFG_BotToken, CFG_UserID, CFG_ChannelID, CFG_BotPrefix
    global CFG_AttackCycleStart, CFG_AttackTimeout
    global CFG_ReconnectEnable, CFG_ReconnectTime, CFG_ReconnectPer24h, CFG_ReconnectMainOnly
    global CFG_GuideNonPineMins, CFG_GuideGatherField, CFG_GuideFieldBluf, CFG_GuideFieldBamb
    global CFG_TadReturnField, CFG_TadPreTadEnable, CFG_TadPreTadClientID, CFG_TadPreTadField
    global RelayClients

    IniWrite(CFG_ServerIP,          CFG_INI, "Relay",     "ServerIP")
    IniWrite(CFG_Port,              CFG_INI, "Relay",     "Port")
    IniWrite(CFG_MainVIP,           CFG_INI, "VIP",       "MainVIP")
    IniWrite(CFG_IdleVIP,           CFG_INI, "VIP",       "IdleVIP")
    IniWrite(CFG_SubVIP,            CFG_INI, "VIP",       "SubVIP")
    IniWrite(CFG_ExtraVIP,          CFG_INI, "VIP",       "ExtraVIP")
    IniWrite(CFG_DiscordEnable,     CFG_INI, "Discord",   "Enable")
    IniWrite(CFG_BotToken,          CFG_INI, "Discord",   "BotToken")
    IniWrite(CFG_UserID,            CFG_INI, "Discord",   "UserID")
    IniWrite(CFG_ChannelID,         CFG_INI, "Discord",   "ChannelID")
    IniWrite(CFG_BotPrefix,         CFG_INI, "Discord",   "BotPrefix")
    IniWrite(CFG_AttackCycleStart,  CFG_INI, "Attack",    "CycleStart")
    IniWrite(CFG_AttackTimeout,     CFG_INI, "Attack",    "TimeoutPastMondo")
    IniWrite(CFG_ReconnectEnable,   CFG_INI, "Reconnect", "Enable")
    IniWrite(CFG_ReconnectTime,     CFG_INI, "Reconnect", "Time")
    IniWrite(CFG_ReconnectPer24h,   CFG_INI, "Reconnect", "Per24h")
    IniWrite(CFG_ReconnectMainOnly, CFG_INI, "Reconnect", "MainServerOnly")
    IniWrite(CFG_GuideNonPineMins,  CFG_INI, "GuideAlt",  "NonPineMins")
    IniWrite(CFG_GuideGatherField,  CFG_INI, "GuideAlt",  "GatherField")
    IniWrite(CFG_GuideFieldBluf,    CFG_INI, "GuideAlt",  "GatherFieldBluf")
    IniWrite(CFG_GuideFieldBamb,    CFG_INI, "GuideAlt",  "GatherFieldBamb")
    IniWrite(CFG_TadReturnField,    CFG_INI, "TadAlt",    "ReturnField")
    IniWrite(CFG_TadPreTadEnable,   CFG_INI, "TadAlt",    "EnablePreTad")
    IniWrite(CFG_TadPreTadClientID, CFG_INI, "TadAlt",    "PreTadClientID")
    IniWrite(CFG_TadPreTadField,    CFG_INI, "TadAlt",    "PreTadField")

    IniWrite(RelayClients.Length, CFG_INI, "Clients", "Count")
    loop RelayClients.Length {
        c := RelayClients[A_Index]
        IniWrite(c.id,      CFG_INI, "Client" A_Index, "ID")
        IniWrite(c.role,    CFG_INI, "Client" A_Index, "Role")
        IniWrite(c.userID,  CFG_INI, "Client" A_Index, "UserID")
        IniWrite(c.mainVIP, CFG_INI, "Client" A_Index, "MainVIP")
        IniWrite(c.idleVIP, CFG_INI, "Client" A_Index, "IdleVIP")
    }
}

; =========================================
; WEBSOCKET CORE
; =========================================

WSRegister() {
    global WSOutbox, AltClientName
    WSWrite("REGISTER|" AltClientName "|unknown")
    WSRegistered := true
    RelayLog("[WS] Registered as " AltClientName)
}

WSSendMessage(codeword, command, data := "") {
    global AltClientName
    msg := "[" codeword "]" AltClientName "|" command "|" data
    WSWrite(msg)
    RelayLog("[WS SENT] " msg)
    return true
}

WSWrite(msg) {
    global WSOutbox
    try {
        FileAppend(msg "`n", WSOutbox)
    } catch as e {
        RelayLog("[WS ERROR] Write failed: " e.Message, "error")
    }
}

WSStartPolling() {
    global WSPollTimer
    if (!WSPollTimer)
        WSPollTimer := SetTimer(WSPollInbox, 200)
    RelayLog("[WS] Polling started")
}

WSPollInbox() {
    global WSInbox, WSConnecting
    if (WSConnecting)
        return
    try {
        content := FileRead(WSInbox)
        if (!content || content = "")
            return
        FileDelete(WSInbox)
        loop parse, content, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line = "" || line = "ACK" || InStr(line, "ACK|"))
                continue
            if (InStr(line, "[BSS_")) {
                RelayLog("[WS RECV] " line)
                WSHandleMessage(line)
            }
        }
    } catch {
    }
}

WSHandleMessage(msg) {
    if !RegExMatch(msg, "^\[([^\]]+)\]([^|]+)\|([^|]+)\|?(.*)", &m)
        return
    cmd := { codeword: m[1], sender: m[2], command: m[3], data: m[4] }
    ExecuteAltCommand(cmd)
}

; =========================================
; VIP RESOLUTION
; =========================================

ResolveVIPLabel(label) {
    global CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    switch label {
        case "Main VIP":  return CFG_MainVIP
        case "Idle VIP":  return CFG_IdleVIP
        case "Sub VIP":   return CFG_SubVIP
        case "Extra VIP": return CFG_ExtraVIP
        default:          return label   ; treat as literal URL
    }
}

; =========================================
; COMMAND DISPATCH
; =========================================

ExecuteAltCommand(cmd) {
    global AltPendingCommand, AltMyRole, RelayClientStatus

    switch cmd.command {
        case "ATTACK_PREPARE":
            if (AltMyRole = "Attack") {
                AltPendingCommand := "ATTACK_PREPARE"
                RelayLog("[EXEC] Attack prepare queued")
            }
        case "ATTACK_LEAVE":
            if (AltMyRole = "Attack") {
                AltPendingCommand := "ATTACK_LEAVE"
                RelayLog("[EXEC] Attack leave queued")
            }
        case "TAD_BFB":
            if (AltMyRole = "Tad") {
                AltPendingCommand := "TAD_BFB"
                RelayLog("[EXEC] Tad BFB queued")
            } else if (AltMyRole = "Guide") {
                AltPendingCommand := "GUIDE_BFB_ON"
                RelayLog("[EXEC] Guide BFB-on queued")
            }
        case "TAD_LEAVE":
            if (AltMyRole = "Tad") {
                AltPendingCommand := "TAD_LEAVE"
                RelayLog("[EXEC] Tad leave queued")
            } else if (AltMyRole = "Guide") {
                AltPendingCommand := "GUIDE_BFB_OFF"
                RelayLog("[EXEC] Guide BFB-off queued")
            }
        case "CLIENT_JOINED":
            HandleClientJoined(cmd.data)
        case "CLIENT_LEFT":
            HandleClientLeft(cmd.data)
        case "RELAY_VIP":
            HandleRelayVIP(cmd.data)
        default:
            RelayLog("[EXEC] Unknown command: " cmd.command " from " cmd.sender)
    }
}

HandleClientJoined(data) {
    global RelayClientStatus
    ; data format: "clientID:role"
    parts := StrSplit(data, ":")
    cid   := parts[1]
    RelayClientStatus[cid] := "online"
    RelayLog("[RELAY] Client joined: " data)
    DiscordSend("✅ " cid " connected to relay")
    RMUpdateClientStatus()
}

HandleClientLeft(data) {
    global RelayClientStatus
    parts := StrSplit(data, ":")
    cid   := parts[1]
    RelayClientStatus[cid] := "offline"
    RelayLog("[RELAY] Client left: " data)
    DiscordSend("⚠️ " cid " disconnected from relay")
    RMUpdateClientStatus()
}

HandleRelayVIP(data) {
    global CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    global RelayClients, AltClientName, AltMyMainVIP, AltMyIdleVIP
    ; data format: "main=url|idle=url|sub=url|extra=url"
    loop parse, data, "|" {
        kv := StrSplit(A_LoopField, "=", , 2)
        if (kv.Length < 2)
            continue
        switch kv[1] {
            case "main":  CFG_MainVIP  := kv[2]
            case "idle":  CFG_IdleVIP  := kv[2]
            case "sub":   CFG_SubVIP   := kv[2]
            case "extra": CFG_ExtraVIP := kv[2]
        }
    }
    ; Re-resolve this PC's VIP labels now that URLs are updated
    for client in RelayClients {
        if (client.id = AltClientName) {
            AltMyMainVIP := ResolveVIPLabel(client.mainVIP)
            AltMyIdleVIP := ResolveVIPLabel(client.idleVIP)
            break
        }
    }
    RelayLog("[VIP] Received VIP links from relay")
}

; =========================================
; MACRO LOOP INTEGRATION
; =========================================

nm_RelayCheck() {
    global AltPendingCommand, AltMyRole, AltMyMainVIP, AltMyIdleVIP
    global CFG_ReconnectEnable, CFG_TadReturnField

    ; Daily reconnect check (cheap guard inside, safe every loop)
    if (CFG_ReconnectEnable)
        CheckDailyReconnect()

    if (AltPendingCommand = "")
        return

    cmd              := AltPendingCommand
    AltPendingCommand := ""

    if (AltMyRole = "Attack") {
        if (cmd = "ATTACK_PREPARE") {
            RelayLog("[ALT] Attack prepare - joining Main VIP")
            AltSwitchServer(AltMyMainVIP)
        } else if (cmd = "ATTACK_LEAVE") {
            RelayLog("[ALT] Attack leave - returning to Idle VIP")
            AltSwitchServer(AltMyIdleVIP)
        }

    } else if (AltMyRole = "Tad") {
        if (cmd = "TAD_BFB") {
            RelayLog("[ALT] Tad BFB - joining Main VIP")
            AltSwitchServer(AltMyMainVIP)
        } else if (cmd = "TAD_LEAVE") {
            RelayLog("[ALT] Tad leave - returning to Idle VIP")
            AltSwitchServer(AltMyIdleVIP)
            Sleep 3000
            nm_gotoField(StrLower(StrReplace(CFG_TadReturnField, " ", "")))
        }

    } else if (AltMyRole = "Guide") {
        if (cmd = "GUIDE_BFB_ON") {
            RelayLog("[ALT] Guide - BFB on, switching field")
            nm_RelayGuideFieldUpdate(true)
        } else if (cmd = "GUIDE_BFB_OFF") {
            RelayLog("[ALT] Guide - BFB off, switching field")
            nm_RelayGuideFieldUpdate(false)
        }
    }
}

; =========================================
; GUIDE ALT FIELD ROTATION
; =========================================

; Called when BFB state changes on the Guide alt.
; bfbActive=true  → switch to Blue Flower adjacet field (CFG_GuideFieldBluf)
; bfbActive=false → return to default gather field    (CFG_GuideGatherField)
nm_RelayGuideFieldUpdate(bfbActive) {
    global CFG_GuideGatherField, CFG_GuideFieldBluf
    targetField := bfbActive ? CFG_GuideFieldBluf : CFG_GuideGatherField
    nm_gotoField(StrLower(StrReplace(targetField, " ", "")))
    RelayLog("[GUIDE] Switched gather field to: " targetField)
}

; =========================================
; BFB DETECTION HOOK
; Call nm_RelayBFBChange(true)  when BFB activates on the main server
; Call nm_RelayBFBChange(false) when BFB ends
; =========================================

nm_RelayBFBChange(active) {
    global RelayBFBActive, WSConnected
    if (!WSConnected)
        return
    RelayBFBActive := active
    if (active) {
        SendToRole("Tad",   "TAD_BFB")
        SendToRole("Guide", "TAD_BFB")
        RelayLog("[BFB] BFB started - TAD_BFB broadcast")
        DiscordSend("🌼 Blue Flower Boost detected - Tad alts summoned")
    } else {
        SendToRole("Tad",   "TAD_LEAVE")
        SendToRole("Guide", "TAD_LEAVE")
        RelayLog("[BFB] BFB ended - TAD_LEAVE broadcast")
        DiscordSend("🌼 Blue Flower Boost ended - Tad alts returning")
    }
}

; =========================================
; SEND TO ROLE
; Server broadcasts to all; each client self-filters in ExecuteAltCommand
; =========================================

SendToRole(role, command, data := "") {
    WSSendMessage("BSS_CMD", command, role (data != "" ? "|" data : ""))
    RelayLog("[CMD] Sent " command " → role:" role)
}

; =========================================
; VIP BROADCAST  (main → all alts on connect)
; =========================================

SendRelayVIP() {
    global CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    data := "main=" CFG_MainVIP "|idle=" CFG_IdleVIP "|sub=" CFG_SubVIP "|extra=" CFG_ExtraVIP
    WSSendMessage("BSS_CMD", "RELAY_VIP", data)
    RelayLog("[VIP] Broadcast VIP links to all alts")
}

; =========================================
; SERVER SWITCH
; =========================================

AltSwitchServer(vipLabel) {
    global PrivServer
    url := ResolveVIPLabel(vipLabel)
    if (url = "") {
        RelayLog("[ALT] No VIP URL resolved for: " vipLabel, "error")
        return
    }
    RelayLog("[ALT] Switching to: " vipLabel)
    PrivServer := url
    try nm_endWalk()
    DisconnectCheck(1)
}

; =========================================
; ATTACK TIMER
; =========================================

StartAttackTimer() {
    global AttackPrepareSent, AttackLeaveSent
    AttackPrepareSent := false
    AttackLeaveSent   := false
    SetTimer(CheckAttackTimer, 30000)   ; check every 30 s
    RelayLog("[TIMER] Attack timer started")
}

CheckAttackTimer() {
    global CFG_AttackCycleStart, CFG_AttackTimeout
    global AttackPrepareSent, AttackLeaveSent

    min := Integer(FormatTime(A_Now, "m"))

    ; Send ATTACK_PREPARE at CycleStart minute (default :57)
    if (min = Integer(CFG_AttackCycleStart) && !AttackPrepareSent) {
        SendToRole("Attack", "ATTACK_PREPARE")
        AttackPrepareSent := true
        AttackLeaveSent   := false
        RelayLog("[TIMER] ATTACK_PREPARE sent at :" Format("{:02}", min))
        DiscordSend("⚔️ Attack alts summoned at :" Format("{:02}", min))
    }

    ; Send ATTACK_LEAVE at TimeoutPastMondo minute (default :03)
    leaveMin := Integer(CFG_AttackTimeout)
    if (min = leaveMin && AttackPrepareSent && !AttackLeaveSent) {
        SendToRole("Attack", "ATTACK_LEAVE")
        AttackLeaveSent   := true
        AttackPrepareSent := false
        RelayLog("[TIMER] ATTACK_LEAVE sent at :" Format("{:02}", min))
        DiscordSend("⚔️ Attack alts returning at :" Format("{:02}", min))
    }

    ; Reset cycle flags 5 min after leave so next hour works
    resetMin := Mod(leaveMin + 5, 60)
    if (min = resetMin && AttackLeaveSent) {
        AttackPrepareSent := false
        AttackLeaveSent   := false
    }
}

; =========================================
; DISCORD  (Bot API via WinHttp)
; =========================================

DiscordSend(msg) {
    global CFG_DiscordEnable, CFG_BotToken, CFG_ChannelID
    if (!CFG_DiscordEnable || CFG_BotToken = "" || CFG_ChannelID = "")
        return
    try {
        http := ComObject("WinHttp.WinHttpRequest.5.1")
        http.Open("POST", "https://discord.com/api/v10/channels/" CFG_ChannelID "/messages", false)
        http.SetRequestHeader("Authorization", "Bot " CFG_BotToken)
        http.SetRequestHeader("Content-Type", "application/json")
        safeMsg := StrReplace(StrReplace(msg, "\", "\\"), '"', '\"')
        http.Send('{"content":"' safeMsg '"}')
    } catch as e {
        RelayLog("[DISCORD ERROR] " e.Message, "error")
    }
}

; =========================================
; DAILY RECONNECT
; =========================================

CheckDailyReconnect() {
    global CFG_ReconnectEnable, CFG_ReconnectTime, CFG_ReconnectMainOnly
    global ReconnectLastDate, AltMyRole

    if (!CFG_ReconnectEnable)
        return
    if (CFG_ReconnectMainOnly && AltMyRole != "Main")
        return

    nowHHMM := FormatTime(A_Now, "HH:mm")
    today   := FormatTime(A_Now, "yyyyMMdd")

    if (nowHHMM != CFG_ReconnectTime || ReconnectLastDate = today)
        return

    ReconnectLastDate := today
    RelayLog("[RECONNECT] Daily reconnect at " nowHHMM)
    DiscordSend("🔄 Daily reconnect triggered at " nowHHMM)
    DisconnectCheck(1)
}

; =========================================
; LOGGING
; =========================================

RelayLog(msg, logType := "relay") {
    global CFG_LOG
    try FileAppend(A_Now " " msg "`n", CFG_LOG)
    RMAppendLog(msg, logType)
}

RMAppendLog(msg, logType := "relay") {
    global RelayGui
    try {
        if !IsObject(RelayGui)
            return
        ctrl := (logType = "error") ? "RMErrorLog" : (logType = "status") ? "RMStatusLog" : "RMRelayLog"
        RelayGui[ctrl].Value .= A_Now " " msg "`n"
        if (RelayGui["RMAutoScroll"].Value)
            SendMessage(0x115, 7, 0, RelayGui[ctrl])   ; WM_VSCROLL SB_BOTTOM
    }
}

; =========================================
; NATRO RELAY TABS
; =========================================

CreateRelayMainTab() {
    global MainGui, TabCtrl
    TabCtrl.UseTab("Relay Main")

    MainGui.SetFont("s8 cDefault Norm", "Tahoma")
    MainGui.Add("Text", "x10 y28 w70 +BackgroundTrans", "Status:")
    MainGui.Add("Text", "x80 y28 w200 vRelayStatusSmall +BackgroundTrans", "● Offline")
    MainGui.Add("Text", "x10 y44 w70 +BackgroundTrans", "Server:")
    MainGui.Add("Text", "x80 y44 w200 vRelayServerStatus +BackgroundTrans", "Not running")
    MainGui.Add("Text", "x10 y60 w70 +BackgroundTrans", "Bridge:")
    MainGui.Add("Text", "x80 y60 w200 vRelayBridgeStatus +BackgroundTrans", "Not running")
    MainGui.Add("Text", "x10 y76 w70 +BackgroundTrans", "Connected:")
    MainGui.Add("Text", "x80 y76 w200 vRelayConnected +BackgroundTrans", "No")

    MainGui.Add("Text", "x10 y94 w460 h1 0x7")

    MainGui.Add("Button", "x10 y100 w110 h20", "Start as HOST").OnEvent("Click", RelayStartHost)
    MainGui.Add("Button", "x125 y100 w110 h20", "Stop Relay").OnEvent("Click", RelayStop)
    MainGui.Add("Button", "x10 y124 w225 h20", "Open Manager").OnEvent("Click", OpenRelayManager)
}

CreateRelayClientTab() {
    global MainGui, TabCtrl, AltClientName

    TabCtrl.UseTab("Relay Client")

    MainGui.SetFont("s8 cDefault Norm", "Tahoma")
    MainGui.Add("Text", "x10 y28 w70 +BackgroundTrans", "Bridge:")
    MainGui.Add("Text", "x80 y28 w200 vRelayBridgeRunning +BackgroundTrans", "● Not running")
    MainGui.Add("Text", "x10 y44 w70 +BackgroundTrans", "Connected:")
    MainGui.Add("Text", "x80 y44 w200 vRelayClientConnected +BackgroundTrans", "No")

    MainGui.Add("Text", "x10 y62 w460 h1 0x7")

    MainGui.Add("Text", "x10 y70 w70 +BackgroundTrans", "Client Name:")
    MainGui.Add("Edit", "x80 y68 w150 h20 vRelayClientName", IsSet(AltClientName) ? AltClientName : "")
    MainGui.Add("Button", "x235 y68 w60 h20", "Save").OnEvent("Click", RelaySaveClientName)

    MainGui.Add("Text", "x10 y96 w460 h1 0x7")

    MainGui.Add("Button", "x10  y102 w110 h20", "Start as CLIENT").OnEvent("Click", RelayStartClient)
    MainGui.Add("Button", "x125 y102 w110 h20", "Connect").OnEvent("Click", RelayClientConnect)
    MainGui.Add("Button", "x10  y126 w110 h20", "Stop Relay").OnEvent("Click", RelayStop)
}

RelaySaveClientName(*) {
    global MainGui, AltClientName, CFG_INI, RelayClients, AltMyRole, AltMyMainVIP, AltMyIdleVIP
    AltClientName := MainGui["RelayClientName"].Value
    IniWrite(AltClientName, CFG_INI, "ThisPC", "ClientName")

    AltMyRole := ""
    AltMyMainVIP := ""
    AltMyIdleVIP := ""
    for client in RelayClients {
        if (client.id = AltClientName) {
            AltMyRole    := client.role
            AltMyMainVIP := client.mainVIP
            AltMyIdleVIP := client.idleVIP
            break
        }
    }
    RelayLog("[RELAY] Client name set to: " AltClientName " | Role: " AltMyRole)
}

RelayStartHost(*) {
    global MainGui, RelayServerPID, RelayBridgePID
    SplitPath(A_WorkingDir, , &parentDir)
    bssRelayPath := parentDir "\BSSRelay"

    if (RelayServerPID && ProcessExist(RelayServerPID)) {
        MsgBox("Relay is already running!`n`nClick Stop Relay first.", "BSS Relay", 0x40)
        return
    }

    try {
        if !FileExist(bssRelayPath "\server.js") {
            MsgBox("server.js not found at:`n" bssRelayPath, "Relay Error", 0x10)
            return
        }
        Run("node server.js", bssRelayPath, "Hide", &RelayServerPID)
        Sleep 2000
        Run("node bridge.js", bssRelayPath, "Hide", &RelayBridgePID)
        Sleep 1000
        MainGui["RelayStatusSmall"].Value  := "● Online"
        MainGui["RelayServerStatus"].Value := "Running"
        MainGui["RelayBridgeStatus"].Value := "Running"
        RelayLog("[RELAY] Started as HOST")
    } catch as e {
        MainGui["RelayStatusSmall"].Value := "● Failed"
        RelayLog("[RELAY ERROR] " e.Message, "error")
    }
}

RelayStartClient(*) {
    global MainGui, BridgeRunning, RelayBridgePID
    SplitPath(A_WorkingDir, , &parentDir)
    bssRelayPath := parentDir "\BSSRelay"

    if (RelayBridgePID && ProcessExist(RelayBridgePID)) {
        MsgBox("Bridge is already running!", "BSS Relay", 0x40)
        return
    }

    try {
        if !FileExist(bssRelayPath "\bridge.js") {
            MsgBox("bridge.js not found at:`n" bssRelayPath, "Relay Error", 0x10)
            return
        }
        Run("node bridge.js", bssRelayPath, "Hide", &RelayBridgePID)
        Sleep 1000
        BridgeRunning := true
        MainGui["RelayBridgeRunning"].Value := "● Running"
        RelayLog("[RELAY] Started as CLIENT")
    } catch as e {
        MsgBox("Failed to start bridge.js`n`nError: " e.Message "`n`nMake sure Node.js is installed.", "Relay Error", 0x10)
        RelayLog("[RELAY ERROR] " e.Message, "error")
    }
}

RelayStop(*) {
    global MainGui, WSRegistered, WSConnected, BridgeRunning, RelayServerPID, RelayBridgePID
    try {
        if (RelayServerPID) {
            ProcessClose(RelayServerPID)
            RelayServerPID := 0
        }
        if (RelayBridgePID) {
            ProcessClose(RelayBridgePID)
            RelayBridgePID := 0
        }
        try MainGui["RelayStatusSmall"].Value     := "● Offline"
        try MainGui["RelayServerStatus"].Value    := "Not running"
        try MainGui["RelayBridgeStatus"].Value    := "Not running"
        try MainGui["RelayConnected"].Value       := "No"
        try MainGui["RelayBridgeRunning"].Value   := "● Not running"
        try MainGui["RelayClientConnected"].Value := "No"
        WSRegistered  := false
        WSConnected   := false
        BridgeRunning := false
        RelayLog("[RELAY] Stopped")
    } catch as e {
        RelayLog("[RELAY ERROR] Stop failed: " e.Message, "error")
    }
}

; =========================================
; RELAY MANAGER WINDOW
; =========================================

OpenRelayManager(*) {
    global RelayGui, RelayClients, WSConnected, CFG_LOG
    global CFG_ServerIP, CFG_Port, CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    global CFG_DiscordEnable, CFG_BotToken, CFG_UserID, CFG_ChannelID, CFG_BotPrefix
    global CFG_AttackCycleStart, CFG_AttackTimeout
    global CFG_ReconnectEnable, CFG_ReconnectTime, CFG_ReconnectPer24h, CFG_ReconnectMainOnly
    global CFG_GuideNonPineMins, CFG_GuideGatherField, CFG_GuideFieldBluf, CFG_GuideFieldBamb
    global CFG_TadReturnField, CFG_TadPreTadEnable, CFG_TadPreTadClientID, CFG_TadPreTadField
    global FieldList

    try RelayGui.Destroy()

    RelayGui := Gui("+Resize +MinSize1000x600", "BSS Relay Manager")
    RelayGui.BackColor := "161625"
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")

    ; ===== HEADER =====
    RelayGui.SetFont("s13 w700 c00D4FF", "Consolas")
    RelayGui.Add("Text", "x16 y14 w400", "BSS RELAY MANAGER")
    RelayGui.SetFont("s7 c555570", "Consolas")
    RelayGui.Add("Text", "x16 y34 w400", "WebSocket Alt Coordinator  //  v2.1")
    RelayGui.SetFont("s8 w700 cFF4444", "Consolas")
    RelayGui.Add("Text", "x820 y18 w160 +Right vRMStatusPill", "● DISCONNECTED")
    RelayGui.Add("Text", "x0 y52 w1200 h1 0x7")

    ; ===== LEFT PANEL - Main Config =====
    RelayGui.SetFont("s7 w700 c00D4FF", "Consolas")
    RelayGui.Add("Text", "x10 y62 w230 +Center", "MAIN CONFIGURATION")
    RelayGui.Add("Text", "x10 y72 w230 h1 0x7")

    y := 82

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ WEBSOCKET")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("Text", "x10 y" y " w80", "Server IP")
    RelayGui.Add("Edit", "x95 y" (y-2) " w145 h18 vRMServerIP Background1e1e32 cC8C8D4", CFG_ServerIP)
    y += 22
    RelayGui.Add("Text", "x10 y" y " w80", "Port")
    RelayGui.Add("Edit", "x95 y" (y-2) " w60 h18 vRMPort Background1e1e32 cC8C8D4", CFG_Port)
    y += 26
    RelayGui.Add("Button", "x10 y" y " w230 h22 vRMConnectBtn", "CONNECT TO RELAY").OnEvent("Click", RMConnect)
    y += 32

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ VIP LINKS")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    for label, key in Map("Main VIP", "RMMainVIP", "Idle VIP", "RMIdleVIP", "Sub VIP", "RMSubVIP", "Extra VIP", "RMExtraVIP") {
        RelayGui.Add("Text", "x10 y" y " w80", label)
        val := (key = "RMMainVIP") ? CFG_MainVIP : (key = "RMIdleVIP") ? CFG_IdleVIP : (key = "RMSubVIP") ? CFG_SubVIP : CFG_ExtraVIP
        RelayGui.Add("Edit", "x95 y" (y-2) " w145 h18 v" key " Background1e1e32 cC8C8D4", val)
        y += 22
    }
    y += 8

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ TADPOLE ALT PARAMETERS")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("Text", "x10 y" y " w230", "Return Field For Tad Alts")
    y += 16
    (ddl := RelayGui.Add("DropDownList", "x10 y" y " w230 vRMTadReturnField Background1e1e32 cC8C8D4", FieldList))
    ddl.Text := CFG_TadReturnField
    y += 24
    RelayGui.Add("CheckBox", "x10 y" y " cC8C8D4 Background161625 vRMTadPreTadEnable Checked" CFG_TadPreTadEnable, "Enable Pre Tad")
    y += 22
    RelayGui.Add("Text", "x10 y" y " w80", "Pre Tad Client ID")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w230 h18 vRMTadPreTadClientID Background1e1e32 cC8C8D4", CFG_TadPreTadClientID)
    y += 24
    RelayGui.Add("Text", "x10 y" y " w80", "Pre Tad Field")
    y += 16
    (ddl2 := RelayGui.Add("DropDownList", "x10 y" y " w230 vRMTadPreTadField Background1e1e32 cC8C8D4", FieldList))
    ddl2.Text := CFG_TadPreTadField
    y += 32

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ GUIDE ALT PARAMETERS")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("Text", "x10 y" y " w230", "Allow Non-Pine Guiding Stars X Mins Before BFB")
    y += 30
    RelayGui.Add("Edit", "x10 y" y " w50 h18 vRMGuideNonPineMins Background1e1e32 cC8C8D4", CFG_GuideNonPineMins)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "Guide Alt Gather Field")
    y += 16
    (ddl3 := RelayGui.Add("DropDownList", "x10 y" y " w230 vRMGuideGatherField Background1e1e32 cC8C8D4", FieldList))
    ddl3.Text := CFG_GuideGatherField
    y += 24
    RelayGui.Add("Text", "x10 y" y, "Gather Field (Blue Flower Boost)")
    y += 16
    (ddl4 := RelayGui.Add("DropDownList", "x10 y" y " w230 vRMGuideFieldBluf Background1e1e32 cC8C8D4", FieldList))
    ddl4.Text := CFG_GuideFieldBluf
    y += 24
    RelayGui.Add("Text", "x10 y" y, "Gather Field (Bamboo Boost)")
    y += 16
    (ddl5 := RelayGui.Add("DropDownList", "x10 y" y " w230 vRMGuideFieldBamb Background1e1e32 cC8C8D4", FieldList))
    ddl5.Text := CFG_GuideFieldBamb
    y += 32

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ ATTACK ALT PARAMETERS")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "Attack Cycle Start (min of each hour)")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w50 h18 vRMAttackCycleStart Background1e1e32 cC8C8D4", CFG_AttackCycleStart)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "Alt Timeout Past Mondo Spawn (min)")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w50 h18 vRMAttackTimeout Background1e1e32 cC8C8D4", CFG_AttackTimeout)
    y += 32

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ DAILY RECONNECT")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("CheckBox", "x10 y" y " cC8C8D4 Background161625 vRMReconnectEnable Checked" CFG_ReconnectEnable, "Enable Daily Reconnect")
    y += 22
    RelayGui.Add("Text", "x10 y" y, "Reconnect Time (HH:mm)")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w80 h18 vRMReconnectTime Background1e1e32 cC8C8D4", CFG_ReconnectTime)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "Number of Reconnects Per 24h")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w50 h18 vRMReconnectPer24h Background1e1e32 cC8C8D4", CFG_ReconnectPer24h)
    y += 26
    RelayGui.Add("CheckBox", "x10 y" y " cC8C8D4 Background161625 vRMReconnectMainOnly Checked" CFG_ReconnectMainOnly, "Only Reconnect Main Server")
    y += 32

    RelayGui.SetFont("s7 w700 c888899", "Consolas")
    RelayGui.Add("Text", "x10 y" y, "▼ DISCORD BOT")
    y += 14
    RelayGui.SetFont("s8 cC8C8D4", "Consolas")
    RelayGui.Add("CheckBox", "x10 y" y " cC8C8D4 Background161625 vRMDiscordEnable Checked" CFG_DiscordEnable, "Enable Discord Bot")
    y += 22
    RelayGui.Add("Text", "x10 y" y, "Bot Token")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w230 h18 vRMBotToken Background1e1e32 cC8C8D4 +Password", CFG_BotToken)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "User ID")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w230 h18 vRMUserID Background1e1e32 cC8C8D4", CFG_UserID)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "Channel ID")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w230 h18 vRMChannelID Background1e1e32 cC8C8D4", CFG_ChannelID)
    y += 26
    RelayGui.Add("Text", "x10 y" y, "Bot Prefix")
    y += 16
    RelayGui.Add("Edit", "x10 y" y " w50 h18 vRMBotPrefix Background1e1e32 cC8C8D4", CFG_BotPrefix)
    y += 32

    RelayGui.SetFont("s8 w700", "Consolas")
    RelayGui.Add("Button", "x10 y" y " w230 h24", "SAVE CONFIG").OnEvent("Click", RMSaveConfig)

    RelayGui.Add("Text", "x248 y58 w1 h" (y + 40) " 0x7")

    ; ===== CENTER PANEL - Clients =====
    RelayGui.SetFont("s7 w700 c00D4FF", "Consolas")
    RelayGui.Add("Text", "x258 y62 w390 +Center", "CLIENT CONFIGURATION")
    RelayGui.Add("Text", "x258 y72 w390 h1 0x7")
    RelayGui.Add("Text", "x258 y80 w390 h560 Border vRMClientArea Background1a1a2a")
    RelayGui.Add("Button", "x258 y648 w390 h22", "+ ADD CLIENT").OnEvent("Click", RMAddClient)

    RelayGui.Add("Text", "x653 y58 w1 h620 0x7")

    ; ===== RIGHT PANEL - Live Status + Log =====
    RelayGui.SetFont("s7 w700 c00D4FF", "Consolas")
    RelayGui.Add("Text", "x663 y62 w300 +Center", "LIVE STATUS")
    RelayGui.Add("Text", "x663 y72 w300 h1 0x7")

    RelayGui.SetFont("s7 cC8C8D4", "Consolas")
    RelayGui.Add("Edit", "x663 y80 w298 h120 vRMLiveStatus +ReadOnly Background111122 cC8C8D4", "No clients configured")

    RelayGui.SetFont("s7 w700 c00D4FF", "Consolas")
    RelayGui.Add("Text", "x663 y210 w300 +Center", "LOG")
    RelayGui.Add("Text", "x663 y220 w300 h1 0x7")

    RelayGui.SetFont("s7 w700", "Consolas")
    RelayGui.Add("Button", "x663 y226 w98 h18 vRMTabRelay",  "RELAY").OnEvent("Click",  (*) => RMShowTab("relay"))
    RelayGui.Add("Button", "x763 y226 w98 h18 vRMTabError",  "ERRORS").OnEvent("Click", (*) => RMShowTab("error"))
    RelayGui.Add("Button", "x863 y226 w98 h18 vRMTabStatus", "STATUS").OnEvent("Click", (*) => RMShowTab("status"))

    RelayGui.SetFont("s7 cC8C8D4", "Consolas")
    RelayGui.Add("Edit", "x663 y248 w298 h372 vRMRelayLog  +ReadOnly -Wrap Background111122 cC8C8D4 +0x100000")
    RelayGui.Add("Edit", "x663 y248 w298 h372 vRMErrorLog  +ReadOnly -Wrap Background111122 cFF6666 Hidden +0x100000")
    RelayGui.Add("Edit", "x663 y248 w298 h372 vRMStatusLog +ReadOnly -Wrap Background111122 c00FF88 Hidden +0x100000")

    RelayGui.Add("Button", "x830 y626 w130 h20", "CLEAR LOG").OnEvent("Click", RMClearLog)
    RelayGui.Add("CheckBox", "x663 y629 cC8C8D4 Background161625 vRMAutoScroll Checked1", "Auto-scroll")

    RelayGui.Show("w975 h680")
    RMShowTab("relay")
    RMRenderClients()
    RMUpdateClientStatus()

    try {
        logContent := FileRead(CFG_LOG)
        RelayGui["RMRelayLog"].Value := logContent
    }

    if (WSConnected) {
        RelayGui["RMStatusPill"].Value := "● CONNECTED"
        RelayGui["RMStatusPill"].SetFont("c00FF88")
    } else {
        RelayGui["RMStatusPill"].Value := "● DISCONNECTED"
        RelayGui["RMStatusPill"].SetFont("cFF4444")
    }
}

; ===== LIVE CLIENT STATUS PANEL =====

RMUpdateClientStatus() {
    global RelayGui, RelayClients, RelayClientStatus
    try {
        if !IsObject(RelayGui)
            return
        statusText := ""
        for client in RelayClients {
            online     := RelayClientStatus.Has(client.id) && (RelayClientStatus[client.id] = "online")
            dot        := online ? "● " : "○ "
            statusText .= dot client.id " [" client.role "]`n"
        }
        RelayGui["RMLiveStatus"].Value := statusText != "" ? statusText : "No clients configured"
    }
}

; ===== RENDER CLIENTS =====

RMRenderClients() {
    global RelayGui, RelayClients, RelayClientStatus

    roleList     := ["Main", "Tad", "Balloon", "Guide", "Attack", "Helper", "Ignored"]
    vipList      := ["None", "Main VIP", "Idle VIP", "Sub VIP", "Extra VIP"]
    needsIdleVIP := ["Attack", "Guide", "Helper", "Balloon"]

    i := 1
    for client in RelayClients {
        y      := 88 + (i - 1) * 155
        online := RelayClientStatus.Has(client.id) && (RelayClientStatus[client.id] = "online")

        RelayGui.SetFont("s7 w700 c00D4FF", "Consolas")
        RelayGui.Add("Text", "x265 y" y " w85", "CLIENT " i)
        RelayGui.SetFont("s7 w700 " (online ? "c00FF88" : "c888899"), "Consolas")
        RelayGui.Add("Text", "x350 y" y " w60", online ? "● ONLINE" : "○ OFFLINE")
        RelayGui.SetFont("s8 cC8C8D4", "Consolas")
        RelayGui.Add("Button", "x595 y" (y-1) " w45 h15 vRMDel" i, "DELETE").OnEvent("Click", RMDeleteClient.Bind(i))

        RelayGui.Add("Text", "x265 y" (y+18) " w65", "Client ID")
        RelayGui.Add("Edit", "x335 y" (y+16) " w200 h18 vRMCID" i " Background1e1e32 cC8C8D4", client.id)

        RelayGui.Add("Text", "x265 y" (y+40) " w65", "User ID")
        RelayGui.Add("Edit", "x335 y" (y+38) " w200 h18 vRMCUserID" i " Background1e1e32 cC8C8D4", client.userID)

        RelayGui.Add("Text", "x265 y" (y+62) " w65", "Role")
        (ddl := RelayGui.Add("DropDownList", "x335 y" (y+60) " w120 vRMCRole" i " Background1e1e32 cC8C8D4", roleList))
        ddl.Text := client.role
        ddl.OnEvent("Change", RMClientRoleChanged.Bind(i))

        RelayGui.Add("Text", "x265 y" (y+84) " w65", "Main VIP")
        (ddl2 := RelayGui.Add("DropDownList", "x335 y" (y+82) " w120 vRMCMainVIP" i " Background1e1e32 cC8C8D4", vipList))
        ddl2.Text := client.mainVIP

        showIdle := false
        for role in needsIdleVIP
            if (client.role = role)
                showIdle := true

        RelayGui.Add("Text", "x265 y" (y+106) " w65 vRMCIdleVIPLabel" i, "Idle VIP")
        (ddl3 := RelayGui.Add("DropDownList", "x335 y" (y+104) " w120 vRMCIdleVIP" i " Background1e1e32 cC8C8D4", vipList))
        ddl3.Text := client.idleVIP
        RelayGui["RMCIdleVIPLabel" i].Visible := showIdle
        RelayGui["RMCIdleVIP" i].Visible      := showIdle

        RelayGui.Add("Text", "x260 y" (y+128) " w382 h1 0x7")
        i++
    }
}

RMClientRoleChanged(index, ctrl, *) {
    global RelayGui
    needsIdleVIP := ["Attack", "Guide", "Helper", "Balloon"]
    showIdle := false
    for role in needsIdleVIP
        if (ctrl.Text = role)
            showIdle := true
    RelayGui["RMCIdleVIPLabel" index].Visible := showIdle
    RelayGui["RMCIdleVIP"      index].Visible := showIdle
}

; ===== ADD / DELETE CLIENT =====

RMAddClient(*) {
    global RelayClients
    RelayClients.Push({
        id:      "client_" RelayClients.Length + 1,
        userID:  "",
        role:    "Tad",
        mainVIP: "Main VIP",
        idleVIP: "Idle VIP"
    })
    SaveConfig()
    try RelayGui.Destroy()
    OpenRelayManager()
}

RMDeleteClient(index, *) {
    global RelayClients
    RelayClients.RemoveAt(index)
    SaveConfig()
    try RelayGui.Destroy()
    OpenRelayManager()
}

; ===== CONNECT =====

RMConnect(*) {
    global RelayGui, WSHost, WSPort, WSRegistered, WSInbox, WSOutbox, WSConnecting, WSConnected, AltClientName

    if (WSConnected) {
        MsgBox("Already connected to relay!", "BSS Relay", 0x40)
        return
    }

    WSConnecting := true
    WSHost := RelayGui["RMServerIP"].Value
    WSPort := RelayGui["RMPort"].Value

    RelayGui["RMStatusPill"].Value := "● CONNECTING..."
    RelayGui["RMStatusPill"].SetFont("c00D4FF")

    WSWrite("REGISTER|" AltClientName "|unknown")

    startTime := A_TickCount
    while (A_TickCount - startTime < 5000) {
        try {
            content := FileRead(WSInbox)
            if (InStr(content, "ACK")) {
                WSConnecting := false
                WSConnected  := true
                try FileDelete(WSInbox)
                WSRegistered := true
                RelayGui["RMStatusPill"].Value := "● CONNECTED"
                RelayGui["RMStatusPill"].SetFont("c00FF88")
                RMAppendLog("[WS] Connected as Main")
                try MainGui["RelayConnected"].Value := "Yes - Main"
                WinActivate("BSS Relay Manager")
                WSStartPolling()
                StartAttackTimer()
                SendRelayVIP()
                return
            }
        }
        Sleep 200
    }

    WSConnecting := false
    WSRegistered := false
    WSConnected  := false
    RelayGui["RMStatusPill"].Value := "● FAILED"
    RelayGui["RMStatusPill"].SetFont("cFF4444")
    RMAppendLog("[WS] Connection failed - no ACK", "error")
    MsgBox("Connection failed!`n`nMake sure:`n1. server.js is running`n2. bridge.js is running`n3. IP is " WSHost "`n4. Port is " WSPort, "BSS Relay - Failed", 0x10)
    WinActivate("BSS Relay Manager")
}

RelayClientConnect(*) {
    global WSConnected, WSConnecting, WSInbox, WSOutbox, AltClientName, MainGui, BridgeRunning

    if (WSConnected) {
        MsgBox("Already connected!", "BSS Relay", 0x40)
        return
    }

    if (AltClientName = "") {
        MsgBox("No Client Name set!`n`nSet your Client Name and click Save first.", "Relay Error", 0x10)
        return
    }

    nodeRunning := false
    try {
        RunWait('cmd.exe /c tasklist /fi "imagename eq node.exe" /fo csv /nh > "%TEMP%\nodechk.txt"', , "Hide")
        if InStr(FileRead(A_Temp "\nodechk.txt"), "node.exe")
            nodeRunning := true
    }

    if (!nodeRunning) {
        MsgBox("Bridge is not running!`n`nClick 'Start as CLIENT' first.", "Relay Error", 0x10)
        return
    }

    if !FileExist(WSOutbox) {
        MsgBox("Cannot reach relay.`n`nOutbox not found at:`n" WSOutbox "`n`nMake sure:`n1. Click 'Start as CLIENT' first`n2. BSSRelay folder exists", "Relay Error", 0x10)
        return
    }

    WSConnecting := true
    WSWrite("REGISTER|" AltClientName "|unknown")

    startTime := A_TickCount
    while (A_TickCount - startTime < 5000) {
        try {
            content := FileRead(WSInbox)
            if (InStr(content, "ACK")) {
                WSConnecting := false
                WSConnected  := true
                try FileDelete(WSInbox)
                MainGui["RelayClientConnected"].Value := "Yes - " AltClientName
                MainGui["RelayBridgeRunning"].Value   := "● Running"
                RelayLog("[WS] Connected as " AltClientName)
                WSStartPolling()
                return
            }
        }
        Sleep 200
    }

    WSConnecting := false
    WSConnected  := false
    RelayLog("[WS] Connection failed", "error")
    MsgBox("Connection timed out.`n`nChecklist:`n1. Is main PC running as HOST?`n2. Check Task Manager for node.exe", "Relay - Failed", 0x10)
}

; ===== SAVE CONFIG FROM GUI =====

RMSaveConfig(*) {
    global RelayGui
    global CFG_ServerIP, CFG_Port, CFG_MainVIP, CFG_IdleVIP, CFG_SubVIP, CFG_ExtraVIP
    global CFG_DiscordEnable, CFG_BotToken, CFG_UserID, CFG_ChannelID, CFG_BotPrefix
    global CFG_AttackCycleStart, CFG_AttackTimeout
    global CFG_ReconnectEnable, CFG_ReconnectTime, CFG_ReconnectPer24h, CFG_ReconnectMainOnly
    global CFG_GuideNonPineMins, CFG_GuideGatherField, CFG_GuideFieldBluf, CFG_GuideFieldBamb
    global CFG_TadReturnField, CFG_TadPreTadEnable, CFG_TadPreTadClientID, CFG_TadPreTadField
    global WSHost, WSPort, RelayClients

    try {
        CFG_ServerIP          := RelayGui["RMServerIP"].Value
        CFG_Port              := RelayGui["RMPort"].Value
        CFG_MainVIP           := RelayGui["RMMainVIP"].Value
        CFG_IdleVIP           := RelayGui["RMIdleVIP"].Value
        CFG_SubVIP            := RelayGui["RMSubVIP"].Value
        CFG_ExtraVIP          := RelayGui["RMExtraVIP"].Value
        CFG_DiscordEnable     := RelayGui["RMDiscordEnable"].Value
        CFG_BotToken          := RelayGui["RMBotToken"].Value
        CFG_UserID            := RelayGui["RMUserID"].Value
        CFG_ChannelID         := RelayGui["RMChannelID"].Value
        CFG_BotPrefix         := RelayGui["RMBotPrefix"].Value
        CFG_AttackCycleStart  := RelayGui["RMAttackCycleStart"].Value
        CFG_AttackTimeout     := RelayGui["RMAttackTimeout"].Value
        CFG_ReconnectEnable   := RelayGui["RMReconnectEnable"].Value
        CFG_ReconnectTime     := RelayGui["RMReconnectTime"].Value
        CFG_ReconnectPer24h   := RelayGui["RMReconnectPer24h"].Value
        CFG_ReconnectMainOnly := RelayGui["RMReconnectMainOnly"].Value
        CFG_GuideNonPineMins  := RelayGui["RMGuideNonPineMins"].Value
        CFG_GuideGatherField  := RelayGui["RMGuideGatherField"].Value
        CFG_GuideFieldBluf    := RelayGui["RMGuideFieldBluf"].Value
        CFG_GuideFieldBamb    := RelayGui["RMGuideFieldBamb"].Value
        CFG_TadReturnField    := RelayGui["RMTadReturnField"].Value
        CFG_TadPreTadEnable   := RelayGui["RMTadPreTadEnable"].Value
        CFG_TadPreTadClientID := RelayGui["RMTadPreTadClientID"].Value
        CFG_TadPreTadField    := RelayGui["RMTadPreTadField"].Value

        loop RelayClients.Length {
            try RelayClients[A_Index].id      := RelayGui["RMCID"      A_Index].Value
            try RelayClients[A_Index].role    := RelayGui["RMCRole"    A_Index].Value
            try RelayClients[A_Index].mainVIP := RelayGui["RMCMainVIP" A_Index].Value
            try RelayClients[A_Index].userID  := RelayGui["RMCUserID"  A_Index].Value
            try RelayClients[A_Index].idleVIP := RelayGui["RMCIdleVIP" A_Index].Value
        }

        WSHost := CFG_ServerIP
        WSPort := CFG_Port

        SaveConfig()
        RMAppendLog("[CONFIG] Saved successfully")
    } catch as e {
        RMAppendLog("[CONFIG ERROR] " e.Message, "error")
    }
}

; ===== TAB / LOG HELPERS =====

RMShowTab(tab) {
    global RelayGui
    try {
        RelayGui["RMRelayLog"].Visible  := (tab = "relay")
        RelayGui["RMErrorLog"].Visible  := (tab = "error")
        RelayGui["RMStatusLog"].Visible := (tab = "status")
    }
}

RMClearLog(*) {
    global RelayGui, CFG_LOG
    try RelayGui["RMRelayLog"].Value  := ""
    try RelayGui["RMErrorLog"].Value  := ""
    try RelayGui["RMStatusLog"].Value := ""
    try FileDelete(CFG_LOG)
}
