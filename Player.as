/*
c 2023-08-23
m 2023-08-24
*/

void RenderPlayer() {
    if (!S_Player) return;

    UI::Begin("MusicControl", S_Player, UI::WindowFlags::AlwaysAutoResize);
        UI::BeginTabBar("tabs", UI::TabBarFlags::None);
            if (UI::BeginTabItem("buttons")) {
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

                UI::SliderInt(
                    FormatSeconds(state.songProgress / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
                    state.songProgressPercent,
                    0,
                    100,
                    "%d%%"
                );

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