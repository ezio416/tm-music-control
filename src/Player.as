/*
c 2023-08-23
m 2023-12-02
*/

uint maxWidth = 0;
float scale = UI::GetScale();
bool seeking = false;
float windowWidth = 0.0f;

float sliderWidth = 0.0f;
float songNameWidth = 0.0f;

void RenderPlayer() {
    if (!disclaimerAccepted)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl", S_Enabled, flags);
        vec2 pre = UI::GetCursorPos();

        if (S_Album) {
            if (tex !is null)
                UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));
            else
                UI::Dummy(vec2(S_AlbumArtWidth, S_AlbumArtWidth));

            UI::SameLine();
        }

        UI::BeginGroup();
            DisplaySongName();
            DisplayArtists();
            DisplayAlbumName();
            DisplayReleaseDate();
        UI::EndGroup();

        if (UI::Button((state.shuffle ? "\\$0F0" : "") + Icons::Random))
            startnew(API::ToggleShuffle);
        HoverTooltip("shuffle: " + (state.shuffle ? "on" : "off"));

        UI::SameLine();
        if (UI::Button(Icons::StepBackward)) {
            if (state.songProgress > 3000) {
                seekPosition = 0;
                startnew(API::Seek);
            } else
                startnew(API::SkipPrevious);
        }

        UI::SameLine();
        if (state.playing) {
            if (UI::Button(Icons::Pause))
                startnew(API::Pause);
        } else
            if (UI::Button(Icons::Play))
                startnew(API::Play);

        UI::SameLine();
        if (UI::Button(Icons::StepForward))
            startnew(API::SkipNext);

        UI::SameLine();
        string repeatIcon;
        switch (state.repeat) {
            case Repeat::context: repeatIcon = "\\$0F0" + Icons::Refresh; break;
            case Repeat::track:   repeatIcon = "\\$00F" + Icons::Refresh; break;
            default:              repeatIcon = Icons::Refresh;
        }
        if (UI::Button(repeatIcon))
            startnew(API::CycleRepeat);
        HoverTooltip("repeat: " + tostring(state.repeat));

        if (S_ScrollText) {
            windowWidth = UI::GetWindowSize().x;
        } else
            SetMaxWidth();

        // sliderWidth = (S_ScrollText ? 286 : maxWidth - pre.x) / scale;
        sliderWidth = S_ScrollText ? 191 : maxWidth - pre.x;
        UI::SetNextItemWidth(sliderWidth);
        // UI::SetNextItemWidth((S_ScrollText ? 191 : maxWidth - pre.x));
        int seekPositionPercent = UI::SliderInt(
            "##songProgress",
            state.songProgressPercent,
            0,
            100,
            FormatSeconds((seeking ? seekPosition : state.songProgress) / 1000) + " / " + FormatSeconds(state.songDuration / 1000)
        );

        if (seekPositionPercent != state.songProgressPercent) {
            seeking = true;
            seekPosition = int(state.songDuration * (float(seekPositionPercent) / 100));
        }

        if (seeking && !UI::IsMouseDown()) {
            startnew(API::Seek);
            seeking = false;
        }

        if (!Auth::Authorized())
            UI::Text("NOT AUTHORIZED - PLEASE FINISH SETUP");
    UI::End();
}

// scrolling text from Ultimate Medals plugin - https://github.com/Phlarx/tm-ultimate-medals
uint64 songWidthTime = 0;
uint64 songWidthTimeEnd = 0;
void DisplaySongName() {
    if (!S_Song)
        return;

    if (S_ScrollText) {
        if (windowWidth == 0)
            return;

        vec2 size = Draw::MeasureString(state.song);
        songNameWidth = windowWidth - (S_Album ? S_AlbumArtWidth : 0) - ((S_Album ? 60 : 45) / scale);
        // float songNameWidth = windowWidth - (S_Album ? S_AlbumArtWidth : 0) - (S_Album ? 30 : 20);

        if (size.x > songNameWidth) {
            vec2 cursorPos = UI::GetWindowPos() + UI::GetCursorPos();
            UI::DrawList@ dl = UI::GetWindowDrawList();
            uint64 now = Time::Now;

            UI::Dummy(vec2(songNameWidth, size.y));

            if (UI::IsItemHovered()) {
                songWidthTime = now;
                songWidthTimeEnd = 0;
            }

            vec2 textPos = vec2(0, 0);
            uint64 timeOffset = now - songWidthTime;

            if (timeOffset > 1000)
                textPos.x = -((timeOffset - 1000) / (101 - S_ScrollSpeed));

            if (textPos.x < songNameWidth - size.x) {
                textPos.x = songNameWidth - size.x;

                if (songWidthTimeEnd == 0)
                    songWidthTimeEnd = now;
            }

            if (songWidthTimeEnd > 0 && now - songWidthTimeEnd > 2000) {
                songWidthTime = now;
                songWidthTimeEnd = 0;
            }

            dl.PushClipRect(vec4(cursorPos.x, cursorPos.y, songNameWidth, size.y), true);
            dl.AddText(cursorPos + textPos, vec4(1, 1, 1, 1), state.song);
            dl.PopClipRect();
        } else {
            UI::Text(state.song);
        }
    } else {
        UI::Text(state.song);
        SetMaxWidth();
    }
}

