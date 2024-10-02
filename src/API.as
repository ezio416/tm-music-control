// c 2023-08-23
// m 2024-10-01

const string apiUrl           = "https://api.spotify.com/v1";
bool         forceDevice      = false;
bool         forceDeviceTried = false;
uint64       lastSeek         = 0;
uint64       lastVolume       = 0;
bool         loopRunning      = false;
dictionary@  playlists        = dictionary();
bool         runLoop          = false;
int          seekPosition     = 0;
string       selectedPlaylist;
int          volumeDesired    = 0;

namespace API {
    enum ResponseCode {
        Good            = 200,
        Created         = 201,
        Accepted        = 202,
        NoContent       = 204,
        NotModified     = 304,
        BadRequest      = 400,
        Unauthorized    = 401,
        Forbidden       = 403,
        NotFound        = 404,
        TooManyRequests = 429,
        InternalError   = 500,
        BadGateway      = 502,
        Unavailable     = 503
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

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("CycleRepeat(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("CycleRepeat", req);
                break;
            default:
                Error("Couldn't cycle repeat type");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    bool GetCurrentSongIsLiked() {
        if (state.songId.Length == 0)
            return true;

        // trace("checking if song \"" + state.song + "\" is in user's library");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/tracks/contains?ids=" + state.songId;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();
        const int respCode = req.ResponseCode();
        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::Unauthorized:  // handled by GetDevices()
            case ResponseCode::Forbidden:     // might be missing new permission (untested)
                state.songLiked = false;
                liked = false;
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetCurrentSongIsLiked", req);
            default:
                Error("Couldn't check if song is liked");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }
        Json::Value@ json = req.Json();
        liked = false;
        try {
            state.songLiked = bool(json[0]);
            liked = state.songLiked;
            return true;
        } catch {
            Error("Couldn't check if song is liked");
            warn("got: " + Json::Write(json));
        }
        return false;
    }

    bool GetDevices() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/player/devices";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::Unauthorized:
                startnew(Auth::Refresh);
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetDevices", req);
            default:
                Error("Couldn't get device list");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        SetDevices(req.Json().Get("devices"));

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

        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::NoContent:  // playback not active
            case ResponseCode::Unauthorized:  // handled by GetDevices()
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetPlaybackState", req);
            default:
                Error("Couldn't get playback state");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        state = activeDevice !is null ? State(req.Json()) : State();
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

        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::Unauthorized:  // handled by GetDevices()
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetPlaylists", req);
            default:
                Error("Couldn't get playlists");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        Json::Value@ json = req.Json();

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

        int waitTime = S_UpdateFreq;

        uint checkLiked     = 0;
        uint checkPlaylists = 0;

        while (true) {
            if (!Auth::Authorized() || !disclaimerAccepted)
                break;

            if (waitTime > S_UpdateFreq)
                Warn("Waiting " + waitTime + " ms to try contacting API again");
            sleep(waitTime);

            if (waitTime > S_UpdateFreq * 4)
                waitTime = S_UpdateFreq * 4;

            if (!runLoop) {
                state = State();
                break;
            }

            if (!S_AlbumArt_.heart)
                checkLiked = 0;

            if (!S_Playlists)
                checkPlaylists = 0;

            if (!GetDevices() || !GetPlaybackState()) {
                waitTime *= 2;
                continue;
            } else
                waitTime = S_UpdateFreq;

            if (S_AlbumArt_.heart && checkLiked++ % 5 == 0) {
                if (!GetCurrentSongIsLiked())
                    waitTime *= 2;
                else
                    waitTime = S_UpdateFreq;

                checkLiked = 1;
            }

            if (S_Playlists && checkPlaylists++ % 20 == 0) {
                if (!GetPlaylists())
                    waitTime *= 2;
                else
                    waitTime = S_UpdateFreq;

                checkPlaylists = 1;
            }
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

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    Premium();
                    return;
                }
                startnew(Play);
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("Pause", req);
                break;
            default:
                Error("Couldn't pause playback");
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
            if (playlists.Exists(selectedPlaylist))
                trace("switching playlist to \"" + string(playlists[selectedPlaylist]) + "\"");
            else
                warn("playlist \"" + selectedPlaylist + "\" not found");

            req.Body = "{\"context_uri\":\"" + selectedPlaylist + "\"}";
            selectedPlaylist = "";
        }

        req.Start();
        while (!req.Finished())
            yield();

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    Premium();
                    return;
                }
                startnew(Play);
                break;
            case ResponseCode::NotFound:
                if (forceDeviceTried) {
                    Error("Couldn't find a device");
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
            case ResponseCode::TooManyRequests:
                RateLimited("Play", req);
                break;
            default:
                Error("Couldn't resume playback");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        forceDevice = false;
    }

    void Seek() {
        if (!S_Premium)
            return;

        const uint64 now = Time::Now;
        if (now - lastSeek < 2000) {
            warn("wait to seek again");
            return;
        }

        trace(seekPosition == 0 ? "restarting song" : "seeking to " + FormatSeconds(seekPosition / 1000));

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = apiUrl + "/me/player/seek?position_ms=" + seekPosition;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("Seek(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("Seek", req);
                break;
            default:
                Error("Couldn't seek in song");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        lastSeek = now;
    }

    void SetVolume() {
        if (!S_Premium)
            return;

        const uint64 now = Time::Now;
        if (now - lastVolume < 2000) {
            warn("wait to change volume again");
            return;
        }

        trace("setting volume to " + volumeDesired + " %" + (S_Volume_.egg && volumeDesired == 69 ? " (nice)" : ""));

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = apiUrl + "/me/player/volume?volume_percent=" + volumeDesired;
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("SetVolume(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SetVolume", req);
                break;
            default:
                Error("Couldn't set volume");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        lastVolume = now;
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

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("SkipNext(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SkipNext", req);
                break;
            default:
                Error("Couldn't skip to next song");
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

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("SkipPrevious(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SkipPrevious", req);
                break;
            default:
                Error("Couldn't skip to previous song");
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

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required"))
                    Premium();
                else
                    warn("ToggleShuffle(): " + resp.Replace("\n", ""));
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("ToggleShuffle", req);
                break;
            default:
                Error("couldn't toggle shuffle");
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

    void Premium() {
        Error("Sorry, you need a Premium account");
        warn("free account detected, disabling controls...");
        S_Premium = false;
    }

    bool RateLimited(const string &in func, Net::HttpRequest@ req) {
        const dictionary@ headers = req.ResponseHeaders();
        const string msg = func + "(): rate limited" + (headers.Exists("retry-after") ? ", try again after " + string(headers["retry-after"]) + "s" : "");

        Error(msg);

        return true;
    }
}
