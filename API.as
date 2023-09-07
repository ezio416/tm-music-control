/*
c 2023-08-23
m 2023-09-07
*/

string apiUrl           = "https://api.spotify.com/v1";
bool   forceDevice      = false;
bool   forceDeviceTried = false;

enum ResponseCode {
    ExpiredAccess    = 401,
    InvalidOperation = 403,
    NoActiveDevice   = 404,
    TooManyRequests  = 429,
    Unavailable      = 503
}

void GetDevicesCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Get;
    req.Url = apiUrl + "/me/player/devices";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == ResponseCode::ExpiredAccess) {
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error getting devices");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
        return;
    }

    SetDevices(Json::Parse(resp).Get("devices"));
}

void GetPlaybackStateCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Get;
    req.Url = apiUrl + "/me/player";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == ResponseCode::ExpiredAccess)
        return;
    if (respCode == ResponseCode::NoActiveDevice) {
        NotifyWarn("No currently active device", true);
        return;
    }

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error getting playback state");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
        return;
    }

    Json::Value json = Json::Parse(resp);
    state = @activeDevice != null ? State(json) : State();
    if (state.albumArtUrl64 != loadedAlbumArtUrl)
        startnew(CoroutineFunc(LoadAlbumArtCoro));
    // Json::ToFile(IO::FromStorageFolder("test.json"), json);
}

void GetRecentTracksCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Get;
    req.Url = apiUrl + "/me/player/recently-played";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error getting recently played tracks");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
        return;
    }

    Json::Value json = Json::Parse(resp);
    Json::ToFile(IO::FromStorageFolder("test.json"), json);
}

void PauseCoro() {
    string url = apiUrl + "/me/player/pause";

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == ResponseCode::InvalidOperation) {
        startnew(CoroutineFunc(PlayCoro));
        return;
    }

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error pausing playback");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void PlayCoro() {
    string url = apiUrl + "/me/player/play";
    if (forceDevice) {
        url += "?device_id=" + lastDeviceId;
        forceDevice = false;
    }

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == ResponseCode::InvalidOperation) {
        startnew(CoroutineFunc(PauseCoro));
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
        startnew(CoroutineFunc(PlayCoro));
        return;
    }

    forceDevice = false;

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error resuming playback");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void SkipNextCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Post;
    req.Url = apiUrl + "/me/player/next";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error skipping to next track");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void SkipPreviousCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Post;
    req.Url = apiUrl + "/me/player/previous";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error skipping to previous track");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void ToggleShuffleCoro() {
    string url = apiUrl + "/me/player/shuffle?state=" + !state.shuffle;
    // if (selectedDeviceId.Length > 0)
    //     url += "&device_id=" + selectedDeviceId;

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error toggling shuffle");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void CycleRepeatCoro() {
    string url = apiUrl + "/me/player/repeat?state=";
    switch (state.repeat) {
        case Repeat::off:     url += "context"; break;
        case Repeat::context: url += "track";   break;
        default:              url += "off";
    }
    // if (selectedDeviceId.Length > 0)
    //     url += "&device_id=" + selectedDeviceId;

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error cycling repeat type");
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