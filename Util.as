/*
c 2023-08-22
m 2023-08-24
*/

string       albumArtFolder    = IO::FromStorageFolder("albumArt");
string       loadedAlbumArtUrl = "";
UI::Texture@ tex               = UI::LoadTexture("Assets/1x1.png");

void LoadAlbumArtCoro() {
    print("loading album art for \"" + state.album + "\"");

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

void NotifyWarn(const string &in text) {
    UI::ShowNotification("MusicControl", text, UI::HSV(0.02, 0.8, 0.9));
}