Font      currentFont = S_Font;
UI::Font@ font;
UI::Font@ fontDroidSans;
UI::Font@ fontDroidSansBold;
UI::Font@ fontDroidSansMono;

enum Font {
    DroidSans,
    DroidSansBold,
    DroidSansMono
}

void ChangeFont() {
    switch (S_Font) {
        case Font::DroidSans:     @font = fontDroidSans;     break;
        case Font::DroidSansBold: @font = fontDroidSansBold; break;
        case Font::DroidSansMono: @font = fontDroidSansMono; break;
    }

    currentFont = S_Font;
}

void LoadFonts() {
    @fontDroidSans     = UI::LoadFont("DroidSans.ttf");
    @fontDroidSansBold = UI::LoadFont("DroidSans-Bold.ttf");
    @fontDroidSansMono = UI::LoadFont("DroidSansMono.ttf");
}
