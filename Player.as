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
    UI::End();
}