Meta::Plugin@ PLUGIN         = Meta::ExecutingPlugin();
const string  PLUGIN_COLOR   = "\\$2D6";
const string  PLUGIN_ICON    = Icons::Music;
const string  PLUGIN_TITLE   = PLUGIN_COLOR + PLUGIN_ICON + "\\$G " + PLUGIN.Name;
const string  PLUGIN_VERSION = PLUGIN.Version;

void Main() {
    if (true
        and !uriChanged
        and !IO::FileExists(authFile)
    ) {
        uriChanged = true;  // user's first install >= v0.6.0, no need to do this setup
    }

    Auth::Load();
    S_Setup = !Auth::Authorized();

    if (S_Font > 7) {  // enum before 0.7 had more options so the setting gets messed up
        S_Font = Font::DroidSans;
    }
    ChangeFont();

    while (true) {
        startnew(API::Loop);
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

    if (S_Setup) {
        RenderSetup();
        // RenderPlayer();
    }
}

void RenderMenu() {
    if (true
        and S_Premium
        and UI::MenuItem(PLUGIN_TITLE, "", S_Enabled)
    ) {
        S_Enabled = !S_Enabled;
    }
}
