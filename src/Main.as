// c 2023-08-21
// m 2024-09-25

const string title   = "\\$2D6" + Icons::Music + "\\$G Music Control";
const string version = Meta::ExecutingPlugin().Version;

void Main() {
    Auth::Load();
    S_Setup = !Auth::Authorized();

    while (true) {
        startnew(API::Loop);
        sleep(1000);
    }
}

void Render() {
    if (!S_Enabled) {
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
}

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}
