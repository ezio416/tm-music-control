// c 2023-08-23
// m 2024-01-19

const string apiUrl           = "https://api.spotify.com/v1";
bool         forceDevice      = false;
bool         forceDeviceTried = false;
bool         loopRunning      = false;
dictionary@  playlists        = dictionary();
bool         runLoop          = false;
int          seekPosition;
string       selectedPlaylist;

namespace API {
    enum ResponseCode {
        ExpiredAccess    = 401,
        InvalidOperation = 403,
        NoActiveDevice   = 404,
        TooManyRequests  = 429,
        Unavailable      = 503
    }

    void CycleRepeat() {
        trace("cycling repeat");

        string url = apiUrl + "/me/player/repeat?state=";
        switch (state.repeat) {
            case Repeat::off:     url += "context"; break;
            case Repeat::context: url += "track";   break;
            default:              url += "off";
        }

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = url;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation && resp.Contains("Premium required")) {
            NotifyWarn("sorry, you need a Premium account");
            warn("free account detected, disabling controls...");
            S_Premium = false;
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't cycle repeat type", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    // void GetCurrentSongIsInLibrary() {
    //     trace("checking if song \"" + state.song + "\" is in user's library");

    //     Net::HttpRequest@ req = Net::HttpRequest();
    //     req.Method = Net::HttpMethod::Get;
    //     req.Url = apiUrl + "/me/tracks/contains";
    //     req.Headers["Authorization"] = string(auth["access"]);
    //     req.Start();
    //     while (!req.Finished())
    //         yield();
    // }

    bool GetDevices() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/player/devices";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::ExpiredAccess) {
            startnew(Auth::Refresh);
            return true;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't get device list", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return false;
        }

        SetDevices(Json::Parse(resp).Get("devices"));

