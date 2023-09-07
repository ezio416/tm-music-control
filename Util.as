/*
c 2023-08-22
m 2023-09-07
*/

string       albumArtFolder    = IO::FromStorageFolder("albumArt");
string       loadedAlbumArtUrl = "";
UI::Texture@ tex               = UI::LoadTexture("Assets/1x1.png");

string FormatSeconds(int seconds) {
    return Zpad(seconds / 60) + ":" + Zpad(seconds % 60);
}

void LoadAlbumArtCoro() {
    trace(
        state.album != "" ?
        "loading album art for \"" + state.album + "\"" :
        "clearing album art"
    );

    IO::CreateFolder(albumArtFolder);
    string filepath = albumArtFolder + "/" + state.albumArtUrl64.Replace(":", "_").Replace("/", "_") + ".jpg";

    if (!IO::FileExists(filepath)) {
        uint max_timeout = 3000;
        uint max_wait = 2000;

        while (true) {
            uint64 nowTimeout = Time::Now;
            bool timedOut = false;

            auto req = Net::HttpGet(state.albumArtUrl64);
            while (!req.Finished()) {
                if (Time::Now - nowTimeout > max_timeout) {
                    timedOut = true;
                    break;
                }
                yield();
            }

            if (timedOut) {
                trace("timed out, waiting " + max_wait + " ms");
                uint64 nowWait = Time::Now;
                while (Time::Now - nowWait < max_wait) yield();
                continue;
            }

            req.SaveToFile(filepath);
            break;
        }
    }

    IO::File file(filepath, IO::FileMode::Read);
    @tex = UI::LoadTexture(file.Read(file.Size()));
    loadedAlbumArtUrl = state.albumArtUrl64;
}

void HoverTooltip(const string &in text) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
            UI::Text(text);
        UI::EndTooltip();
    }
}

void NotifyWarn(const string &in text, bool logWarn = false) {
    UI::ShowNotification("MusicControl", text, UI::HSV(0.02, 0.8, 0.9));
    if (logWarn)
        warn(text);
}

string Zpad(uint num, uint digits = 2) {
    string zeroes = "";
    string result = tostring(num);

    for (uint i = 0; i < digits - uint(result.Length); i++)
        zeroes += "0";

    return zeroes + result;
}