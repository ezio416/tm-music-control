// c 2023-08-23
// m 2024-10-01

bool        changingVolume     = false;
const float scale              = UI::GetScale();
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
                UI::Image(tex, vec2(S_AlbumArt_.width));
            else
                UI::Dummy(vec2(S_AlbumArt_.width));

            UI::SameLine();
        }

        float maxTextWidth = 0.0f;

        UI::PushFont(font);

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

            if (S_AlbumArt && S_AlbumArt_.heart) {
                const string icon = state.songLiked ? Icons::Heart : Icons::HeartO;
                UI::SetCursorPos(pre + vec2(scale, scale * 1.5f));
                UI::Text("\\$000" + icon);
                UI::SetCursorPos(pre);
                UI::Text("\\$0F0" + icon);
                HoverTooltip((state.songLiked ? "" : "not ") + "in library");
            }
        UI::EndGroup();

        const float albumArtAndTextWidth = (S_AlbumArt ? S_AlbumArt_.width + sameLineWidth : 0.0f) + maxTextWidth;
        const float buttonWidth = S_Buttons_.stretch ? Math::Max((albumArtAndTextWidth - (sameLineWidth * 4.0f)) / 5.0f, buttonWidthDefault) : buttonWidthDefault;
        const vec2  buttonSize = vec2(buttonWidth, scale * font.FontSize * 1.4f);

        UI::BeginDisabled(!S_Premium);
            if (S_Buttons) {
                UI::BeginDisabled(state.shuffle && state.smartShuffle);
                if (UI::Button((state.shuffle ? (state.smartShuffle ? "\\$F80" : "\\$0F0") : "") + Icons::Random, buttonSize))
                    startnew(API::ToggleShuffle);
                UI::EndDisabled();
                if (S_Buttons_.tooltips)
                    HoverTooltip("shuffle: " + (state.shuffle ? (state.smartShuffle ? "smart" : "on"): "off"));

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
                if (S_Buttons_.tooltips)
                    HoverTooltip(skipPrevious ? "previous" : "restart");

                UI::SameLine();
                if (state.playing) {
                    if (UI::Button(Icons::Pause, buttonSize))
                        startnew(API::Pause);
                    if (S_Buttons_.tooltips)
                        HoverTooltip("pause");
                } else {
                    if (UI::Button(Icons::Play, buttonSize))
                        startnew(API::Play);
                    if (S_Buttons_.tooltips)
                        HoverTooltip("resume");
                }

                UI::SameLine();
                if (UI::Button(Icons::StepForward, buttonSize))
                    startnew(API::SkipNext);
                if (S_Buttons_.tooltips)
                    HoverTooltip("next");

                UI::SameLine();
                string repeatIcon;
                switch (state.repeat) {
                    case Repeat::context: repeatIcon = "\\$0F0" + Icons::Refresh; break;
                    case Repeat::track:   repeatIcon = "\\$F80" + Icons::Refresh; break;
                    default:              repeatIcon = Icons::Refresh;
                }
                if (UI::Button(repeatIcon, buttonSize))
                    startnew(API::CycleRepeat);
                if (S_Buttons_.tooltips)
                    HoverTooltip("repeat: " + tostring(state.repeat));
            }

            const float widthToSet = Math::Max(albumArtAndTextWidth, ((buttonWidth * 5.0f) + (sameLineWidth * 4.0f))) / scale;

            if (S_Progress) {
                UI::BeginDisabled(Time::Now - lastSeek < 2000);
                    UI::SetNextItemWidth(widthToSet);
                    int seekPositionPercent = UI::SliderInt(
                        "##songProgress",
                        state.songProgressPercent,
                        0,
                        100,
                        FormatSeconds((seeking ? seekPosition : state.songProgress) / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
                        UI::SliderFlags::NoInput
                    );
                UI::EndDisabled();

                if (S_Progress_.scroll && UI::IsItemHovered()) {
                    switch (int(UI::GetMouseWheelDelta())) {
                        case -1:
                            seekPositionPercent -= (seekPositionPercent < int(S_Progress_.step) ? seekPositionPercent : S_Progress_.step);
                            break;
                        case 1:
                            seekPositionPercent += (seekPositionPercent > 100 - int(S_Progress_.step) ? 100 - seekPositionPercent : S_Progress_.step);
                            break;
                        default:;
                    }
                }

                if (seekPositionPercent != state.songProgressPercent) {
                    seeking = true;
                    seekPosition = int(state.songDuration * (float(seekPositionPercent) / 100.0f));
                }

                if (seeking && !UI::IsMouseDown()) {
                    startnew(API::Seek);
                    seeking = false;
                }
            }

            const bool supportsVolume = activeDevice !is null && activeDevice.supportsVolume;
            if (S_Volume && (supportsVolume || (!supportsVolume && S_Volume_.unsupported))) {
                const int currentVolume = activeDevice !is null ? activeDevice.volume : -1;
                const string volumeIcon = currentVolume < 34 ? Icons::VolumeOff : currentVolume < 67 ? Icons::VolumeDown : Icons::VolumeUp;
                const bool eggValue = (!changingVolume && currentVolume == 69) || (changingVolume && volumeDesired == 69);
                const string volumeText = (S_Volume_.egg && eggValue) ? "\\$I\\$888 NICE\\$Z " : tostring(changingVolume ? volumeDesired : currentVolume);

                UI::BeginDisabled(!supportsVolume || Time::Now - lastVolume < 2000);
                    UI::SetNextItemWidth(widthToSet);
                    int volume = UI::SliderInt(
                        "##volume",
                        currentVolume,
                        0,
                        100,
                        volumeIcon + " " + volumeText + " %%",
                        UI::SliderFlags::NoInput
                    );

                    if (S_Volume_.scroll && UI::IsItemHovered()) {
                        switch (int(UI::GetMouseWheelDelta())) {
                            case -1:
                                volume -= (volume < int(S_Volume_.step) ? volume : S_Volume_.step);
                                break;
                            case 1:
                                volume += (volume > 100 - int(S_Volume_.step) ? 100 - volume : S_Volume_.step);
                                break;
                            default:;
                        }
                    }
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

        UI::PopFont();
    }
    UI::End();
}

float GetMaxTextWidth(float input, const string &in text) {
    return Math::Max(input, Draw::MeasureString(text, font).x);
}
