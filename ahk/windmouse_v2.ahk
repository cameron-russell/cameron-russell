#Requires AutoHotkey v2.0
;  v2.0 - AHK v2 port of Flight's WindMouse
;  Original: https://github.com/SRL/SRL/blob/master/shared/mouse.simba
;  AHK v1 by: HowDoIStayInDreams and Arekusei | v2 port for this project

CoordMode "Mouse", "Client"
SetMouseDelay -1
ProcessSetPriority "H"

MoveMouse(x, y, speed := 0.6, randomness := 10, RD := "") {
    rxRan := Random(-1 * randomness, randomness)
    ryRan := Random(-1 * randomness, randomness)
    x := x + rxRan
    y := y + ryRan
    if (RD == "RD")
        _goRelative(x, y, speed)
    else
        _goStandard(x, y, speed)
}

;---------------------- helpers ------------------------------------------------;

_Hypot(dx, dy) {
    return Sqrt(dx * dx + dy * dy)
}

_RandomInt(n) {
    return Random(0, n)
}

_PreciseSleep(s) {
    DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
    DllCall("QueryPerformanceCounter", "Int64*", &counterBefore := 0)
    counterAfter := 0
    while (((counterAfter - counterBefore) / freq * 1000) < s)
        DllCall("QueryPerformanceCounter", "Int64*", &counterAfter)
}

_Muller(m, s) {
    static toggle := 0, Y := 0
    if (toggle := !toggle) {
        U := Random(0.001, 1.0)
        V := Random(0.0, 6.2831853071795862)
        U := Sqrt(-2 * Ln(U)) * s
        Y := m + U * Sin(V)
        return m + U * Cos(V)
    }
    return Y
}

_SortArray(arr, order := "A") {
    n := arr.Length
    if (order = "R") {
        result := []
        loop n
            result.Push(arr[n - A_Index + 1])
        arr.Length := 0
        loop result.Length
            arr.Push(result[A_Index])
        return
    }
    loop n - 1 {
        i := A_Index + 1
        key := arr[i]
        j := i - 1
        if (order = "A") {
            while (j >= 1 && arr[j] > key) {
                arr[j + 1] := arr[j]
                j--
            }
        } else {
            while (j >= 1 && arr[j] < key) {
                arr[j + 1] := arr[j]
                j--
            }
        }
        arr[j + 1] := key
    }
}

_RandomWeight(minVal, target, maxVal) {
    Rmin := Random(minVal, target)
    Rmax := Random(target, maxVal)
    return Random(Rmin, Rmax)
}

;---------------------- core WindMouse -----------------------------------------;

_WindMouse(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea, sleepsArray) {
    windX := 0, windY := 0, veloX := 0, veloY := 0
    newX := Round(xs), newY := Round(ys)
    sqrt2 := Sqrt(2), sqrt3 := Sqrt(3), sqrt5 := Sqrt(5)
    dist := _Hypot(xe - xs, ye - ys)
    i := 1, stepVar := maxStep
    loop {
        wind := Min(wind, dist)
        if (dist >= targetArea) {
            windX := windX / sqrt3 + (_RandomInt(Round(wind) * 2 + 1) - wind) / sqrt5
            windY := windY / sqrt3 + (_RandomInt(Round(wind) * 2 + 1) - wind) / sqrt5
            maxStep := _RandomWeight(stepVar / 2, (stepVar + (stepVar / 2)) / 2, stepVar)
        } else {
            windX := windX / sqrt2
            windY := windY / sqrt2
            maxStep := (maxStep < 3) ? 1 : maxStep / 3
        }
        veloX += windX, veloY += windY
        veloX := veloX + gravity * (xe - xs) / dist
        veloY := veloY + gravity * (ye - ys) / dist
        if (_Hypot(veloX, veloY) > maxStep) {
            randomDist := maxStep / 2 + (Round(_RandomInt(maxStep)) / 2)
            veloMag := _Hypot(veloX, veloY)
            veloX := (veloX / veloMag) * randomDist
            veloY := (veloY / veloMag) * randomDist
        }
        oldX := Round(xs), oldY := Round(ys)
        xs += veloX, ys += veloY
        dist := _Hypot(xe - xs, ye - ys)
        if (dist <= 1)
            break
        newX := Round(xs), newY := Round(ys)
        if (oldX != newX) or (oldY != newY)
            MouseMove newX, newY, 0
        c := sleepsArray.Length
        if (i > c) {
            w := Random(Round(sleepsArray[c]), Round(sleepsArray[c]) + 1)
        } else {
            w := Random(Round(sleepsArray[i]), Round(sleepsArray[i]) + 1)
            i++
        }
        _PreciseSleep(Max(Round(Abs(w)), 1))
    }
    endX := Round(xe), endY := Round(ye)
    if (endX != newX) or (endY != newY)
        MouseMove endX, endY, 0
}

