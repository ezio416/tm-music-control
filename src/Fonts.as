Font      currentFont = S_Font;
UI::Font@ font;
UI::Font@ fontDroidSans;
UI::Font@ fontDroidSansBold;
UI::Font@ fontDroidSansMono;
string[]  fontErrors;

enum Font {
    DroidSans,
    DroidSansBold,
    DroidSansMono,
    Montserrat,
    MontserratBold,
    Oswald,
    OswaldBold,
    System
}

void ChangeFont() {
    switch (S_Font) {
        case Font::DroidSans:      @font = UI::LoadFont("DroidSans.ttf");       break;
        case Font::DroidSansBold:  @font = UI::LoadFont("DroidSans-Bold.ttf");  break;
        case Font::DroidSansMono:  @font = UI::LoadFont("DroidSansMono.ttf");   break;
        case Font::Montserrat:     @font = UI::LoadFont("Montserrat.ttf");      break;
        case Font::MontserratBold: @font = UI::LoadFont("Montserrat-Bold.ttf"); break;
        case Font::Oswald:         @font = UI::LoadFont("Oswald.ttf");          break;
        case Font::OswaldBold:     @font = UI::LoadFont("Oswald-Bold.ttf");     break;

        case Font::System:
            try {
                @font = UI::LoadSystemFont(S_SystemFont);
            } catch {
                @font = null;
            }
            if (font is null) {
                const string msg = "error loading system font '" + S_SystemFont + "', reverting to DroidSans";
                error(msg + ", error: " + getExceptionInfo());
                UI::ShowNotification(
                    title,
                    msg,
                    vec4(1.0f, 0.2f, 0.2f, 0.5f)
                );

                if (fontErrors.Find(S_SystemFont) == -1) {
                    fontErrors.InsertLast(S_SystemFont);
                }
                S_SystemFont = "";
                S_Font = Font::DroidSans;
                ChangeFont();
                return;
            }
    }

    currentFont = S_Font;
}

[SettingsTab icon="Font" name="Font" order=1]
void SettingsTab_Font() {
    if (UI::BeginCombo("Font", S_Font == Font::System ? S_SystemFont : tostring(S_Font))) {
        if (UI::Selectable("DroidSans", S_Font == Font::DroidSans)) {
            S_Font = Font::DroidSans;
            ChangeFont();
        }

        if (UI::Selectable("DroidSansBold", S_Font == Font::DroidSansBold)) {
            S_Font = Font::DroidSansBold;
            ChangeFont();
        }

        if (UI::Selectable("DroidSansMono", S_Font == Font::DroidSansMono)) {
            S_Font = Font::DroidSansMono;
            ChangeFont();
        }

        if (UI::Selectable("Montserrat", S_Font == Font::Montserrat)) {
            S_Font = Font::Montserrat;
            ChangeFont();
        }

        if (UI::Selectable("MontserratBold", S_Font == Font::MontserratBold)) {
            S_Font = Font::MontserratBold;
            ChangeFont();
        }

        if (UI::Selectable("Oswald", S_Font == Font::Oswald)) {
            S_Font = Font::Oswald;
            ChangeFont();
        }

        if (UI::Selectable("OswaldBold", S_Font == Font::OswaldBold)) {
            S_Font = Font::OswaldBold;
            ChangeFont();
        }

        const string systemFonts = "C:/Windows/Fonts/";
        if (IO::FolderExists(systemFonts)) {
            UI::Separator();

            string[]@ files = IO::IndexFolder(systemFonts, false);
            for (uint i = 0; i < files.Length; i++) {
                if (files[i].ToLower().EndsWith(".ttf")) {
                    const string fileName = files[i].Replace(systemFonts, "");
                    const string displayName = fileName.Replace(".ttf", "").Replace(".TTF", "");
                    if (UI::Selectable(
                        (fontErrors.Find(fileName) > -1 ? "\\$F00" : "") + displayName + "##" + i,
                        S_SystemFont == fileName
                    )) {
                        S_Font = Font::System;
                        S_SystemFont = fileName;
                        ChangeFont();
                    }
                }
            }
        }

        UI::EndCombo();
    }

    S_FontSize = UI::SliderInt("Font size", S_FontSize, 8, 72);
}
