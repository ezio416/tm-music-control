// c 2023-08-24
// m 2024-01-19

void RenderDebug() {
    if (!S_Debug)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize;
    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin(title + " Debug", S_Debug, flags);
        UI::BeginTabBar("debug-tabs", UI::TabBarFlags::None);
            if (UI::BeginTabItem("devices")) {
                UI::BeginTabBar("all-devices");
                    if (UI::BeginTabItem("active")) {
                        if (activeDevice !is null)
                            UI::Text(activeDevice.name);
                        UI::EndTabItem();
                    }

                    if (UI::BeginTabItem("last")) {
                        if (lastDevice !is null)
                            UI::Text(lastDevice.name);
                        UI::EndTabItem();
                    }

                    for (uint i = 0; i < devices.Length; i++) {
                        Device@ dev = @devices[i];
                        if (UI::BeginTabItem(i + " " + dev.name + "###" + dev.name)) {
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
                UI::Text("click any row to copy value to clipboard");
                UI::Separator();

                if (UI::Selectable("device ID: " + state.deviceId, false))
                    IO::SetClipboard(state.deviceId);
                if (UI::Selectable("context: " + state.context, false))
                    IO::SetClipboard(state.context);
                if (UI::Selectable("song: " + state.song, false))
                    IO::SetClipboard(state.song);
                if (UI::Selectable("artists: " + state.artists, false))
                    IO::SetClipboard(state.artists);
                if (UI::Selectable("album: " + state.album, false))
                    IO::SetClipboard(state.album);
                if (UI::Selectable("album release: " + state.albumRelease, false))
                    IO::SetClipboard(state.albumRelease);
                if (UI::Selectable("album art URL: " + state.albumArtUrl64, false))
                    IO::SetClipboard(state.albumArtUrl64);
                if (UI::Selectable("playing: " + state.playing, false))
                    IO::SetClipboard(tostring(state.playing));
                if (UI::Selectable("progress: " + state.songProgress, false))
                    IO::SetClipboard(tostring(state.songProgress));
                if (UI::Selectable("duration: " + state.songDuration, false))
                    IO::SetClipboard(tostring(state.songDuration));
                if (UI::Selectable("progress%: " + state.songProgressPercent, false))
                    IO::SetClipboard(tostring(state.songProgressPercent));
                if (UI::Selectable("repeat: " + tostring(state.repeat), false))
                    IO::SetClipboard(tostring(state.repeat));
                if (UI::Selectable("shuffle: " + state.shuffle, false))
                    IO::SetClipboard(tostring(state.shuffle));
                UI::EndTabItem();
            }
        UI::EndTabBar();
    UI::End();
}