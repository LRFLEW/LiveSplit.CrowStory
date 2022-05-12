state("BlackthornprodJam-Win64-Shipping")
{
    bool cutscene : 0x3FFD8F0, 0x188, 0x38, 0x00, 0x30, 0x598;
    uint mapfname : 0x3FFD8F0, 0x18;
    float timer : 0x3FFD8F0, 0x188, 0x1A0;
}

startup
{
    settings.Add("do_start", true, "Automatically Start Timer");
    settings.Add("do_map", true, "Split on Map Load");
    settings.Add("do_end", true, "Split on Game End");
    settings.Add("do_rmenu", true, "Reset Timer on Main Menu");
    settings.Add("do_rstart", false, "Reset Timer on New Game");

    vars.maps = new Dictionary<string, int>() {
        { "MainMenu",    0 },
        { "Level_A1",    1 },
        { "Level_A2",    2 },
        { "Level_A3",    3 },
        { "Level_ATop",  4 },
        { "Level_B1",    5 },
        { "Level_B2",    6 },
        { "Level_B3",    7 },
        { "Level_BTop",  8 },
        { "Level_BBoss", 9 },
    //  { "None",       -1 },
    //  { "End",        -1 },
    };
}

init
{
    vars.running = false;
    current.map = 99;
}

update
{
    // Get Map
    if (current.mapfname != old.mapfname) {
        IntPtr mapentry = (IntPtr) (memory.ReadValue<ulong>(
            modules.First().BaseAddress + 0x3EA41D0 +
            8 * (int) (current.mapfname >> 16)
        ) + 2 * (current.mapfname & 0xFFFF));
        int maplen = memory.ReadValue<ushort>(mapentry) >> 6;
        string mapstr = memory.ReadString(mapentry + 2, maplen);
        if (vars.maps.ContainsKey(mapstr)) {
            current.map = vars.maps[mapstr];
            vars.running = true;
        } else {
            vars.running = false;
        }
    }

    return vars.running;
}

start
{
    return settings["do_start"] && old.map == 1 && current.map == 1 &&
                                   old.timer == 0 && current.timer > 0;
}

reset
{
    return (settings["do_rmenu"] && old.map != 0 && current.map == 0) ||
           (settings["do_rstart"] && old.map == 0 && current.map == 1 &&
                                     current.timer == 0);
}

split
{
    return (settings["do_map"] && old.map > 0 && current.map > old.map) ||
           (settings["do_end"] && current.map == 8 && current.cutscene);
}

isLoading
{
    // Do not interpolate game time
    return true;
}

gameTime
{
    return TimeSpan.FromSeconds(current.timer);
}
