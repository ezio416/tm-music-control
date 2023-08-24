/*
c 2023-08-22
m 2023-08-23
*/

void HoverTooltip(const string &in text) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
            UI::Text(text);
        UI::EndTooltip();
    }
}

void NotifyWarn(const string &in text) {
    UI::ShowNotification("MusicControl", text, UI::HSV(0.02, 0.8, 0.9));
}