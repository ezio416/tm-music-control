Meta::Plugin@ PLUGIN       = Meta::ExecutingPlugin();
const string  PLUGIN_COLOR = "\\$2D6";
const string  PLUGIN_ICON  = Icons::Music;
const string  PLUGIN_TITLE = PLUGIN_COLOR + PLUGIN_ICON + "\\$G " + PLUGIN.Name;

bool       forceDevice      = false;
bool       forceDeviceTried = false;
uint64     lastSeek         = 0;
uint64     lastVolume       = 0;
bool       loopRunning      = false;
dictionary playlists;
bool       runLoop          = false;
int        seekPosition     = 0;
string     selectedPlaylist;
int        volumeDesired    = 0;

void Main() {
    @spotify = SpotifyToken();

    S_Setup = !token.authorized;

    if (S_Font > 7) {  // enum before 0.7 had more options so the setting gets messed up
        S_Font = Font::DroidSans;
    }
    ChangeFont();

    while (true) {
        startnew(LoopAsync);
        sleep(1000);
    }
}

void OnSettingsChanged() {
    if (currentFont != S_Font) {
        ChangeFont();
    }

    S_Opacity = Math::Clamp(S_Opacity, 0.05f, 1.0f);
}

void Render() {
    if (S_Setup) {
        RenderSetup();
    }

    if (false
        or !S_Enabled
        or font is null
    ) {
        runLoop = false;
        return;
    } else {
        runLoop = true;
    }

    if (false
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
    ) {
        return;
    }

    RenderPlayer();
}

void RenderMenu() {
    if (true
        and S_Premium
        and UI::MenuItem(PLUGIN_TITLE, "", S_Enabled)
    ) {
        S_Enabled = !S_Enabled;
    }
}

void LoopAsync() {
    if (loopRunning) {
        return;
    }

    loopRunning = true;

    int waitTime = S_UpdateFreq;

    uint checkLiked     = 0;
    uint checkPlaylists = 0;

    while (true) {
        if (!token.authorized) {
            break;
        }

        if (waitTime > S_UpdateFreq) {
            warn("Waiting " + waitTime + " ms to try contacting API again");
        }
        sleep(waitTime);

        if (waitTime > S_UpdateFreq * 4) {
            waitTime = S_UpdateFreq * 4;
        }

        if (!runLoop) {
            state.Clear();
            break;
        }

        if (!S_AlbumArt_Cond.heart) {
            checkLiked = 0;
        }

        if (!S_Playlists) {
            checkPlaylists = 0;
        }

        if (false
            or !token.GetDevicesAsync()
            or !token.GetPlaybackStateAsync()
        ) {
            waitTime *= 2;
            continue;
        } else {
            waitTime = S_UpdateFreq;
        }

        if (true
            and S_AlbumArt_Cond.heart
            and checkLiked++ % 5 == 0
        ) {
            if (!token.GetCurrentSongIsLikedAsync()) {
                waitTime *= 2;
            } else {
                waitTime = S_UpdateFreq;
            }

            checkLiked = 1;
        }

        if (true
            and S_Playlists
            and checkPlaylists++ % 20 == 0
        ) {
            if (!token.GetPlaylistsAsync()) {
                waitTime *= 2;
            } else {
                waitTime = S_UpdateFreq;
            }

            checkPlaylists = 1;
        }
    }

    loopRunning = false;
}
