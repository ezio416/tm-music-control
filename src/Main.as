// c 2023-08-21
// m 2024-01-19

const string title   = "\\$2D6" + Icons::Music + "\\$G Music Control";
const string version = Meta::ExecutingPlugin().Version;

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Main() {
    Auth::Load();
    S_Setup = !Auth::Authorized();

    while (true) {
        startnew(API::Loop);
        sleep(1000);
    }
}

void OnSettingsChanged() {
    if (S_WaitTime < 500)
        S_WaitTime = 500;
}

void Render() {
    if (
        !S_Enabled ||
        (S_HideWithGame && !UI::IsGameUIVisible()) ||
        (S_HideWithOP && !UI::IsOverlayShown())
    ) {
        runLoop = false;
        return;
    } else
        runLoop = true;

    RenderPlayer();
    RenderDisclaimer();
    RenderSetup();
    RenderSetupPlaylists();
    RenderDebug();
}