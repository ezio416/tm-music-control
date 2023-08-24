/*
c 2023-08-23
m 2023-08-24
*/

void RenderPlayer() {
    if (!S_Player) return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;
    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl", S_Player, flags);
        // if (selectedDevice !is null) {
        //     UI::Text(selectedDevice.name);
        // } else {
        //     UI::Text("no device selected");
        // }

        UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));

        UI::SameLine();
        UI::BeginGroup();
            UI::Text(state.song);
            UI::Text(state.artists);
            UI::Text(state.album);
            UI::Text(state.albumRelease);
        UI::EndGroup();

        if (UI::Button((state.shuffle? "\\$0F0" : "") + Icons::Random))
            startnew(CoroutineFunc(ToggleShuffleCoro));

        UI::SameLine();
        if (UI::Button(Icons::StepBackward))
            startnew(CoroutineFunc(SkipPreviousCoro));

        UI::SameLine();
        if (state.playing) {
            if (UI::Button(Icons::Pause))
                startnew(CoroutineFunc(PauseCoro));
        } else {
            if (UI::Button(Icons::Play))
                startnew(CoroutineFunc(PlayCoro));
        }

        UI::SameLine();
        if (UI::Button(Icons::StepForward))
            startnew(CoroutineFunc(SkipNextCoro));

        UI::SameLine();
        string repeatIcon;
        switch (state.repeat) {
            case Repeat::context: repeatIcon = Icons::Refresh; break;
            case Repeat::track:   repeatIcon = Icons::Repeat;  break;
            default:              repeatIcon = Icons::ArrowRight;
        }
        if (UI::Button(repeatIcon))
            startnew(CoroutineFunc(CycleRepeatCoro));
        HoverTooltip("repeat: " + tostring(state.repeat));

        UI::SliderInt(
            FormatSeconds(state.songProgress / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
            state.songProgressPercent,
            0,
            100,
            "%d%%"
        );
    UI::End();
}