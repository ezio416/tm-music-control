const string title   = "\\$2D6" + Icons::Music + "\\$G Music Control";
const string version = Meta::ExecutingPlugin().Version;

void Main() {
    if (!uriChanged && !IO::FileExists(authFile))
        uriChanged = true;  // user's first install >= v0.6.0, no need to do this setup

    Auth::Load();
    S_Setup = !Auth::Authorized();

    ChangeFont();

    while (true) {
        startnew(API::Loop);
        sleep(1000);
    }
}

void OnSettingsChanged() {
    if (currentFont != S_Font)
        ChangeFont();
}

void Render() {
    if (false
        || !S_Enabled
        || font is null
    ) {
        runLoop = false;
        return;
    } else
        runLoop = true;

    if ((S_HideWithGame && !UI::IsGameUIVisible()) || (S_HideWithOP && !UI::IsOverlayShown()))
        return;

    RenderPlayer();
    RenderDisclaimer();
    RenderSetup();
    RenderSetupPlaylists();
    RenderURISetup();
}

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}
