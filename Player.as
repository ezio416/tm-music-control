/*
c 2023-08-23
m 2023-08-23
*/

void RenderPlayer() {
    UI::Begin("MusicControl", UI::WindowFlags::AlwaysAutoResize);
        if (UI::Button("get devices"))
            startnew(CoroutineFunc(GetDevicesCoro));

        if (UI::Button("get playback state"))
            startnew(CoroutineFunc(GetPlaybackStateCoro));
    UI::End();
}