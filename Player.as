/*
c 2023-08-23
m 2023-08-24
*/

void RenderPlayer() {
    UI::Begin("MusicControl", UI::WindowFlags::AlwaysAutoResize);
        if (UI::Button("get devices"))
            startnew(CoroutineFunc(GetDevicesCoro));

        if (UI::Button("get playback state"))
            startnew(CoroutineFunc(GetPlaybackStateCoro));

        if (UI::Button("get recent tracks"))
            startnew(CoroutineFunc(GetRecentTracksCoro));

        if (UI::Button("pause playback"))
            startnew(CoroutineFunc(PausePlaybackCoro));

        if (UI::Button("resume playback"))
            startnew(CoroutineFunc(ResumePlaybackCoro));

        if (UI::Button("skip next"))
            startnew(CoroutineFunc(SkipNextCoro));

        if (UI::Button("skip previous"))
            startnew(CoroutineFunc(SkipPreviousCoro));
    UI::End();
}