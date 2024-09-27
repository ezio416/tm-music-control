// c 2023-08-23
// m 2024-09-27

bool        changingVolume     = false;
const float scale              = UI::GetScale();
const float buttonHeight       = scale * 24.0f;
const float buttonWidthDefault = scale * 30.0f;
const float sameLineWidth      = scale * 10.0f;
bool        seeking            = false;

void RenderPlayer() {
    if (!disclaimerAccepted)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    if (UI::Begin("MusicControl", S_Enabled, flags)) {
        const vec2 pre = UI::GetCursorPos();

        if (S_AlbumArt) {
            if (@tex !is null)
                UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));
            else
                UI::Dummy(vec2(S_AlbumArtWidth, S_AlbumArtWidth));

            UI::SameLine();

            if (S_AlbumArt && S_InLibrary) {
                const string icon = state.songInLibrary ? Icons::Heart : Icons::HeartO;
                UI::SetCursorPos(pre + vec2(scale, scale * 1.5f));
                UI::Text("\\$000" + icon);
                UI::SetCursorPos(pre);
                UI::Text("\\$0F0" + icon);
                HoverTooltip((state.songInLibrary ? "" : "not ") + "in library");
            }
        }

        float maxTextWidth = 0.0f;

        UI::BeginGroup();
            if (S_Song) {
                const string song = state.song.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.song.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, song);
                UI::Text(song);
            }

            if (S_Artists) {
                const string artists = state.artists.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.artists.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, artists);
                UI::Text(artists);
            }

            if (S_AlbumName) {
                const string album = state.album.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.album.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, album);
                UI::Text(album);
            }

            if (S_AlbumRelease) {
                const string albumRelease = state.albumRelease.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.albumRelease.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, albumRelease);
                UI::Text(albumRelease);
            }
        UI::EndGroup();

        const float albumArtAndTextWidth = (S_AlbumArt ? S_AlbumArtWidth + sameLineWidth : 0.0f) + maxTextWidth;
        const float buttonWidth = S_StretchButtons ? Math::Max((albumArtAndTextWidth - (sameLineWidth * 4.0f)) / 5.0f, buttonWidthDefault) : buttonWidthDefault;
        const vec2  buttonSize = vec2(buttonWidth, buttonHeight);

        UI::BeginDisabled(!S_Premium);
            if (S_ButtonControls) {
                if (UI::Button((state.shuffle ? "\\$0F0" : "") + Icons::Random, buttonSize))
                    startnew(API::ToggleShuffle);
                HoverTooltip("shuffle: " + (state.shuffle ? "on" : "off"));

                UI::SameLine();
                const bool skipPrevious = state.songProgress < 3000;
                if (UI::Button(skipPrevious ? Icons::FastBackward : Icons::StepBackward, buttonSize)) {
                    if (skipPrevious)
                        startnew(API::SkipPrevious);
                    else {
                        seekPosition = 0;
                        startnew(API::Seek);
                    }
                }

                UI::SameLine();
                if (state.playing) {
                    if (UI::Button(Icons::Pause, buttonSize))
                        startnew(API::Pause);
                } else
                    if (UI::Button(Icons::Play, buttonSize))
                        startnew(API::Play);

                UI::SameLine();
                if (UI::Button(Icons::StepForward, buttonSize))
                    startnew(API::SkipNext);

                UI::SameLine();
                string repeatIcon;
                switch (state.repeat) {
                    case Repeat::context: repeatIcon = "\\$0F0" + Icons::Refresh; break;
                    case Repeat::track:   repeatIcon = "\\$F0F" + Icons::Refresh; break;
                    default:              repeatIcon = Icons::Refresh;
                }
                if (UI::Button(repeatIcon, buttonSize))
                    startnew(API::CycleRepeat);
                HoverTooltip("repeat: " + tostring(state.repeat));
            }

            const float widthToSet = Math::Max(albumArtAndTextWidth, ((buttonWidth * 5.0f) + (sameLineWidth * 4.0f))) / scale;

            if (S_Scrubber) {
                UI::SetNextItemWidth(widthToSet);
                const int seekPositionPercent = UI::SliderInt(
                    "##songProgress",
                    state.songProgressPercent,
                    0,
                    100,
                    FormatSeconds((seeking ? seekPosition : state.songProgress) / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
                    UI::SliderFlags::NoInput
                );

                if (seekPositionPercent != state.songProgressPercent) {
                    seeking = true;
                    seekPosition = int(state.songDuration * (float(seekPositionPercent) / 100.0f));
                }

                if (seeking && !UI::IsMouseDown()) {
                    startnew(API::Seek);
                    seeking = false;
                }
            }

            if (S_Volume) {
                const int currentVolume = activeDevice !is null ? activeDevice.volume : -1;

                UI::BeginDisabled(activeDevice is null || !activeDevice.supportsVolume);
                    UI::SetNextItemWidth(widthToSet);
                    const int volume = UI::SliderInt(
                        "##volume",
                        currentVolume,
                        0,
                        100,
                        "Volume: " + (changingVolume ? volumeDesired : currentVolume) + "%%",
                        UI::SliderFlags::NoInput
                    );
                UI::EndDisabled();

                if (activeDevice !is null && volume != activeDevice.volume) {
                    changingVolume = true;
                    volumeDesired = volume;
                }

                if (changingVolume && !UI::IsMouseDown()) {
                    startnew(API::SetVolume);
                    changingVolume = false;
                }
            }

            if (S_Playlists) {
                const string current = playlists.Exists(state.context) ? string(playlists[state.context]) : "";
                const string[]@ keys = playlists.GetKeys();

                UI::SetNextItemWidth(widthToSet);
                if (UI::BeginCombo("##playlists", current)) {
                    for (uint i = 0; i < keys.Length; i++) {
                        const string context = keys[i];
                        const string name = string(playlists[context]);

                        if (UI::Selectable(
                            name + "##name",
                            name == current,
                            name == current || !S_Premium ? UI::SelectableFlags::Disabled : UI::SelectableFlags::None
                        )) {
                            selectedPlaylist = context;
                            startnew(API::Play);
                        }
                    }

                    UI::EndCombo();
                }
            }
        UI::EndDisabled();

        if (!Auth::Authorized())
            UI::Text("NOT AUTHORIZED - PLEASE FINISH SETUP");
    }
    UI::End();
}

float GetMaxTextWidth(float input, const string &in text) {
    return Math::Max(input, Draw::MeasureString(text).x);
}
