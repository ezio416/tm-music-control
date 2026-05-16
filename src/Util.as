const string albumArtFolder    = IO::FromStorageFolder("albumArt");
bool         albumArtLoading   = false;
string       loadedAlbumArtUrl = "";
UI::Texture@ tex;

string FormatSeconds(const int seconds) {
    return Zpad(seconds / 60) + ":" + Zpad(seconds % 60);
}

void HoverTooltip(const string&in msg) {
    if (!UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
        return;
    }

    UI::BeginTooltip();
    UI::Text(msg);
    UI::EndTooltip();
}

void LoadAlbumArt() {
    if (!S_AlbumArt) {
        loadedAlbumArtUrl = "";
        @tex = null;
        return;
    }

    if (albumArtLoading) {
        return;
    }

    albumArtLoading = true;

    trace(
        state.album != "" ?
        "loading album art for \"" + state.album + "\"" :
        "clearing album art"
    );

    if (state.albumArtUrlSelected.Length == 0) {
        albumArtLoading = false;
        warn("Blank album art: " + state.album);
        return;
    }

    IO::CreateFolder(albumArtFolder);
    const string filepath = albumArtFolder + "/" + Path::SanitizeFileName(state.albumArtUrlSelected) + ".jpg";

    if (!IO::FileExists(filepath)) {
        const uint max_timeout = 3000;
        const uint max_wait = 2000;

        trace("downloading album art");

        while (true) {
            uint64 nowTimeout = Time::Now;
            bool timedOut = false;

            Net::HttpRequest@ req = Net::HttpGet(state.albumArtUrlSelected);
            while (!req.Finished()) {
                if (Time::Now - nowTimeout > max_timeout) {
                    timedOut = true;
                    break;
                }
                yield();
            }

            if (timedOut) {
                trace("timed out, waiting " + max_wait + " ms");
                const uint64 nowWait = Time::Now;
                while (Time::Now - nowWait < max_wait) {
                    yield();
                }
                continue;
            }

            req.SaveToFile(filepath);
            break;
        }
    }

    IO::File file(filepath, IO::FileMode::Read);
    @tex = UI::LoadTexture(file.Read(file.Size()));
    loadedAlbumArtUrl = state.albumArtUrlSelected;

    albumArtLoading = false;
}

string ReplaceBadQuotes(const string&in input) {
    return input.Replace("‘", "'").Replace("’", "'").Replace('“', '"').Replace('”', '"');
}

string ReplaceBadQuotes(Json::Value@ input) {
    if (false
        or input is null
        or input.GetType() != Json::Type::String
    ) {
        return "";
    }

    return ReplaceBadQuotes(string(input));
}

string Zpad(const uint num, const uint digits = 2) {
    return Text::Format("%0" + digits + "d", num);
}