_WindMouse2(xs, ys, xe, ye, gravity, wind, minWait, maxWait, maxStep, targetArea) {
    windX := 0, windY := 0, veloX := 0, veloY := 0
    newX := Round(xs), newY := Round(ys)
    waitDiff := maxWait - minWait
    sqrt2 := Sqrt(2), sqrt3 := Sqrt(3), sqrt5 := Sqrt(5)
    dist := _Hypot(xe - xs, ye - ys)
    newArr := []
    stepVar := maxStep
    loop {
        wind := Min(wind, dist)
        if (dist >= targetArea) {
            windX := windX / sqrt3 + (_RandomInt(Round(wind) * 2 + 1) - wind) / sqrt5
            windY := windY / sqrt3 + (_RandomInt(Round(wind) * 2 + 1) - wind) / sqrt5
            maxStep := _RandomWeight(stepVar / 2, (stepVar + (stepVar / 2)) / 2, stepVar)
        } else {
            windX := windX / sqrt2
            windY := windY / sqrt2
            maxStep := (maxStep < 3) ? 1 : maxStep / 3
        }
        veloX += windX, veloY += windY
        veloX := veloX + gravity * (xe - xs) / dist
        veloY := veloY + gravity * (ye - ys) / dist
        if (_Hypot(veloX, veloY) > maxStep) {
            randomDist := maxStep / 2 + (Round(_RandomInt(maxStep)) / 2)
            veloMag := _Hypot(veloX, veloY)
            veloX := (veloX / veloMag) * randomDist
            veloY := (veloY / veloMag) * randomDist
        }
        oldX := Round(xs), oldY := Round(ys)
        xs += veloX, ys += veloY
        dist := _Hypot(xe - xs, ye - ys)
        if (dist <= 1)
            break
        newX := Round(xs), newY := Round(ys)
        step := _Hypot(xs - oldX, ys - oldY)
        mean := Round(waitDiff * (step / maxStep) + minWait) / 7
        wait := _Muller((mean) / 2, (mean) / 2.718281)
        newArr.Push(wait)
    }
    return newArr
}

;---------------------- movement wrappers --------------------------------------:

_goStandard(x, y, speed) {
    MouseGetPos &xpos, &ypos
    distance := (Sqrt(_Hypot(x - xpos, y - ypos))) * speed
    dynamicSpeed := (1 / distance) * 60
    finalSpeed := Random(dynamicSpeed, dynamicSpeed + 0.8)
    stepArea := Max((finalSpeed / 2 + distance) / 10, 0.1)
    newArr := _WindMouse2(xpos, ypos, x, y, 10, 5, finalSpeed * 10, finalSpeed * 12, stepArea * 11, stepArea * 7)
    _SortArray(newArr, "D")
    c := newArr.Length
    g := c // 2
    loop g {
        newArr.RemoveAt(c)
        c--
    }
    newClone := newArr.Clone()
    _SortArray(newClone, "A")
    newArr.Push(newClone*)
    _WindMouse(xpos, ypos, x, y, 10, 5, finalSpeed * 10, finalSpeed * 12, stepArea * 11, stepArea * 7, newArr)
}

_goRelative(x, y, speed) {
    MouseGetPos &xpos, &ypos
    distance := (Sqrt(_Hypot(Abs(x), Abs(y)))) * speed
    dynamicSpeed := (1 / distance) * 60
    finalSpeed := Random(dynamicSpeed, dynamicSpeed + 0.8)
    stepArea := Max((finalSpeed / 2 + distance) / 10, 0.1)
    newArr := _WindMouse2(xpos, ypos, xpos + x, ypos + y, 10, 3, finalSpeed * 10, finalSpeed * 12, stepArea * 11,
        stepArea * 7)
    _SortArray(newArr, "D")
    c := newArr.Length
    g := c // 2
    loop g {
        newArr.RemoveAt(c)
        c--
    }
    newClone := newArr.Clone()
    _SortArray(newClone, "A")
    newArr.Push(newClone*)
    _WindMouse(xpos, ypos, xpos + x, ypos + y, 10, 3, finalSpeed * 10, finalSpeed * 12, stepArea * 11, stepArea * 7,
        newArr)
}
