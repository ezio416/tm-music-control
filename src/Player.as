/*
c 2023-08-23
m 2023-12-30
*/

bool seeking = false;

void RenderPlayer() {
    if (!disclaimerAccepted)
        return;

    int flags = UI::WindowFlags::AlwaysAutoResize |
                UI::WindowFlags::NoTitleBar;

    if (!UI::IsOverlayShown())
        flags |= UI::WindowFlags::NoMove;

    UI::Begin("MusicControl", S_Enabled, flags);
        vec2 pre = UI::GetCursorPos();
        uint maxWidth = 0;

        if (S_AlbumArt) {
            if (@tex !is null)
                UI::Image(tex, vec2(S_AlbumArtWidth, S_AlbumArtWidth));
            else
                UI::Dummy(vec2(S_AlbumArtWidth, S_AlbumArtWidth));

            UI::SameLine();
        }

        UI::BeginGroup();
            if (S_Song) {
                UI::Text(state.song);
                maxWidth = GetMaxWidth(maxWidth);
            }

            if (S_Artists) {
                UI::Text(state.artists);
                maxWidth = GetMaxWidth(maxWidth);
            }

            if (S_AlbumName) {
                UI::Text(state.album);
                maxWidth = GetMaxWidth(maxWidth);
            }

            if (S_AlbumRelease) {
                UI::Text(state.albumRelease);
                maxWidth = GetMaxWidth(maxWidth);
            }
        UI::EndGroup();

        UI::BeginDisabled(!S_Premium);

        if (UI::Button((state.shuffle ? "\\$0F0" : "") + Icons::Random))
            startnew(API::ToggleShuffle);
        HoverTooltip("shuffle: " + (state.shuffle ? "on" : "off"));

        UI::SameLine();
        bool skipPrevious = state.songProgress < 3000;
        if (UI::Button(skipPrevious ? Icons::FastBackward : Icons::StepBackward)) {
            if (skipPrevious)
                startnew(API::SkipPrevious);
            else {
                seekPosition = 0;
                startnew(API::Seek);
            }
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
        maxWidth = GetMaxWidth(maxWidth);

        UI::EndDisabled();

        UI::BeginDisabled(UI::IsKeyPressed(UI::Key::Tab));

        UI::SetNextItemWidth((maxWidth - pre.x) / UI::GetScale());
        int seekPositionPercent = UI::SliderInt(
            "##songProgress",
            state.songProgressPercent,
            0,
            100,
            FormatSeconds((seeking ? seekPosition : state.songProgress) / 1000) + " / " + FormatSeconds(state.songDuration / 1000)
        );

        UI::EndDisabled();

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

uint GetMaxWidth(uint input) {
    UI::SameLine();
    uint result = uint(Math::Max(input, UI::GetCursorPos().x));
    UI::NewLine();
    return result;
}