#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2
#SingleInstance Force
#Include windmouse_v2.ahk

;========================= CONFIGURABLE CONSTANTS =============================;
; Target click area (the "go" click) - PLACEHOLDER: set to your client coords
TARGET_X_MIN := 513
TARGET_X_MAX := 522
TARGET_Y_MIN := 209
TARGET_Y_MAX := 220

; Gate click area - PLACEHOLDER: set to your client coords
GATE_X_MIN := 386
GATE_X_MAX := 393
GATE_Y_MIN := 206
GATE_Y_MAX := 212

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
SKIP_CHANCE := 12            ; % chance to intentionally miss the go tick
DRIFT_CHANCE := 40           ; % chance to do an idle mouse drift during waits
GATE_CLICK_MIN := 4          ; earliest tick after respawn to click gate
GATE_CLICK_MAX := 7          ; latest tick after respawn to click gate
EARLY_MIN := 2               ; arrive at target this many ticks early (minimum)
EARLY_MAX := 5               ; arrive at target this many ticks early (maximum)
;==============================================================================;

toggle := 0

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

; WindMouse to a random point within a rectangle
moveToArea(xMin, xMax, yMin, yMax) {
    targetX := Random(xMin, xMax)
    targetY := Random(yMin, yMax)
    MoveMouse(targetX, targetY, 0.6, 0)
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

    ; Gate phase: click gate quickly after respawn (2-5 ticks)
    gateClickTick := Random(GATE_CLICK_MIN, GATE_CLICK_MAX)
    plan["gateClickTick"] := gateClickTick
    plan["gateReaction"] := Random(50, 200)                         ; pause before gate click (ms)
    plan["gateClickHold"] := Random(80, 180)                         ; gate click hold time (ms)

    ; Gate budget = time from respawn to gate click (in ms)
    ; Known micro-delays that happen right before the click
    plan["gateKnownMs"] := plan["gateReaction"] + plan["gateClickHold"]
    plan["gateBudgetMs"] := gateClickTick * TICK_MS

    ; Post-gate phase: wait on other side, then click target at go tick
    ; Post-gate budget = 22 - gateClickTick = ticks remaining after gate click
    postGateTicks := RESPAWN_TICKS - gateClickTick
    plan["postGateBudgetMs"] := postGateTicks * TICK_MS

    ; Target arrival randoms
    plan["arriveEarly"] := Random(EARLY_MIN, EARLY_MAX)            ; ticks early to arrive at target
    plan["goReaction"] := Random(0, 500)                          ; pause before go click (ms)
    plan["goClickHold"] := Random(80, 180)                         ; go click hold time (ms)
    plan["postGateDrift"] := Random(1, 100) <= DRIFT_CHANCE       ; drift while waiting post-gate?

    ; Target phase: only goReaction is subtracted from the hover budget
    ; goClickHold happens AFTER the go tick (mousedown = go tick, hold follows)
    plan["targetKnownMs"] := plan["goReaction"]

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
    maybeDo(80, idleDrift)

    ; Wait for the action to complete + respawn (38 ticks, use elapsed time)
    firstWaitMs := (ACTION_TICKS * TICK_MS) - (A_TickCount - firstStart)
    if (firstWaitMs > 0)
        waitMs(firstWaitMs)

    ; --- MAIN LOOP: starts at respawn (22 ticks remain in cycle) ---
    loop {
        if not toggle
            break

        ; Pre-roll all random values for this cycle
        plan := rollCyclePlan()
        cycleStart := A_TickCount

        ; 1. SHORT IDLE after respawn, then move to gate and click
        ;    Gate budget = gateClickTick * TICK_MS (1200-3000ms)
        ;    Idle first, then move, then click — all within that budget.
        ;    Reserve ~1200ms for WindMouse + gateKnownMs for reaction/click
        idleBeforeGateMs := plan["gateBudgetMs"] - 1200 - plan["gateKnownMs"]
        if (idleBeforeGateMs > 0)
            waitMs(idleBeforeGateMs)

        ; 2. WINDMOUSE TO GATE then click immediately
        moveToArea(GATE_X_MIN, GATE_X_MAX, GATE_Y_MIN, GATE_Y_MAX)
        Sleep plan["gateReaction"]
        humanClick(plan["gateClickHold"])

        if not toggle
            break

        ; 3. POST-GATE: wait on the other side of the gate
        ;    We're now through the gate with plenty of time before the go tick.
        ;    Drift around or idle to look human.
        if (plan["postGateDrift"])
            idleDrift()

        ; 4. MOVE TO TARGET (arrive early and hover)
        ;    Compute how long to wait before moving, using elapsed wall-clock time
        totalBudgetMs := RESPAWN_TICKS * TICK_MS
        arriveEarlyMs := plan["arriveEarly"] * TICK_MS
        elapsedSoFar := A_TickCount - cycleStart
        ; Wait until it's time to move (total - arriveEarly - targetKnown - elapsed)
        waitBeforeMove := totalBudgetMs - arriveEarlyMs - plan["targetKnownMs"] - elapsedSoFar
        if (waitBeforeMove > 0)
            waitMs(waitBeforeMove)

        if not toggle
            break

        ; 5. WINDMOUSE TO TARGET
        moveToArea(TARGET_X_MIN, TARGET_X_MAX, TARGET_Y_MIN, TARGET_Y_MAX)

        ; Hover at target: fill remaining time before go tick
        elapsedTotal := A_TickCount - cycleStart
        remainMs := totalBudgetMs - elapsedTotal - plan["targetKnownMs"]
        if (remainMs > 0)
            waitMs(remainMs)

        if not toggle
            break

        ; 6. SKIP CHECK - simulate missing the window
        ;    Both skip and click paths wait until cycleStart + 60 ticks (next respawn)
        fullCycleMs := CYCLE_TICKS * TICK_MS

        if (Random(1, 100) <= SKIP_CHANCE) {
            ; Missed it! Idle and wait until next respawn point
            maybeDo(DRIFT_CHANCE, idleDrift)
            skipWaitMs := fullCycleMs - (A_TickCount - cycleStart)
            if (skipWaitMs > 0)
                waitMs(skipWaitMs)
            continue
        }

        ; 7. GO CLICK (reaction + click use pre-rolled durations)
        Sleep plan["goReaction"]
        humanClick(plan["goClickHold"])
        maybeDo(80, idleDrift)

        ; 8. Wait for action to complete + respawn
        ;    Use elapsed time from cycleStart so drift/clicks don't accumulate
        actionWaitMs := fullCycleMs - (A_TickCount - cycleStart)
        if (actionWaitMs > 0)
            waitMs(actionWaitMs)

        ; Loop restarts at respawn point
    }
}
