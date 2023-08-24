/*
c 2023-08-23
m 2023-08-24
*/

void RenderPlayer() {
    UI::Begin("MusicControl", UI::WindowFlags::AlwaysAutoResize);
        UI::BeginTabBar("tabs", UI::TabBarFlags::None);
            if (UI::BeginTabItem("buttons")) {
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

                UI::EndTabItem();
            }
            if (UI::BeginTabItem("devices")) {
                UI::BeginTabBar("all-devices");
                    if (UI::BeginTabItem("active")) {
                        if (activeDevice !is null) {
                            UI::Text(activeDevice.name);
                        }
                        UI::EndTabItem();
                    }
                    if (UI::BeginTabItem("selected")) {
                        if (selectedDevice !is null) {
                            UI::Text(selectedDevice.name);
                        }
                        UI::EndTabItem();
                    }
                    for (uint i = 0; i < devices.Length; i++) {
                        auto dev = @devices[i];
                        if (UI::BeginTabItem(i + " " + dev.name)) {
                            UI::BeginDisabled(selectedDeviceId == dev.id);
                            if (UI::Button("select")) {
                                selectedDeviceId = dev.id;
                                SetSelectedDevice();
                            }
                            UI::EndDisabled();

                            UI::Text("id: " + dev.id);
                            UI::Text("type: " + dev.type);
                            UI::Text("active: " + dev.active);
                            UI::Text("private: " + dev.privateSession);
                            UI::Text("restricted: " + dev.restricted);
                            UI::Text("supportsVolume: " + dev.supportsVolume);
                            UI::Text("volume: " + dev.volume);

                            UI::EndTabItem();
                        }
                    }
                UI::EndTabBar();
                UI::EndTabItem();
            }
        UI::EndTabBar();
    UI::End();
}