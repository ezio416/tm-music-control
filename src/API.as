/*
c 2023-08-23
m 2023-11-28
*/

string apiUrl           = "https://api.spotify.com/v1";
bool   forceDevice      = false;
bool   forceDeviceTried = false;
int    seekPosition;

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
            NotifyWarn("Sorry, you need a Premium account");
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error cycling repeat type");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void GetDevices() {
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
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error getting devices");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return;
        }

        SetDevices(Json::Parse(resp).Get("devices"));
    }

    void GetPlaybackState() {
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
            return;

        if (respCode == ResponseCode::NoActiveDevice) {
            NotifyWarn("No currently active device", true);
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error getting playback state");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return;
        }

        Json::Value json = Json::Parse(resp);
        state = activeDevice !is null ? State(json) : State();
        if (state.albumArtUrl64 != loadedAlbumArtUrl)
            startnew(LoadAlbumArt);
        // Json::ToFile(IO::FromStorageFolder("test.json"), json);
    }

    void GetRecentTracks() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = apiUrl + "/me/player/recently-played";
        req.Headers["Authorization"] = string(auth["access"]);
        req.Start();
        while (!req.Finished())
            yield();

        string resp = req.String();
        int respCode = req.ResponseCode();

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error getting recently played tracks");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
            return;
        }

        Json::Value json = Json::Parse(resp);
        Json::ToFile(IO::FromStorageFolder("test.json"), json);
    }

    void Pause() {
        trace("pausing");

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
                NotifyWarn("Sorry, you need a Premium account");
                return;
            }

            startnew(Play);
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error pausing playback");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void Play() {
        trace("playing");

        string url = apiUrl + "/me/player/play";
        if (forceDevice) {
            url += "?device_id=" + lastDeviceId;
            forceDevice = false;
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

        if (respCode == ResponseCode::InvalidOperation) {
            if (resp.Contains("Premium required")) {
                NotifyWarn("Sorry, you need a Premium account");
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
            NotifyWarn("API error - please check Openplanet log");
            error("error resuming playback");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void Seek() {
        trace(seekPosition == 0 ? "restarting" : "seeking to " + FormatSeconds(seekPosition / 1000));

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
            NotifyWarn("Sorry, you need a Premium account");
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error seeking");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void SkipNext() {
        trace("next");

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
            NotifyWarn("Sorry, you need a Premium account");
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error skipping to next track");
            warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void SkipPrevious() {
        trace("previous");

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
            NotifyWarn("Sorry, you need a Premium account");
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error skipping to previous track");
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
            NotifyWarn("Sorry, you need a Premium account");
            return;
        }

        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("API error - please check Openplanet log");
            error("error toggling shuffle");
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