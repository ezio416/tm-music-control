bool changingVolume = false;
bool seeking        = false;

void RenderPlayer() {
    if (!S_Premium) {
        return;
    }

    if (true
        and S_HideInactive
        and Time::Stamp - lastActive > int(S_Inactivity)
    ) {
        return;
    }

    const float scale              = UI::GetScale();
    const float buttonWidthDefault = scale * 30.0f;
    const float sameLineWidth      = scale * 10.0f;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown()) {
        flags |= UI::WindowFlags::NoMove;
    }

    const vec4 styleButton     = UI::GetStyleColor(UI::Col::Button);
    const vec4 styleFrameBg    = UI::GetStyleColor(UI::Col::FrameBg);
    const vec4 stylePopupBg    = UI::GetStyleColor(UI::Col::PopupBg);
    const vec4 styleSliderGrab = UI::GetStyleColor(UI::Col::SliderGrab);
    const vec4 styleText       = UI::GetStyleColor(UI::Col::Text);
    const vec4 styleWindowBg   = UI::GetStyleColor(UI::Col::WindowBg);

    UI::PushStyleColor(UI::Col::Button,     vec4(styleButton.xyz,     Math::Min(S_Opacity, styleButton.w)));
    UI::PushStyleColor(UI::Col::FrameBg,    vec4(styleFrameBg.xyz,    Math::Min(S_Opacity, styleFrameBg.w)));
    UI::PushStyleColor(UI::Col::PopupBg,    vec4(stylePopupBg.xyz,    Math::Min(S_Opacity, stylePopupBg.w)));
    UI::PushStyleColor(UI::Col::SliderGrab, vec4(styleSliderGrab.xyz, Math::Min(S_Opacity, styleSliderGrab.w)));
    UI::PushStyleColor(UI::Col::Text,       vec4(styleText.xyz,       Math::Min(S_Opacity, styleText.w)));
    UI::PushStyleColor(UI::Col::WindowBg,   vec4(styleWindowBg.xyz,   Math::Min(S_Opacity, styleWindowBg.w)));

    if (UI::Begin("MusicControl", S_Enabled, flags)) {
        const vec2 pre = UI::GetCursorPos();

        if (S_AlbumArt) {
            if (@tex !is null) {
                UI::ImageWithBg(tex, vec2(S_AlbumArt_Cond.width), tint_col: vec4(vec3(1.0f), S_Opacity));
            } else {
                UI::Dummy(vec2(S_AlbumArt_Cond.width));
            }

            UI::SameLine();
        }

        float maxTextWidth = 0.0f;

        UI::PushFont(font, S_FontSize);

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
            string albumRelease = state.albumRelease.SubStr(0, (S_MaxTextLength > -1 ? S_MaxTextLength : state.albumRelease.Length));
            if (true
                and S_AlbumReleaseTruncate
                and albumRelease.EndsWith("-01-01")
            ) {
                albumRelease = albumRelease.SubStr(0, 4);  // only show year
            }
            maxTextWidth = GetMaxTextWidth(maxTextWidth, albumRelease);
            UI::Text(albumRelease);
        }

        if (true
            and S_AlbumArt
            and S_AlbumArt_Cond.heart
        ) {
            const string icon = state.songLiked ? Icons::Heart : Icons::HeartO;
            UI::SetCursorPos(pre + vec2(scale, scale * 1.5f));
            UI::Text("\\$000" + icon);
            UI::SetCursorPos(pre);
            UI::Text("\\$0F0" + icon);
            HoverTooltip((state.songLiked ? "" : "not ") + "in library");
        }
        UI::EndGroup();

        const float albumArtAndTextWidth = (S_AlbumArt ? S_AlbumArt_Cond.width + sameLineWidth : 0.0f) + maxTextWidth;
        const float buttonWidth = S_Buttons_Cond.stretch ? Math::Max((albumArtAndTextWidth - (sameLineWidth * 4.0f)) / 5.0f, buttonWidthDefault) : buttonWidthDefault;
        const vec2  buttonSize = vec2(buttonWidth, scale * font.FontSize * S_Buttons_Cond.height);

        if (S_Buttons) {
            UI::BeginDisabled(true
                and state.shuffle
                and state.smartShuffle
            );
            if (UI::Button((state.shuffle ? (state.smartShuffle ? "\\$F80" : "\\$0F0") : "") + Icons::Random, buttonSize)) {
                token.ToggleShuffle();
            }
            UI::EndDisabled();
            if (S_Buttons_Cond.tooltips) {
                HoverTooltip("shuffle: " + (state.shuffle ? (state.smartShuffle ? "smart" : "on"): "off"));
            }

            UI::SameLine();
            const bool skipPrevious = state.songProgress < 3000;
            if (UI::Button(skipPrevious ? Icons::FastBackward : Icons::StepBackward, buttonSize)) {
                if (skipPrevious) {
                    token.SkipPrevious();
                } else {
                    seekPosition = 0;
                    token.Seek();
                }
            }
            if (S_Buttons_Cond.tooltips) {
                HoverTooltip(skipPrevious ? "previous" : "restart");
            }

            UI::SameLine();
            if (state.playing) {
                if (UI::Button(Icons::Pause, buttonSize)) {
                    token.Pause();
                }
                if (S_Buttons_Cond.tooltips) {
                    HoverTooltip("pause");
                }
            } else {
                if (UI::Button(Icons::Play, buttonSize)) {
                    token.Play();
                }
                if (S_Buttons_Cond.tooltips) {
                    HoverTooltip("resume");
                }
            }

            UI::SameLine();
            if (UI::Button(Icons::StepForward, buttonSize)) {
                token.SkipNext();
            }
            if (S_Buttons_Cond.tooltips) {
                HoverTooltip("next");
            }

            UI::SameLine();
            string repeatIcon;
            switch (state.repeat) {
                case Repeat::context: repeatIcon = "\\$0F0" + Icons::Refresh; break;
                case Repeat::track:   repeatIcon = "\\$F80" + Icons::Refresh; break;
                default:              repeatIcon = Icons::Refresh;
            }
            if (UI::Button(repeatIcon, buttonSize)) {
                token.CycleRepeat();
            }
            if (S_Buttons_Cond.tooltips) {
                HoverTooltip("repeat: " + tostring(state.repeat));
            }
        }

        const float widthToSet = Math::Max(albumArtAndTextWidth, ((buttonWidth * 5.0f) + (sameLineWidth * 4.0f))) / scale;

        if (S_Progress) {
            UI::BeginDisabled(Time::Now - lastSeek < 2000);
            UI::SetNextItemWidth(widthToSet);
            int newSeekPosition = UI::SliderInt(
                "##songProgress",
                state.songProgressPredicted,
                0,
                state.songDuration,
                FormatSeconds((seeking ? seekPosition : state.songProgressPredicted) / 1000) + " / " + FormatSeconds(state.songDuration / 1000),
                UI::SliderFlags::NoInput
            );
            UI::EndDisabled();

            if (true
                and S_Progress_Cond.scroll
                and UI::IsItemHovered()
                and state.songDuration > 0
            ) {
                int newSeekPositionPercent = int(100.0f * newSeekPosition / state.songDuration);
                bool scroll = true;

                switch (int(UI::GetMouseWheelDelta())) {
                    case -1:  // down
                        newSeekPositionPercent -= Math::Min(newSeekPositionPercent, S_Progress_Cond.step);
                        break;

                    case 1:  // up
                        newSeekPositionPercent += Math::Min(100 - newSeekPositionPercent, S_Progress_Cond.step);
                        break;

                    default:
                        scroll = false;
                }

                if (scroll) {
                    newSeekPosition = int(0.01f * newSeekPositionPercent * state.songDuration);
                }
            }

            if (true
                and Time::Now - lastSeek > 2000
                and Math::Abs(newSeekPosition - state.songProgressPredicted) > 100
            ) {
                seeking = true;
                seekPosition = newSeekPosition;
            }

            if (true
                and seeking
                and !UI::IsMouseDown()
            ) {
                token.Seek();
                seeking = false;
            }
        }

        const bool supportsVolume = true
            and activeDevice !is null
            and activeDevice.supportsVolume
        ;

        if (true
            and S_Volume
            and (false
                or supportsVolume
                or (true
                    and !supportsVolume
                    and S_Volume_Cond.unsupported
                )
            )
        ) {  // TODO fix this mess
            const int currentVolume = activeDevice !is null ? activeDevice.volume : -1;
            const string volumeIcon = currentVolume < 34 ? Icons::VolumeOff : currentVolume < 67 ? Icons::VolumeDown : Icons::VolumeUp;
            const bool eggValue = (!changingVolume && currentVolume == 69) || (changingVolume && volumeDesired == 69);
            const string volumeText = (S_Volume_Cond.egg && eggValue) ? "\\$I\\$888 NICE\\$Z " : tostring(changingVolume ? volumeDesired : currentVolume);

            UI::BeginDisabled(false
                or !supportsVolume
                or Time::Now - lastVolume < 2000
            );
            UI::SetNextItemWidth(widthToSet);
            int volume = UI::SliderInt(
                "##volume",
                currentVolume,
                0,
                100,
                volumeIcon + " " + volumeText + " %%",
                UI::SliderFlags::NoInput
            );

            if (true
                and S_Volume_Cond.scroll
                and UI::IsItemHovered()
            ) {
                switch (int(UI::GetMouseWheelDelta())) {
                    case -1:
                        volume -= (volume < int(S_Volume_Cond.step) ? volume : S_Volume_Cond.step);
                        break;
                    case 1:
                        volume += (volume > 100 - int(S_Volume_Cond.step) ? 100 - volume : S_Volume_Cond.step);
                        break;
                }
            }
            UI::EndDisabled();

            if (true
                and activeDevice !is null
                and volume != activeDevice.volume
            ) {
                changingVolume = true;
                volumeDesired = volume;
            }

            if (true
                and changingVolume
                and !UI::IsMouseDown()
            ) {
                token.SetVolume();
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
                        name == current
                            ? UI::SelectableFlags::Disabled
                            : UI::SelectableFlags::None
                    )) {
                        selectedPlaylist = context;
                        token.Play();
                    }
                }

                UI::EndCombo();
            }
        }

        if (!token.authorized) {
            UI::Text("NOT AUTHORIZED - PLEASE FINISH SETUP");
        }

        UI::PopFont();
    }

    UI::End();

    UI::PopStyleColor(6);
}

float GetMaxTextWidth(const float input, const string&in text) {
    return Math::Max(input, UI::MeasureString(text, font).x);
}
