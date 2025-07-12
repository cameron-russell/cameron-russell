SendMode Input
SetWorkingDir %A_ScriptDir%
#include windmouse.ahk
#SingleInstance Force
#MaxThreadsPerHotkey 2
toggle := 0

;3171, 541 = top left invy 3215, 541 for next
;3005, 503

; move to bank
; wait small random
; click bank
; wait large random amount of time
; move to item
; wait very small random time
; click bottom left item
; wait large random time
; close bank with esc
; wait
; move mouse to invent

humanClick() {
    MouseClick left, , , , , D
    wait := Random 100, 200
    Sleep wait
    MouseClick left, , , , , U
}

smallRandWait() {
    wait := Random 400, 4000 
    Sleep wait
    return wait
}

largeRandWait() {
    wait := Random 20000, 30000
    Sleep wait
    return wait
}

maybeMoveMouseAround(max := 0.25) {
    Random, ticket, 0.0, 1.0
    totalSleep := 0
    if (ticket <= max) {
        Random, elements, 2, 6
        xArr := Array()
        yArr := Array()
        sleepArr := Array()
        totalSleep := 0
        
        loop %elements% {
            Random, rx, -1000, 1000
            Random, ry, -1000, 1000
            Random, rs, 500, 8000
            xArr.Push(rx)
            yArr.Push(ry)
            sleepArr.Push(rs)
        }

        for i, v IN sleepArr {
            totalSleep += v
            MoveMouse(xArr[i], yArr[i])
            Sleep v
        }

    }
    return totalSleep
}

bankItemX := 444
bankItemY := 502
bankX := 407
bankY := 372
invy1X := 611
invy1Y := 540
invy2X := 651
invy2Y := 536
depX := 466
depY := 628

^PgDn::
{

    global toggle := !toggle
    
    ; start from an open bank
    ; move mouse over bank first
    ; maybeMoveMouseAround()
    ; MoveMouse(bankX, bankY, 0.7, 50)
    ; ; hovering over the bank
    ; smallRandWait()
    ; humanClick() ; bank opened

    loop {
        if not toggle
            break
        ; bank is open here
        smallRandWait()
        ; move mouse to item
        MoveMouse(bankItemX, bankItemY, 0.6)
        smallRandWait()
        humanClick()
        smallRandWait()
        ; close bank
        Send "{ Escape }"
        smallRandWait()
        ; move mouse to invy slot 1
        MoveMouse(invy1X, invy1Y)
        smallRandWait()
        humanClick() ;use item
        smallRandWait()
        MoveMouse(invy2X, invy2Y, 1)
        smallRandWait()
        humanClick() ; slot 2
        smallRandWait()
        smallRandWait()
        Send "{Space}"
        lw := largeRandWait()
        ret := maybeMoveMouseAround(0.5)
        remaining := 50000 - ret - lw
        if (remaining > 0) {
            Sleep remaining
        }
        smallRandWait()
        ; back to bank
        MoveMouse(bankX, bankY, 0.6, 50)
        smallRandWait()
        humanClick()
        smallRandWait()
        MoveMouse(depX, depY)
        smallRandWait()
        humanClick() ;deposit
        smallRandWait()
    }
    Random, OutputVar, 1, 2
}
