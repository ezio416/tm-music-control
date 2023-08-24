/*
c 2023-08-24
m 2023-08-24
*/

void RenderDebug() {
    if (!S_Debug) return;

    int flags = UI::WindowFlags::AlwaysAutoResize;
    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl Debug", S_Debug, flags);
        UI::BeginTabBar("debug-tabs", UI::TabBarFlags::None);
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

            if (UI::BeginTabItem("state")) {
                UI::Text("device ID: " + state.deviceId);
                UI::Text("context: " + state.context);
                UI::Text("song: " + state.song);
                UI::Text("artists: " + state.artists);
                UI::Text("album: " + state.album);
                UI::Text("album release: " + state.albumRelease);
                UI::Text("album art URL: " + state.albumArtUrl64);
                UI::Text("playing: " + state.playing);
                UI::Text("progress: " + state.songProgress);
                UI::Text("duration: " + state.songDuration);
                UI::Text("progress%: " + state.songProgressPercent);
                UI::Text("repeat: " + tostring(state.repeat));
                UI::Text("shuffle: " + state.shuffle);
                UI::EndTabItem();
            }
        UI::EndTabBar();
    UI::End();
}