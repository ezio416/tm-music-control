/*
c 2023-08-21
m 2023-11-30
*/

string title = "\\$2D6" + Icons::Music + "\\$G Music Control";

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Main() {
    // OnSettingsChanged();

    Auth::Load();
    S_Setup = !Auth::Authorized();

    while (true) {
        if (S_Enabled) {
            if (Auth::Authorized() && disclaimerAccepted) {
                startnew(API::GetDevices);
                startnew(API::GetPlaybackState);
            }
        } else {
            state = State();
            @tex = null;
        }

        sleep(1000);
    }
}

void OnSettingsChanged() {
    if (_S_ScrollText != S_ScrollText) {
        maxWidth = 0;
        windowWidth = 0;
        _S_ScrollText = S_ScrollText;
    }

    if (S_ScrollSpeed < 1)
        S_ScrollSpeed = 1;
    else if (S_ScrollSpeed > 100)
        S_ScrollSpeed = 100;
}

void Render() {
    if (
        !S_Enabled ||
        (S_HideWithGame && !UI::IsGameUIVisible()) ||
        (S_HideWithOP && !UI::IsOverlayShown())
    )
        return;

    RenderDisclaimer();
    RenderSetup();
    RenderPlayer();
    RenderDebug();
}