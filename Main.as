/*
c 2023-08-21
m 2023-08-24
*/

string title = "\\$2D6" + Icons::Music + "\\$G MusicControl";

void Main() {
    LoadAuth();
    S_Setup = !Authorized();

    while (true) {
        if (Authorized()) {
            startnew(CoroutineFunc(GetDevicesCoro));
            startnew(CoroutineFunc(GetPlaybackStateCoro));
        }
        sleep(1000);
    }
}

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

void Render() {
    if (!S_Enabled) return;

    RenderPlayer();
    RenderSetup();
    RenderDebug();
}