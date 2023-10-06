#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2
#SingleInstance Force
toggle := 0

humanClick()
{
    MouseClick "left", 0, 0, 1, 0, "D", "R"
    Sleep Random(100, 200) 
    MouseClick "left", 0, 0, 1, 0, "U", "R"
}
return

^PgDn::
{
    global toggle := !toggle
    Loop
    {
        if not toggle
            Break
        
        {
            humanClick()
            Sleep Random(100, 200)
            humanClick()

            ; N := Random(3000, 3500) ; high-alc
            N := Random(6, 52) * 1000 ; NMZ
            Sleep N
        }
    }
}
