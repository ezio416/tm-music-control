/*
c 2023-08-22
m 2023-08-22
*/

void HoverTooltip(const string &in text) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
            UI::Text(text);
        UI::EndTooltip();
    }
}