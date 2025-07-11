SendMode Input
SetWorkingDir %A_ScriptDir%
#include windmouse.ahk
#SingleInstance Force
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
    wait := Random 200, 500
    Sleep wait
}

largeRandWait() {
    wait := Random 20000, 30000
    Sleep wait
}

maybeMoveMouseAround(max := 0.9) {
    ticket := Random 0, 1
    totalSleep := 0
    ; if (true) {
        elements := Random 2, 6
        xArr := Array()
        yArr := Array()
        sleepArr := Array()
        indexes := Array()
        curIdx := 1
        totalSleep := 0
        loop %elements% {
            rx := Random - 1000, 1000
            ry := Random - 1000, 1000
            rs := Random 500, 50000
            xArr.add(rx)
            yArr.add(ry)
            sleepArr.add(rs)
            indexes.add(curIdx)
            curIdx++
        }

        for i, v IN indexes {
            totalSleep += sleepArr[v]
            MoveMouse(xArr[v], yArr[v])
            Sleep sleepArr[v]
        }

    ; ;}
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
    ;move mouse over bank first
    maybeMoveMouseAround()
    ; MoveMouse(bankX, bankY, 0.6, 50)
    ; ; hovering over the bank
    ; smallRandWait()
    ; humanClick() ; bank opened

    ; loop ;{
    ;     if not toggle
    ;         break
    ;     ; bank is open here
    ;     smallRandWait()
    ;     maybeMoveMouseAround()
    ;     ; move mouse to item
    ;     MoveMouse(bankItemX, bankItemY, 0.6)
    ;     smallRandWait()
    ;     humanClick()
    ;     smallRandWait()
    ;     ; close bank
    ;     Send "{ Escape }"
    ;     smallRandWait()
    ;     maybeMoveMouseAround()
    ;     ; move mouse to invy slot 1
    ;     MoveMouse(invy1X, invy1Y)
    ;     smallRandWait()
    ;     humanClick() ;use item
    ;     smallRandWait()
    ;     MoveMouse(invy2X, invy2Y, 1)
    ;     smallRandWait()
    ;     humanClick() ; slot 2
    ;     smallRandWait()
    ;     Send "{Space}"
    ;     ret := maybeMoveMouseAround(0.9)
    ;     remaining := 50000 - ret
    ;     if (remaining > 0) {
    ;         Sleep ret
    ;     }
    ;     largeRandWait()
    ;     maybeMoveMouseAround()
    ;     ; back to bank
    ;     MoveMouse(bankX, bankY, 0.6, 50)
    ;     smallRandWait()
    ;     humanClick()
    ;     smallRandWait()
    ;     MoveMouse(depX, depY)
    ;     smallRandWait()
    ;     humanClick() ;deposit
    ;     largeRandWait()
    ;     maybeMoveMouseAround()
    ; }
}