// scrolling text from Ultimate Medals plugin - https://github.com/Phlarx/tm-ultimate-medals
uint64 artistsWidthTime = 0;
uint64 artistsWidthTimeEnd = 0;
void DisplayArtists() {
    if (!S_Artists)
        return;

    if (S_ScrollText) {
        if (windowWidth == 0)
            return;

        vec2 size = Draw::MeasureString(state.artists);
        float artistsWidth = windowWidth - (S_Album ? S_AlbumArtWidth : 0) - ((S_Album ? 60 : 45) / scale);

        if (size.x > artistsWidth) {
            vec2 cursorPos = UI::GetWindowPos() + UI::GetCursorPos();
            UI::DrawList@ dl = UI::GetWindowDrawList();
            uint64 now = Time::Now;

            UI::Dummy(vec2(artistsWidth, size.y));

            if (UI::IsItemHovered()) {
                artistsWidthTime = now;
                artistsWidthTimeEnd = 0;
            }

            vec2 textPos = vec2(0, 0);
            uint64 timeOffset = now - artistsWidthTime;

            if (timeOffset > 1000)
                textPos.x = -((timeOffset - 1000) / (101 - S_ScrollSpeed));

            if (textPos.x < artistsWidth - size.x) {
                textPos.x = artistsWidth - size.x;

                if (artistsWidthTimeEnd == 0)
                    artistsWidthTimeEnd = now;
            }

            if (artistsWidthTimeEnd > 0 && now - artistsWidthTimeEnd > 2000) {
                artistsWidthTime = now;
                artistsWidthTimeEnd = 0;
            }

            dl.PushClipRect(vec4(cursorPos.x, cursorPos.y, artistsWidth, size.y), true);
            dl.AddText(cursorPos + textPos, vec4(1, 1, 1, 1), state.artists);
            dl.PopClipRect();
        } else {
            UI::Text(state.artists);
        }
    } else {
        UI::Text(state.artists);
        SetMaxWidth();
    }
}

// scrolling text from Ultimate Medals plugin - https://github.com/Phlarx/tm-ultimate-medals
uint64 albumWidthTime = 0;
uint64 albumWidthTimeEnd = 0;
void DisplayAlbumName() {
    if (!S_AlbumName)
        return;

    if (S_ScrollText) {
        if (windowWidth == 0)
            return;

        vec2 size = Draw::MeasureString(state.album);
        float albumWidth = windowWidth - (S_Album ? S_AlbumArtWidth : 0) - ((S_Album ? 60 : 45) / scale);

        if (size.x > albumWidth) {
            vec2 cursorPos = UI::GetWindowPos() + UI::GetCursorPos();
            UI::DrawList@ dl = UI::GetWindowDrawList();
            uint64 now = Time::Now;

            UI::Dummy(vec2(albumWidth, size.y));

            if (UI::IsItemHovered()) {
                albumWidthTime = now;
                albumWidthTimeEnd = 0;
            }

            vec2 textPos = vec2(0, 0);
            uint64 timeOffset = now - albumWidthTime;

            if (timeOffset > 1000)
                textPos.x = -((timeOffset - 1000) / (101 - S_ScrollSpeed));

            if (textPos.x < albumWidth - size.x) {
                textPos.x = albumWidth - size.x;

                if (albumWidthTimeEnd == 0)
                    albumWidthTimeEnd = now;
            }

            if (albumWidthTimeEnd > 0 && now - albumWidthTimeEnd > 2000) {
                albumWidthTime = now;
                albumWidthTimeEnd = 0;
            }

            dl.PushClipRect(vec4(cursorPos.x, cursorPos.y, albumWidth, size.y), true);
            dl.AddText(cursorPos + textPos, vec4(1, 1, 1, 1), state.album);
            dl.PopClipRect();
        } else {
            UI::Text(state.album);
        }
    } else {
        UI::Text(state.album);
        SetMaxWidth();
    }
}

void DisplayReleaseDate() {
    if (!S_AlbumRelease)
        return;

    UI::Text(state.albumRelease);
    SetMaxWidth();
}

void SetMaxWidth() {
    UI::SameLine();
    maxWidth = uint(Math::Max(maxWidth, UI::GetCursorPos().x));
    UI::NewLine();
}