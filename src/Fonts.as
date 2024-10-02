// c 2023-08-04
// m 2024-10-01

Font      currentFont = S_Font;
UI::Font@ font;
uint      fontSize    = GetFontSize(currentFont);

enum Font {
    DroidSans_16,
    DroidSans_20,      // free
    DroidSans_26,      // free
    DroidSansBold_16,  // free
    DroidSansBold_20,
    DroidSansBold_26,
    DroidSansMono_16,  // free
    DroidSansMono_20,
    DroidSansMono_26
}

void ChangeFont() {
    switch (S_Font) {
        case Font::DroidSans_16:     @font = UI::LoadFont("DroidSans.ttf",      16.0f, -1, -1, true, true, true); break;
        case Font::DroidSans_20:     @font = UI::LoadFont("DroidSans.ttf",      20.0f, -1, -1, true, true, true); break;
        case Font::DroidSans_26:     @font = UI::LoadFont("DroidSans.ttf",      26.0f, -1, -1, true, true, true); break;
        case Font::DroidSansBold_16: @font = UI::LoadFont("DroidSans-Bold.ttf", 16.0f, -1, -1, true, true, true); break;
        case Font::DroidSansBold_20: @font = UI::LoadFont("DroidSans-Bold.ttf", 20.0f, -1, -1, true, true, true); break;
        case Font::DroidSansBold_26: @font = UI::LoadFont("DroidSans-Bold.ttf", 26.0f, -1, -1, true, true, true); break;
        case Font::DroidSansMono_16: @font = UI::LoadFont("DroidSansMono.ttf",  16.0f, -1, -1, true, true, true); break;
        case Font::DroidSansMono_20: @font = UI::LoadFont("DroidSansMono.ttf",  20.0f, -1, -1, true, true, true); break;
        case Font::DroidSansMono_26: @font = UI::LoadFont("DroidSansMono.ttf",  26.0f, -1, -1, true, true, true); break;
        default:;
    }

    currentFont = S_Font;
    fontSize = GetFontSize(currentFont);
}

uint GetFontSize(Font f) {
    switch (f) {
        case Font::DroidSans_16:
        case Font::DroidSansBold_16:
        case Font::DroidSansMono_16:
            return 16;
        case Font::DroidSans_20:
        case Font::DroidSansBold_20:
        case Font::DroidSansMono_20:
            return 20;
        default:
            return 26;
    }
}
