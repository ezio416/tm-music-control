/*
c 2023-08-23
m 2023-11-23
*/

void RenderPlayer() {
    if (!disclaimerAccepted)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl", S_Enabled, flags);
        vec2 pre = UI::GetCursorPos();
        uint maxWidth = 0;

        if (@tex !is null)
            UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));
        else
            UI::Dummy(vec2(S_AlbumArtWidth, S_AlbumArtWidth));

        UI::SameLine();
        UI::BeginGroup();
            UI::Text(state.song);
            maxWidth = GetMaxWidth(maxWidth);

            UI::Text(state.artists);
            maxWidth = GetMaxWidth(maxWidth);

            UI::Text(state.album);
            maxWidth = GetMaxWidth(maxWidth);

            UI::Text(state.albumRelease);
            maxWidth = GetMaxWidth(maxWidth);
        UI::EndGroup();

        if (UI::Button((state.shuffle ? "\\$0F0" : "") + Icons::Random))
            startnew(CoroutineFunc(ToggleShuffleCoro));
        HoverTooltip("shuffle: " + (state.shuffle ? "on" : "off"));

        UI::SameLine();
        if (UI::Button(Icons::StepBackward))
            startnew(CoroutineFunc(SkipPreviousCoro));

        UI::SameLine();
        if (state.playing) {
            if (UI::Button(Icons::Pause))
                startnew(CoroutineFunc(PauseCoro));
        } else
            if (UI::Button(Icons::Play))
                startnew(CoroutineFunc(PlayCoro));

        UI::SameLine();
        if (UI::Button(Icons::StepForward))
            startnew(CoroutineFunc(SkipNextCoro));

        UI::SameLine();
        string repeatIcon;
        switch (state.repeat) {
            case Repeat::context: repeatIcon = "\\$0F0" + Icons::Refresh; break;
            case Repeat::track:   repeatIcon = "\\$00F" + Icons::Refresh; break;
            default:              repeatIcon = Icons::Refresh;
        }
        if (UI::Button(repeatIcon))
            startnew(CoroutineFunc(CycleRepeatCoro));
        HoverTooltip("repeat: " + tostring(state.repeat));
        maxWidth = GetMaxWidth(maxWidth);

        UI::SetNextItemWidth((maxWidth - pre.x) / UI::GetScale());
        UI::SliderInt(
            "##songProgress",
            state.songProgressPercent,
            0,
            100,
            FormatSeconds(state.songProgress / 1000) + " / " + FormatSeconds(state.songDuration / 1000)
        );

        if (!Authorized())
            UI::Text("NOT AUTHORIZED - PLEASE FINISH SETUP");
    UI::End();
}

uint GetMaxWidth(uint input) {
    UI::SameLine();
    uint result = uint(Math::Max(input, UI::GetCursorPos().x));
    UI::NewLine();
    return result;
}