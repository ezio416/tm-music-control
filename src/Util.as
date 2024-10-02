// c 2023-08-22
// m 2024-10-01

const string albumArtFolder    = IO::FromStorageFolder("albumArt");
bool         albumArtLoading   = false;
string       loadedAlbumArtUrl = "";
UI::Texture@ tex;

void Error(const string &in msg, bool log = true) {
    if (log)
        error(msg);

    if (S_Errors)
        UI::ShowNotification("MusicControl", msg, UI::HSV(0.02f, 0.8f, 0.9f));
}

string FormatSeconds(int seconds) {
    return Zpad(seconds / 60) + ":" + Zpad(seconds % 60);
}

void HoverTooltip(const string &in msg) {
    if (!UI::IsItemHovered())
        return;

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

    if (albumArtLoading)
        return;

    albumArtLoading = true;

    trace(
        state.album != "" ?
        "loading album art for \"" + state.album + "\"" :
        "clearing album art"
    );

    IO::CreateFolder(albumArtFolder);
    const string filepath = albumArtFolder + "/" + state.albumArtUrl64.Replace(":", "_").Replace("/", "_") + ".jpg";

    if (filepath == ".jpg") {  // probably wrong, fix at some point
        albumArtLoading = false;
        warn("blank album art");
        return;
    }

    if (!IO::FileExists(filepath)) {
        const uint max_timeout = 3000;
        const uint max_wait = 2000;

        while (true) {
            uint64 nowTimeout = Time::Now;
            bool timedOut = false;

            Net::HttpRequest@ req = Net::HttpGet(state.albumArtUrl64);
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
                while (Time::Now - nowWait < max_wait)
                    yield();
                continue;
            }

            req.SaveToFile(filepath);
            break;
        }
    }

    IO::File file(filepath, IO::FileMode::Read);
    @tex = UI::LoadTexture(file.Read(file.Size()));
    loadedAlbumArtUrl = state.albumArtUrl64;

    albumArtLoading = false;
}

string ReplaceBadQuotes(const string &in input) {
    return input.Replace("‘", "'").Replace("’", "'").Replace("“", "\"").Replace("”", "\"");
}

string ReplaceBadQuotes(Json::Value@ input) {
    if (input is null || input.GetType() != Json::Type::String)
        return "";

    return ReplaceBadQuotes(string(input));
}

void Warn(const string &in msg, bool log = true) {
    if (log)
        warn(msg);

    if (S_Warnings)
        UI::ShowNotification("MusicControl", msg, UI::HSV(0.1f, 0.8f, 0.9f));
}

string Zpad(uint num, uint digits = 2) {
    string zeroes = "";
    const string result = tostring(num);

    for (uint i = 0; i < digits - uint(result.Length); i++)
        zeroes += "0";

    return zeroes + result;
}
