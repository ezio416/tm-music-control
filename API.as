/*
c 2023-08-23
m 2023-08-24
*/

string   apiUrl  = "https://api.spotify.com/v1";
Endpoint lastReq = Endpoint::None;

enum Endpoint {
    None,
    GetDevices,
    GetPlaybackState,
    GetRecentTracks,
    PausePlayback,
    ResumePlayback,
    SkipNext,
    SkipPrevious
}

void GetDevicesCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Get;
    req.Url = apiUrl + "/me/player/devices";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == 401) {
        lastReq = Endpoint::GetDevices;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error getting devices");
        warn("response: " + respCode + " " + resp);
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
    if (respCode == 401) {
        lastReq = Endpoint::GetPlaybackState;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error getting playback state");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
        return;
    }

    Json::Value json = Json::Parse(resp);
    Json::ToFile(IO::FromStorageFolder("test.json"), json);
    try {
        Json::Value device = json.Get("device");
        string deviceName = string(device["name"]);
        uint volume = uint(device["volume_percent"]);

        bool shuffle = bool(json["shuffle_state"]);
        string repeat = string(json["repeat_state"]);
        uint64 timestamp = uint64(double(json["timestamp"]));
        uint64 progress = uint64(json["progress_ms"]);

        Json::Value track = json.Get("item");
        uint64 duration = uint64(track["duration_ms"]);

        print(
            "device:\\$0FA " + deviceName +
            "\\$G volume:\\$0FA " + volume +
            "\\$G shuffle:\\$0FA " + shuffle +
            "\\$G repeat:\\$0FA " + repeat +
            "\\$G timestamp:\\$0FA " + timestamp +
            "\\$G progress:\\$0FA " + progress +
            "\\$G duration:\\$0FA " + duration
        );
    } catch {
        print("no active device");
    }
}

void GetRecentTracksCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Get;
    req.Url = apiUrl + "/me/player/recently-played";
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == 401) {
        lastReq = Endpoint::GetRecentTracks;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

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

void PausePlaybackCoro() {
    string url = apiUrl + "/me/player/pause";
    if (selectedDeviceId.Length > 0)
        url += "?device_id=" + selectedDeviceId;

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == 401) {
        lastReq = Endpoint::PausePlayback;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

    if (respCode == 403) {
        startnew(CoroutineFunc(ResumePlaybackCoro));
        return;
    }

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error pausing playback");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}

void ResumePlaybackCoro() {
    string url = apiUrl + "/me/player/play";
    if (selectedDeviceId.Length > 0)
        url += "?device_id=" + selectedDeviceId;

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Put;
    req.Url = url;
    req.Headers["Authorization"] = string(auth["access"]);
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    if (respCode == 401) {
        lastReq = Endpoint::ResumePlayback;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

    if (respCode == 403) {
        startnew(CoroutineFunc(PausePlaybackCoro));
        return;
    }

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
    if (respCode == 401) {
        lastReq = Endpoint::SkipNext;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

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
    if (respCode == 401) {
        lastReq = Endpoint::SkipPrevious;
        startnew(CoroutineFunc(RefreshCoro));
        return;
    }

    lastReq = Endpoint::None;

    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("API error - please check Openplanet log");
        error("error skipping to previous track");
        warn("response: " + respCode + " " + resp.Replace("\n", ""));
    }
}