        return true;
    }

    bool GetPlaybackState() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/player";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::ExpiredAccess)
            return true;

        if (respCode == ResponseCode::NoActiveDevice) {
            NotifyWarn("no active device", true);
            return true;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't get playback state", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return false;
        }

        Json::Value json = Json::Parse(resp);
        state = activeDevice !is null ? State(json) : State();
        if (state.albumArtUrl64 != loadedAlbumArtUrl)
            startnew(LoadAlbumArt);

        return true;
    }

    bool GetPlaylists() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/playlists?limit=50";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::ExpiredAccess)
            return true;

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't get playlists", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return false;
        }

        Json::Value@ json = Json::Parse(resp);

        playlists.DeleteAll();

        string username = string(json["href"]).Replace("https://api.spotify.com/v1/users/", "").Replace("/playlists?offset=0&limit=50", "");
        playlists["spotify:user:" + username + ":collection"] = "Liked Songs";

        Json::Value@ items = json["items"];
        for (uint i = 0; i < items.Length; i++)
            playlists["spotify:playlist:" + string(items[i]["id"])] = string(items[i]["name"]);

        return true;
    }

    // void GetQueue() {
    //     ;
    // }

    // void GetRecentTracks() {
    //     Net::HttpRequest@ req = Net::HttpRequest();
    //     req.Method = Net::HttpMethod::Get;
    //     req.Url = apiUrl + "/me/player/recently-played";
    //     req.Headers["Authorization"] = string(auth["access"]);
    //     req.Start();
    //     while (!req.Finished())
    //         yield();

    //     string resp = req.String();
    //     int respCode = req.ResponseCode();

    //     if (respCode < 200 || respCode >= 400) {
    //         NotifyWarn("API error - please check Openplanet log");
    //         error("error getting recently played tracks");
    //         warn("response: " + respCode + " " + resp.Replace("\n", ""));
    //         return;
    //     }

    //     Json::Value json = Json::Parse(resp);
    //     Json::ToFile(IO::FromStorageFolder("test.json"), json);
    // }

    void Loop() {
        if (loopRunning)
            return;

        loopRunning = true;

        uint waitTimeDefault = 1000;
        uint waitTime = waitTimeDefault;

        while (true) {
            if (!Auth::Authorized() || !disclaimerAccepted)
                break;

            if (waitTime > waitTimeDefault)
                warn("waiting " + waitTime + "ms to try contacting API again");
            sleep(waitTime);

            if (!runLoop)
                break;

            if (!GetDevices()) {
                waitTime *= 2;
                continue;
            } else
                waitTime = waitTimeDefault;

            if (!GetPlaybackState()) {
                waitTime *= 2;
                continue;
            } else
                waitTime = waitTimeDefault;

            if (S_Playlists) {
                if (!GetPlaylists())
                    waitTime *= 2;
                else
                    waitTime = waitTimeDefault;
            }

            if (waitTime > 8 * waitTimeDefault)
                waitTime = 8 * waitTimeDefault;
        }

        loopRunning = false;
    }

    void Pause() {
        trace("pausing song");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = apiUrl + "/me/player/pause";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation) {
            if (resp.Contains("Premium required")) {
                NotifyWarn("sorry, you need a Premium account");
                warn("free account detected, disabling controls...");
                S_Premium = false;
                return;
            }

            startnew(Play);
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't pause playback", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void Play() {
        trace("playing song");

        string url = apiUrl + "/me/player/play";
        if (forceDevice) {
            url += "?device_id=" + lastDeviceId;
            forceDevice = false;
        }

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = url;
        req.Headers["Authorization"] = string(auth["access"]);

        if (selectedPlaylist.Length > 0) {
            try {
                trace("switching playlist to \"" + string(playlists[selectedPlaylist]) + "\"");
            } catch {
                warn("playlist \"" + selectedPlaylist + "\" not found");
            }

            req.Body = "{\"context_uri\":\"" + selectedPlaylist + "\"}";
            selectedPlaylist = "";
        }

        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation) {
            if (resp.Contains("Premium required")) {
                NotifyWarn("sorry, you need a Premium account");
                warn("free account detected, disabling controls...");
                S_Premium = false;
                return;
            }

            startnew(Play);
            return;
        }

        if (respCode == ResponseCode::NoActiveDevice) {
            if (forceDeviceTried) {
                NotifyWarn("couldn't find a device", true);
                forceDevice = false;
                forceDeviceTried = false;
                return;
            }

            warn("no active device, trying again...");
            forceDevice = true;
            forceDeviceTried = true;
            sleep(1000);
            startnew(Play);
            return;
        }

        forceDevice = false;

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't resume playback", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void Seek() {
        if (!S_Premium)
            return;

        trace(seekPosition == 0 ? "restarting song" : "seeking to " + FormatSeconds(seekPosition / 1000));

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = apiUrl + "/me/player/seek?position_ms=" + seekPosition;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation && resp.Contains("Premium required")) {
            NotifyWarn("sorry, you need a Premium account");
            warn("free account detected, disabling controls...");
            S_Premium = false;
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't seek in song", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void SkipNext() {
        trace("next song");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = apiUrl + "/me/player/next";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation && resp.Contains("Premium required")) {
            NotifyWarn("sorry, you need a Premium account");
            warn("free account detected, disabling controls...");
            S_Premium = false;
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't skip to next song", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void SkipPrevious() {
        trace("previous song");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = apiUrl + "/me/player/previous";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation && resp.Contains("Premium required")) {
            NotifyWarn("sorry, you need a Premium account");
            warn("free account detected, disabling controls...");
            S_Premium = false;
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't skip to previous song", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void ToggleShuffle() {
        trace("toggling shuffle");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = apiUrl + "/me/player/shuffle?state=" + !state.shuffle;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode == ResponseCode::InvalidOperation && resp.Contains("Premium required")) {
            NotifyWarn("sorry, you need a Premium account");
            warn("free account detected, disabling controls...");
            S_Premium = false;
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("couldn't toggle shuffle", true);
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    // void TransferPlaybackCoro() {
    //     if (
    //         activeDevice is null ||
    //         activeDevice.id == selectedDeviceId
    //     ) return;
    //     while (Time::Stamp - lastTransfer < 10) yield();  // wait between transfers
    //     print("transferring...");

    //     auto req = Net::HttpRequest();
    //     req.Method = Net::HttpMethod::Put;
    //     req.Url = apiUrl + "/me/player?play=true";
    //     req.Headers["Authorization"] = string(auth["access"]);
    //     req.Headers["Content-Type"] = "application/json";
    //     req.Body = "{\"device_ids\":[\"" + selectedDeviceId + "\"]}";
    //     req.Start();
    //     while (!req.Finished()) yield();

    //     int respCode = req.ResponseCode();
    //     string resp = req.String();
    //     if (respCode < 200 || respCode >= 400) {
    //         NotifyWarn("API error - please check Openplanet log");
    //         error("error transferring playback");
    //         warn("response: " + respCode + " " + resp.Replace("\n", ""));
    //     }

    //     lastTransfer = Time::Stamp;
    // }
}