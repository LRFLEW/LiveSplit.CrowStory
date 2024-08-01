state("BlackthornprodJam-Win64-Shipping", "1.1.2")
{
    bool cutscene : 0x48F2120, 0x180, 0x200;
    uint mapfname : 0x48F2120, 0x18;
    float timer : 0x48F2120, 0x118, 0x2D4;
}

state("BlackthornprodJam-Win64-Shipping", "1.1.1")
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

    vars.strings_base = 0;
    vars.use_timer_sum = false;
    vars.timers = new float[9];
}

init
{
    vars.running = false;
    current.map = 99;

    if (modules.First().ModuleMemorySize == 0x4D53000) {
        version = "1.1.2";
        vars.strings_base = 0x476E450;
        vars.use_timer_sum = true;
    } else if (modules.First().ModuleMemorySize == 0x4403000) {
        version = "1.1.1";
        vars.strings_base = 0x3EA41D0;
        vars.use_timer_sum = false;
    }
}

update
{
    // Get Map
    if (current.mapfname != old.mapfname) {
        IntPtr mapentry = (IntPtr) (memory.ReadValue<ulong>(
            modules.First().BaseAddress + (int) vars.strings_base +
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
        if (vars.use_timer_sum && vars.running && current.map == 0) {
            // reset timers for error prevention
            for (int i=0; i < 9; ++i)
                vars.timers[i] = 0.0f;
        }
    }
    if (vars.use_timer_sum && vars.running && current.map > 0)
        vars.timers[current.map - 1] = current.timer;
    //print(String.Format("{0} {1} {2}", current.cutscene, current.mapfname, current.timer));

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
    if (vars.use_timer_sum) {
        float sum = 0.0f;
        for (int i=0; i < current.map; ++i)
            sum += vars.timers[i];
        return TimeSpan.FromSeconds(sum);
    } else {
        return TimeSpan.FromSeconds(current.timer);
    }
}
