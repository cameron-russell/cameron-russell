#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2
#SingleInstance Force
#Include windmouse_v2.ahk

;========================= CONFIGURABLE CONSTANTS =============================;
; Target click area (the "go" click) - PLACEHOLDER: set to your client coords
TARGET_X_MIN := 499
TARGET_X_MAX := 514
TARGET_Y_MIN := 233
TARGET_Y_MAX := 246

; Gate click area - PLACEHOLDER: set to your client coords
GATE_X_MIN := 388
GATE_X_MAX := 397
GATE_Y_MIN := 231
GATE_Y_MAX := 239

; Idle area - where the mouse drifts to look human
IDLE_X_MIN := 350
IDLE_X_MAX := 500
IDLE_Y_MIN := 100
IDLE_Y_MAX := 300

; Timing (1 tick = 600ms)
TICK_MS := 600
CYCLE_TICKS := 60           ; ticks between "go" windows
ACTION_TICKS := 38          ; ticks for the action to complete after go click
RESPAWN_TICKS := 22         ; ticks remaining when you respawn before next go tick
GATE_TICKS := 10            ; ticks for gate passage

; Behaviour
DRIFT_CHANCE := 40           ; % chance to do an idle mouse drift during waits
GATE_CLICK_MIN := 4          ; earliest tick after respawn to click gate
GATE_CLICK_MAX := 7          ; latest tick after respawn to click gate
EARLY_MIN := 4               ; arrive at target this many ticks early (minimum)
EARLY_MAX := 8               ; arrive at target this many ticks early (maximum)

; Session / fatigue / breaks
SESSION_MIN := 2              ; minimum cycles per session before break
SESSION_MAX := 5              ; maximum cycles per session
BREAK_MIN := 2               ; minimum break length (in full cycles = 60 ticks each)
BREAK_MAX := 5               ; maximum break length (in full cycles)

;==============================================================================;

toggle := 0
sessionLength := 0           ; how many cycles in this session
cyclesInSession := 0         ; current cycle count within session
consecutiveSuccess := 0      ; consecutive successful go clicks (for skip chance)

; Roll a new session (how many cycles before next break)
rollSession() {
    global SESSION_MIN, SESSION_MAX, sessionLength, cyclesInSession
    sessionLength := Random(SESSION_MIN, SESSION_MAX)
    cyclesInSession := 0
}

; Get fatigue factor (0.0 = fresh, 1.0 = exhausted) based on progress through session
getFatigue() {
    global cyclesInSession, sessionLength
    if (sessionLength <= 1)
        return 0.0
    return cyclesInSession / sessionLength
}

; Get skip chance — increases with consecutive successes (probabilistic expiration)
; Starts at ~5%, ramps up to ~60% after 4-5 in a row
getSkipChance() {
    global consecutiveSuccess
    if (consecutiveSuccess <= 0)
        return 5
    if (consecutiveSuccess >= 5)
        return 100  ; forced break after 5 in a row
    ; Exponential-ish ramp: 5, 12, 25, 45, 100
    chances := [5, 12, 25, 45, 100]
    return chances[consecutiveSuccess]
}

; Human-like click with a specific hold duration (ms)
humanClick(holdMs) {
    MouseClick "left", 0, 0, 1, 0, "D", "R"
    Sleep holdMs
    MouseClick "left", 0, 0, 1, 0, "U", "R"
}

; Maybe perform an action based on a percentage chance
maybeDo(percent, callback) {
    if (Random(1, 100) <= percent)
        callback()
}

; WindMouse to a random point within a rectangle at a given speed and wind (overshoot)
moveToArea(xMin, xMax, yMin, yMax, speed := 0.6, wind := 5) {
    targetX := Random(xMin, xMax)
    targetY := Random(yMin, yMax)
    MoveMouse(targetX, targetY, speed, 0, "", wind)
}

; Idle drift - move mouse to a random spot to look human
idleDrift() {
    global IDLE_X_MIN, IDLE_X_MAX, IDLE_Y_MIN, IDLE_Y_MAX
    moveToArea(IDLE_X_MIN, IDLE_X_MAX, IDLE_Y_MIN, IDLE_Y_MAX)
}

