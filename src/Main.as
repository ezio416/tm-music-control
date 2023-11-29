/*
c 2023-08-21
m 2023-11-28
*/

string title = "\\$2D6" + Icons::Music + "\\$G Music Control";

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Main() {
    Auth::Load();
    S_Setup = !Auth::Authorized();

    while (true) {
        if (Auth::Authorized() && disclaimerAccepted) {
            startnew(API::GetDevices);
            startnew(API::GetPlaybackState);
        }
        sleep(1000);
    }
}

void Render() {
    if (
        !S_Enabled ||
        (S_HideWithGame && !UI::IsGameUIVisible()) ||
        (S_HideWithOP && !UI::IsOverlayShown())
    )
        return;

    RenderPlayer();
    RenderDisclaimer();
    RenderSetup();
    RenderDebug();
}