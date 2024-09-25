// c 2023-08-23
// m 2024-01-20

float scale              = UI::GetScale();
float buttonHeight       = 24.0f * scale;
float buttonWidthDefault = 30.0f * scale;
float sameLineWidth      = 10.0f * scale;
bool  seeking            = false;

void RenderPlayer() {
    if (!disclaimerAccepted)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl", S_Enabled, flags);
        float maxTextWidth = 0.0f;

        if (S_AlbumArt) {
            if (@tex !is null)
                UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));
            else
                UI::Dummy(vec2(S_AlbumArtWidth, S_AlbumArtWidth));

            UI::SameLine();
        }

        UI::BeginGroup();
            if (S_Song) {
                string song = state.song.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.song.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, song);
                UI::Text(song);
            }

            if (S_Artists) {
                string artists = state.artists.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.artists.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, artists);
                UI::Text(artists);
            }

            if (S_AlbumName) {
                string album = state.album.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.album.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, album);
                UI::Text(album);
            }

            if (S_AlbumRelease) {
                string albumRelease = state.albumRelease.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.albumRelease.Length));
                maxTextWidth = GetMaxTextWidth(maxTextWidth, albumRelease);
                UI::Text(albumRelease);
            }
        UI::EndGroup();

        float albumArtAndTextWidth = (S_AlbumArt ? S_AlbumArtWidth + sameLineWidth : 0) + maxTextWidth;
        float buttonWidth = S_StretchButtons ? Math::Max((albumArtAndTextWidth - (4 * sameLineWidth)) / 5, buttonWidthDefault) : buttonWidthDefault;
        vec2 buttonSize = vec2(buttonWidth, buttonHeight);

        if (S_ButtonControls) {
            UI::BeginDisabled(!S_Premium);

            if (UI::Button((state.shuffle ? "\\$0F0" : "") + Icons::Random, buttonSize))
                startnew(API::ToggleShuffle);
            HoverTooltip("shuffle: " + (state.shuffle ? "on" : "off"));

            UI::SameLine();
            bool skipPrevious = state.songProgress < 3000;
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
                case Repeat::track:   repeatIcon = "\\$00F" + Icons::Refresh; break;
                default:              repeatIcon = Icons::Refresh;
            }
            if (UI::Button(repeatIcon, buttonSize))
                startnew(API::CycleRepeat);
            HoverTooltip("repeat: " + tostring(state.repeat));

            UI::EndDisabled();
        }

        float widthToSet = Math::Max(albumArtAndTextWidth, ((5 * buttonWidth) + (4 * sameLineWidth))) / scale;

        if (S_Scrubber) {
            UI::SetNextItemWidth(widthToSet);
            int seekPositionPercent = UI::SliderInt(
                "##songProgress",
                state.songProgressPercent,
                0,
                100,
                FormatSeconds((seeking ? seekPosition : state.songProgress) / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
                UI::SliderFlags::NoInput
            );

            if (seekPositionPercent != state.songProgressPercent) {
                seeking = true;
                seekPosition = int(state.songDuration * (float(seekPositionPercent) / 100));
            }

            if (seeking && !UI::IsMouseDown()) {
                startnew(API::Seek);
                seeking = false;
            }
        }

        if (S_Playlists) {
            string current = playlists.Exists(state.context) ? string(playlists[state.context]) : "";
            string[]@ keys = playlists.GetKeys();

            UI::SetNextItemWidth(widthToSet);
            if (UI::BeginCombo("##playlists", current)) {
                for (uint i = 0; i < keys.Length; i++) {
                    string context = keys[i];
                    string name = string(playlists[context]);

                    if (UI::Selectable(name + "##name", name == current, (name == current || !S_Premium ? UI::SelectableFlags::Disabled : UI::SelectableFlags::None))) {
                        selectedPlaylist = context;
                        startnew(API::Play);
                    }
                }

                UI::EndCombo();
            }
        }

        if (!Auth::Authorized())
            UI::Text("NOT AUTHORIZED - PLEASE FINISH SETUP");
    UI::End();
}

float GetMaxTextWidth(float input, const string &in text) {
    return Math::Max(input, Draw::MeasureString(text).x);
}