; Wait an exact number of milliseconds
waitMs(ms) {
    if (ms > 0)
        Sleep ms
}

; Wait while making tiny mouse micro-adjustments (human can't hold perfectly still)
; Nudges 1-2px with smooth relative moves, clamped to stay within the target area
hoverWait(ms, xMin, xMax, yMin, yMax) {
    if (ms <= 0)
        return
    start := A_TickCount
    while ((A_TickCount - start) < ms) {
        remaining := ms - (A_TickCount - start)
        nextNudge := Random(600, 1800)
        if (nextNudge > remaining) {
            Sleep remaining
            break
        }
        Sleep nextNudge
        ; Get current position and nudge 1-2px, clamped to target bounds
        MouseGetPos &mx, &my
        dx := Random(-2, 2)
        dy := Random(-2, 2)
        newX := Max(xMin, Min(xMax, mx + dx))
        newY := Max(yMin, Min(yMax, my + dy))
        if (newX != mx or newY != my)
            MouseMove newX, newY, 4  ; speed 4 = slow, smooth built-in move
    }
}

; Pre-roll all random values for one cycle into a Map
; Every random delay is known upfront so we can compute exact fill waits
;
; Timeline (22 ticks total after respawn):
;   [respawn] → small wait → move to gate → click gate
;   → gate passage (10 ticks in-game) → wait on other side → move to target → hover → go click
;
rollCyclePlan() {
    global RESPAWN_TICKS, GATE_TICKS, TICK_MS
    global GATE_CLICK_MIN, GATE_CLICK_MAX
    global EARLY_MIN, EARLY_MAX, DRIFT_CHANCE

    plan := Map()
    fatigue := getFatigue()  ; 0.0 = fresh, 1.0 = exhausted

    ; Fatigue slows reactions and mouse speed
    ; reactionScale: 1.0 (fresh) → 1.8 (tired) — reactions up to 80% slower
    reactionScale := 1.0 + (fatigue * 0.8)
    ; speedPenalty: 0.0 (fresh) → 0.15 (tired) — mouse gets slower
    speedPenalty := fatigue * 0.15

    ; Gate phase: click gate quickly after respawn (4-7 ticks)
    gateClickTick := Random(GATE_CLICK_MIN, GATE_CLICK_MAX)
    plan["gateClickTick"] := gateClickTick
    plan["gateReaction"] := Round(Random(50, 200) * reactionScale)    ; fatigue-scaled
    plan["gateClickHold"] := Round(Random(80, 180) * reactionScale)   ; fatigue-scaled
    plan["gateSpeed"] := (Random(40, 65) / 100) + speedPenalty        ; slower when tired
    plan["gateWind"] := Random(5, 12)                                  ; variable overshoot

    ; Gate budget = time from respawn to gate click (in ms)
    plan["gateKnownMs"] := plan["gateReaction"] + plan["gateClickHold"]
    plan["gateBudgetMs"] := gateClickTick * TICK_MS

    ; Post-gate phase: wait on other side, then click target at go tick
    postGateTicks := RESPAWN_TICKS - gateClickTick
    plan["postGateBudgetMs"] := postGateTicks * TICK_MS

    ; Target arrival randoms
    plan["arriveEarly"] := Random(EARLY_MIN, EARLY_MAX)
    plan["goReaction"] := Round(Random(0, 400) * reactionScale)       ; fatigue-scaled
    plan["goClickHold"] := Round(Random(80, 180) * reactionScale)     ; fatigue-scaled
    plan["postGateDrift"] := Random(1, 100) <= DRIFT_CHANCE
    plan["targetSpeed"] := (Random(55, 85) / 100) + speedPenalty      ; slower when tired
    plan["targetWind"] := Random(5, 12)                                ; variable overshoot

    ; Target phase: goReaction is NOT in the budget — it shifts the click
    ; within the 0.6s tick window so timing varies each cycle
    plan["targetKnownMs"] := 0

    return plan
}

;========================= MAIN HOTKEY ========================================;
!PgDn::
{
    global toggle := !toggle

    if not toggle
        return

    ; --- FIRST ITERATION: user has manually gone through gate ---
    ; User's mouse is already on the target, just click immediately
    firstStart := A_TickCount
    Sleep Random(0, 500)
    humanClick(Random(80, 180))
    consecutiveSuccess := 1
    maybeDo(80, idleDrift)

    ; Wait for the action to complete + respawn (38 ticks, use elapsed time)
    firstWaitMs := (ACTION_TICKS * TICK_MS) - (A_TickCount - firstStart)
    if (firstWaitMs > 0)
        waitMs(firstWaitMs)

    ; Start first session
    rollSession()
    cyclesInSession := 1  ; first iteration counts

    ; --- MAIN LOOP: starts at respawn (22 ticks remain in cycle) ---
    loop {
        if not toggle
            break

        ; Pre-roll all random values for this cycle (fatigue-aware)
        plan := rollCyclePlan()
        cycleStart := A_TickCount

        ; 1. SHORT IDLE after respawn, then move to gate and click
        idleBeforeGateMs := plan["gateBudgetMs"] - 1200 - plan["gateKnownMs"]
        if (idleBeforeGateMs > 0)
            waitMs(idleBeforeGateMs)

        ; 2. WINDMOUSE TO GATE
        moveToArea(GATE_X_MIN, GATE_X_MAX, GATE_Y_MIN, GATE_Y_MAX, plan["gateSpeed"], plan["gateWind"])
        Sleep plan["gateReaction"]
        humanClick(plan["gateClickHold"])

        if not toggle
            break

        ; 3. POST-GATE: wait on the other side of the gate
        if (plan["postGateDrift"])
            idleDrift()

        ; SESSION CHECK: if we've completed this session, take a break (after gate, more natural)
        if (cyclesInSession >= sessionLength) {
            breakCycles := Random(BREAK_MIN, BREAK_MAX)
            breakMs := breakCycles * CYCLE_TICKS * TICK_MS
            waitMs(breakMs)
            ; Shift cycleStart forward so elapsed-time calculations stay aligned
            cycleStart += breakMs
            rollSession()
            consecutiveSuccess := 0
            if not toggle
                break
        }

        ; 4. MOVE TO TARGET (arrive early and hover)
        totalBudgetMs := RESPAWN_TICKS * TICK_MS
        arriveEarlyMs := plan["arriveEarly"] * TICK_MS
        elapsedSoFar := A_TickCount - cycleStart
        waitBeforeMove := totalBudgetMs - arriveEarlyMs - plan["targetKnownMs"] - elapsedSoFar
        if (waitBeforeMove > 0)
            waitMs(waitBeforeMove)

        if not toggle
            break

        ; 5. WINDMOUSE TO TARGET
        moveToArea(TARGET_X_MIN, TARGET_X_MAX, TARGET_Y_MIN, TARGET_Y_MAX, plan["targetSpeed"], plan["targetWind"])

        ; Hover at target: fill remaining time before go tick (with micro-adjustments)
        elapsedTotal := A_TickCount - cycleStart
        remainMs := totalBudgetMs - elapsedTotal - plan["targetKnownMs"]
        if (remainMs > 0)
            hoverWait(remainMs, TARGET_X_MIN, TARGET_X_MAX, TARGET_Y_MIN, TARGET_Y_MAX)

        if not toggle
            break

        ; 6. SKIP CHECK — probability increases with consecutive successes
        fullCycleMs := CYCLE_TICKS * TICK_MS
        skipChance := getSkipChance()

        if (Random(1, 100) <= skipChance) {
            ; Missed it! Reset consecutive counter, wait for next respawn
            consecutiveSuccess := 0
            maybeDo(DRIFT_CHANCE, idleDrift)
            skipWaitMs := fullCycleMs - (A_TickCount - cycleStart)
            if (skipWaitMs > 0)
                waitMs(skipWaitMs)
            continue
        }

        ; 7. GO CLICK
        Sleep plan["goReaction"]
        humanClick(plan["goClickHold"])
        consecutiveSuccess += 1
        cyclesInSession += 1
        maybeDo(80, idleDrift)

        ; 8. Wait for action to complete + respawn
        actionWaitMs := fullCycleMs - (A_TickCount - cycleStart)
        if (actionWaitMs > 0)
            waitMs(actionWaitMs)

        ; Loop restarts at respawn point
    }
}
