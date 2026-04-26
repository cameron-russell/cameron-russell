#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2
#SingleInstance Force
toggle := 0

humanClick() {
    MouseClick "left", 0, 0, 1, 0, "D", "R"
    Sleep Random(100, 200)
    MouseClick "left", 0, 0, 1, 0, "U", "R"
}
return

^PgDn::
{
    global toggle := !toggle
    loop {
        if not toggle
            break

        {
            humanClick()
            N := Random(420, 430) * 1000
            Sleep N
        }
    }
}
