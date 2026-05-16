SpotifyToken@ spotify;
YoutubeToken@ youtube;

Token@ get_token() {
    switch (S_API) {
        case TokenType::Spotify: return spotify;
        case TokenType::YouTube: return youtube;
        default:                 return null;
    }
}

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

enum TokenType {
    Spotify,
    YouTube
}

abstract class Token {
    protected string API_BASE_URL;
    protected string AUTH_FILE;

    string           access;
    string           clientId;
    string           clientSecret;
    protected string refresh;
    protected int64  timestamp = 0;
    TokenType        type;

    bool get_authorized() final {
        return access.Length > 0;
    }

    void CycleRepeat() final {
        startnew(CoroutineFunc(CycleRepeatAsync));
    }

    void CycleRepeatAsync() {
        NotImplemented();
    }

    protected Net::HttpRequest@ GetAsync(const string&in endpoint) {
        NotImplemented();
        return null;  // for compiler
    }

    bool GetCurrentSongIsLikedAsync() {
        NotImplemented();
        return false;  // for compiler
    }

    bool GetDevicesAsync() {
        NotImplemented();
        return false;  // for compiler
    }

    bool GetPlaybackStateAsync() {
        NotImplemented();
        return false;  // for compiler
    }

    bool GetPlaylistsAsync() {
        NotImplemented();
        return false;  // for compiler
    }

    void GetToken() final {
        startnew(CoroutineFunc(GetTokenAsync));
    }

    void GetTokenAsync() {
        NotImplemented();
    }

    void Init() {
        access = clientId = clientSecret = refresh = "";
    }

    protected void InvalidSubscription() {
        NotImplemented();
    }

    bool LoadToken() {
        NotImplemented();
        return false;  // for compiler
    }

    private void NotImplemented() {
        throw("implemented elsewhere");
    }

    void Pause() final {
        startnew(CoroutineFunc(PauseAsync));
    }

    void PauseAsync() {
        NotImplemented();
    }

    void Play() final {
        startnew(CoroutineFunc(PlayAsync));
    }

    void PlayAsync() {
        NotImplemented();
    }

    protected Net::HttpRequest@ PostAsync(const string&in endpoint, const string&in body = "") {
        NotImplemented();
        return null;  // for compiler
    }

    protected Net::HttpRequest@ PutAsync(const string&in endpoint, const string&in body = "") {
        NotImplemented();
        return null;  // for compiler
    }

    protected bool RateLimited(const string&in func, Net::HttpRequest@ req) {
        NotImplemented();
        return false;  // for compiler
    }

    void Refresh() final {
        startnew(CoroutineFunc(RefreshAsync));
    }

    void RefreshAsync() {
        NotImplemented();
    }

    void Save() final {
        if (AUTH_FILE.Length == 0) {
            throw("auth file path not set");
        }

        try {
            Json::ToFile(AUTH_FILE, ToJson(), true);
        } catch {
            error("error saving " + tostring(type) + " token: " + getExceptionInfo());
        }
    }

    void Seek() final {
        startnew(CoroutineFunc(SeekAsync));
    }

    void SeekAsync() {
        NotImplemented();
    }

    void SetVolume() final {
        startnew(CoroutineFunc(SetVolumeAsync));
    }

    void SetVolumeAsync() {
        NotImplemented();
    }

    void SkipNext() final {
        startnew(CoroutineFunc(SkipNextAsync));
    }

    void SkipNextAsync() {
        NotImplemented();
    }

    void SkipPrevious() final {
        startnew(CoroutineFunc(SkipPreviousAsync));
    }

    void SkipPreviousAsync() {
        NotImplemented();
    }

    void ToggleShuffle() final {
        startnew(CoroutineFunc(ToggleShuffleAsync));
    }

    void ToggleShuffleAsync() {
        NotImplemented();
    }

    Json::Value@ ToJson() {
        Json::Value json = Json::Object();
        json["access"] = access;
        json["refresh"] = refresh;
        json["timestamp"] = timestamp;
        return json;
    }
}

class SpotifyToken : Token {
    private string AUTH_BASE_URL = "https://accounts.spotify.com/api";
    private string AUTH_FILE_OLD = IO::FromStorageFolder("auth.json");
    private string REDIRECT_URI  = "http://127.0.0.1:7777/callback";

    string basic;
    string callbackUrl;
    string code;

    SpotifyToken() {
        API_BASE_URL = "https://api.spotify.com/v1";
        AUTH_FILE = IO::FromStorageFolder("spotify.json");
        type = TokenType::Spotify;

        if (!LoadOldToken()) {
            if (!LoadToken()) {
                GetToken();
            }
        }
    }

    ~SpotifyToken() {
        if (true
            and access.Length > 0
            and basic.Length > 0
            and refresh.Length > 0
        ) {
            Save();
        }
    }

    void CopyRedirect() {
        IO::SetClipboard(REDIRECT_URI);
    }

    void CycleRepeatAsync() override {
        trace("cycling repeat");

        string endpoint = "/me/player/repeat?state=";
        switch (state.repeat) {
            case Repeat::off:     endpoint += "context"; break;
            case Repeat::context: endpoint += "track";   break;
            default:              endpoint += "off";
        }

        Net::HttpRequest@ req = PutAsync(endpoint);

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("CycleRepeat(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("CycleRepeat", req);
                break;
            default:
                error("Couldn't cycle repeat type");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    Net::HttpRequest@ GetAsync(const string&in endpoint) override {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Get;
        req.Url = API_BASE_URL + endpoint;
        req.Headers["Authorization"] = token.access;

        req.Start();
        while (!req.Finished()) {
            yield();
        }

        return req;
    }

    bool GetCurrentSongIsLikedAsync() override {
        if (state.songId.Length == 0) {
            return true;
        }

        // trace("checking if song \"" + state.song + "\" is in user's library");

        Net::HttpRequest@ req = GetAsync("/me/tracks/contains?ids=" + state.songId);

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
                error("Couldn't check if song is liked");
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
            error("Couldn't check if song is liked");
            warn("got: " + Json::Write(json));
        }

        return false;
    }

    bool GetDevicesAsync() override {
        Net::HttpRequest@ req = GetAsync("/me/player/devices");

        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::Unauthorized:
                token.Refresh();
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetDevices", req);
            default:
                error("Couldn't get device list");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        SetDevices(req.Json().Get("devices"));

        return true;
    }

    bool GetPlaybackStateAsync() override {
        Net::HttpRequest@ req = GetAsync("/me/player");

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
                error("Couldn't get playback state");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        state.Update(activeDevice !is null ? req.Json() : null);

        if (state.albumArtUrlSelected != loadedAlbumArtUrl) {
            startnew(LoadAlbumArt);
        }

        return true;
    }

    bool GetPlaylistsAsync() override {
        Net::HttpRequest@ req = GetAsync("/me/playlists?limit=50");

        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
                break;
            case ResponseCode::Unauthorized:  // handled by GetDevices()
                return true;
            case ResponseCode::TooManyRequests:
                return RateLimited("GetPlaylists", req);
            default:
                error("Couldn't get playlists");
                warn("response: " + respCode + " " + req.String().Replace("\n", ""));
                return false;
        }

        Json::Value@ json = req.Json();

        playlists.DeleteAll();

        string username = string(json["href"]).Replace("https://api.spotify.com/v1/users/", "").Replace("/playlists?offset=0&limit=50", "");
        playlists["spotify:user:" + username + ":collection"] = "Liked Songs";

        Json::Value@ items = json["items"];
        for (uint i = 0; i < items.Length; i++) {
            playlists["spotify:playlist:" + string(items[i]["id"])] = string(items[i]["name"]);
        }

        return true;
    }

    void GetTokenAsync() override {
        if (false
            or basic.Length == 0
            or code.Length == 0
        ) {
            return;
        }

        trace("getting Spotify token");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = AUTH_BASE_URL + "/token?grant_type=authorization_code&code=" + code + "&redirect_uri=" + REDIRECT_URI;
        req.Headers["Authorization"] = basic;
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        const int respCode = req.ResponseCode();

        if (false
            or respCode < 200
            or respCode >= 400
        ) {
            error("error getting Spotify token (" + respCode + "): " + req.String());
            return;
        }

        Json::Value@ json;
        try {
            @json = req.Json();
            access = "Bearer " + string(json["access_token"]);
            refresh = json["refresh_token"];
            trace("got Spotify token");
            timestamp = Time::Stamp;
            Save();
        } catch {
            error("error getting Spotify token: " + getExceptionInfo() + ": " + Json::Write(json));
        }
    }

    void Init() override {
        Token::Init();
        basic = code = "";
    }

    void InvalidSubscription() override {
        error("Sorry, you need a Premium account");
        warn("free account detected, disabling plugin...");
        S_Premium = false;
    }

    bool LoadToken() override {
        trace("loading Spotify token");

        if (!IO::FileExists(AUTH_FILE)) {
            warn("spotify.json not found");
            Init();
            return false;
        }

        Json::Value@ json;
        try {
            @json     = Json::FromFile(AUTH_FILE);
            access    = json["access"];
            basic     = json["basic"];
            refresh   = json["refresh"];
            timestamp = json["timestamp"];
            trace("loaded Spotify token");
            return true;
        } catch {
            error("error loading Spotify token: " + getExceptionInfo() + ": " + Json::Write(json));
            return false;
        }
    }

    bool LoadOldToken() {
        if (!IO::FileExists(AUTH_FILE_OLD)) {
            return false;
        }

        print("loading old Spotify token");

        Json::Value@ json;
        bool success = false;
        try {
            @json   = Json::FromFile(AUTH_FILE_OLD);
            access  = json["access"];
            basic   = json["basic"];
            refresh = json["refresh"];
            print("loaded old Spotify token");
            success = true;
        } catch {
            error("error loading old Spotify token: " + getExceptionInfo() + ": " + Json::Write(json));
        }

        try {
            IO::Delete(AUTH_FILE_OLD);
            print("deleted old Spotify token");
        } catch {
            error("error deleting old Spotify token: " + getExceptionInfo());
        }

        return success;
    }

    void OpenAuthPage() {
        const string[] perms = {
            "playlist-read-private",        // 0.4.0
            "user-library-read",            // 0.4.0
            "user-modify-playback-state",   // 0.1.0
            "user-read-currently-playing",  // 0.4.0
            "user-read-playback-state",     // 0.1.0
            "user-read-recently-played"     // 0.1.0
        };

        OpenBrowserURL(
            "https://accounts.spotify.com/authorize?" +
            "client_id=" + clientId +
            "&response_type=code" +
            "&redirect_uri=" + REDIRECT_URI +
            "&scope=" + Text::Join(perms, " ")
        );
    }

    void PauseAsync() override {
        if (!S_Premium) {
            return;
        }

        trace("pausing song");

        Net::HttpRequest@ req = PutAsync("/me/player/pause");

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                    return;
                }
                Play();
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("Pause", req);
                break;
            default:
                error("Couldn't pause playback");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void PlayAsync() override {
        if (!S_Premium) {
            return;
        }

        trace("playing song");

        string endpoint = "/me/player/play";
        if (forceDevice) {
            endpoint += "?device_id=" + lastDeviceId;
            forceDevice = false;
        }

        string body;
        if (selectedPlaylist.Length > 0) {
            if (playlists.Exists(selectedPlaylist)) {
                trace("switching playlist to '" + string(playlists[selectedPlaylist]) + "'");
            } else {
                warn("playlist '" + selectedPlaylist + "' not found");
            }

            body = '{"context_uri":"' + selectedPlaylist + '"}';
            selectedPlaylist = "";
        }

        Net::HttpRequest@ req = PutAsync(endpoint, body);

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                    return;
                }
                // Play();  // why is this here
                break;
            case ResponseCode::NotFound:
                if (forceDeviceTried) {
                    error("Couldn't find a device");
                    forceDevice = false;
                    forceDeviceTried = false;
                    return;
                }
                warn("no active device, trying again...");
                forceDevice = true;
                forceDeviceTried = true;
                sleep(1000);
                Play();
                return;
            case ResponseCode::TooManyRequests:
                RateLimited("Play", req);
                break;
            default:
                error("Couldn't resume playback");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        forceDevice = false;
    }

    Net::HttpRequest@ PostAsync(const string&in endpoint, const string&in body = "") override {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = API_BASE_URL + endpoint;
        req.Headers["Authorization"] = token.access;
        req.Body = body;

        req.Start();
        while (!req.Finished()) {
            yield();
        }

        return req;
    }

    Net::HttpRequest@ PutAsync(const string&in endpoint, const string&in body = "") override {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Put;
        req.Url = API_BASE_URL + endpoint;
        req.Headers["Authorization"] = token.access;
        req.Body = body;

        req.Start();
        while (!req.Finished()) {
            yield();
        }

        return req;
    }

    bool RateLimited(const string&in func, Net::HttpRequest@ req) override {
        const dictionary@ headers = req.ResponseHeaders();
        const string msg = func + "(): rate limited" + (headers.Exists("retry-after") ? ", try again after "
            + string(headers["retry-after"]) + "s" : "");

        error(msg);

        return true;
    }

    void RefreshAsync() override {
        trace("refreshing Spotify token");

        const int64 diff = Time::Stamp - timestamp;
        if (diff < 5) {
            sleep(5 - diff);
        }

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = AUTH_BASE_URL + "/token?grant_type=refresh_token&refresh_token=" + refresh;
        req.Headers["Authorization"] = basic;
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        const int respCode = req.ResponseCode();

        if (false
            or respCode < 200
            or respCode >= 400
        ) {
            error("error refreshing Spotify token (" + respCode + "): " + req.String());
            return;
        }

        Json::Value@ json;
        try {
            @json  = req.Json();
            access = "Bearer " + string(json["access_token"]);
            trace("refreshed Spotify token");
            timestamp = Time::Stamp;
            Save();
        } catch {
            error("error refreshing Spotify token: " + getExceptionInfo() + ": " + Json::Write(json));
        }
    }

    void SeekAsync() override {
        if (!S_Premium) {
            return;
        }

        const uint64 now = Time::Now;
        if (now - lastSeek < 2000) {
            warn("wait to seek again");
            return;
        }

        trace(seekPosition == 0 ? "restarting song" : "seeking to " + FormatSeconds(seekPosition / 1000));

        Net::HttpRequest@ req = PutAsync("/me/player/seek?position_ms=" + seekPosition);

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("Seek(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("Seek", req);
                break;
            default:
                error("Couldn't seek in song");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        lastSeek = now;
    }

    void SetCode() {
        code = callbackUrl.Split(REDIRECT_URI + "?code=")[1];
    }

    void SetVolumeAsync() override {
        if (!S_Premium) {
            return;
        }

        const uint64 now = Time::Now;
        if (now - lastVolume < 2000) {
            warn("wait to change volume again");
            return;
        }

        trace("setting volume to " + volumeDesired + " %" + (S_Volume_Cond.egg && volumeDesired == 69 ? " (nice)" : ""));

        Net::HttpRequest@ req = PutAsync("/me/player/volume?volume_percent=" + volumeDesired);

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("SetVolume(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SetVolume", req);
                break;
            default:
                error("Couldn't set volume");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }

        lastVolume = now;
    }

    void SkipNextAsync() override {
        if (!S_Premium) {
            return;
        }

        trace("next song");

        Net::HttpRequest@ req = PostAsync("/me/player/next");

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("SkipNext(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SkipNext", req);
                break;
            default:
                error("Couldn't skip to next song");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void SkipPreviousAsync() override {
        if (!S_Premium) {
            return;
        }

        trace("previous song");

        Net::HttpRequest@ req = PostAsync("/me/player/previous");

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("SkipPrevious(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("SkipPrevious", req);
                break;
            default:
                error("Couldn't skip to previous song");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    void ToggleShuffleAsync() override {
        if (!S_Premium) {
            return;
        }

        trace("toggling shuffle");

        Net::HttpRequest@ req = PutAsync("/me/player/shuffle?state=" + !state.shuffle);

        const string resp = req.String();
        const int respCode = req.ResponseCode();

        switch (respCode) {
            case ResponseCode::Good:
            case ResponseCode::NoContent:
                break;
            case ResponseCode::Forbidden:
                if (resp.Contains("Premium required")) {
                    InvalidSubscription();
                } else {
                    warn("ToggleShuffle(): " + resp.Replace("\n", ""));
                }
                break;
            case ResponseCode::TooManyRequests:
                RateLimited("ToggleShuffle", req);
                break;
            default:
                error("couldn't toggle shuffle");
                warn("response: " + respCode + " " + resp.Replace("\n", ""));
        }
    }

    Json::Value@ ToJson() override {
        Json::Value@ json = Token::ToJson();
        json["basic"] = basic;
        return json;
    }
}

class YoutubeToken : Token {
    private string OAUTH_CODE_URL   = "https://www.youtube.com/o/oauth2/device/code";
    private string OAUTH_SCOPE      = "https://www.googleapis.com/auth/youtube";
    private string OAUTH_TOKEN_URL  = "https://oauth2.googleapis.com/token";
    private string USER_AGENT       = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:88.0) Gecko/20100101 Firefox/88.0";
    private string OAUTH_USER_AGENT = USER_AGENT + " Cobalt/Version";
    private string TOKEN_GRANT_TYPE = "urn:ietf:params:oauth:grant-type:device_code";

    string deviceCode;
    string userCode;
    string verificationUrl;

    YoutubeToken() {
        AUTH_FILE = IO::FromStorageFolder("youtube.json");
        type = TokenType::YouTube;

        if (!LoadToken()) {
            GetToken();
        }
    }

    ~YoutubeToken() {
        if (true
            and access.Length > 0
            and clientSecret.Length > 0
            and refresh.Length > 0
        ) {
            Save();
        }
    }

    void GetTokenAsync() override {
        if (false
            or clientSecret.Length == 0
            or deviceCode.Length == 0
        ) {
            return;
        }

        trace("getting YouTube token");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = OAUTH_TOKEN_URL + "?client_id=" + clientId + "&client_secret=" + clientSecret
            + "&device_code=" + deviceCode + "&grant_type=" + TOKEN_GRANT_TYPE;
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        const int respCode = req.ResponseCode();

        if (false
            or respCode < 200
            or respCode >= 400
        ) {
            error("error getting YouTube token (" + respCode + "): " + req.String());
            return;
        }

        Json::Value@ json;
        try {
            @json   = req.Json();
            access  = "Bearer " + string(json["access_token"]);
            refresh = json["refresh_token"];
            trace("got YouTube token");
            timestamp = Time::Stamp;
            Save();
        } catch {
            error("error getting YouTube token: " + getExceptionInfo() + ": " + Json::Write(json));
        }
    }

    void GetCodes() {
        startnew(CoroutineFunc(GetCodesAsync));
    }

    void GetCodesAsync() {
        if (false
            or clientId.Length == 0
            or clientSecret.Length == 0
        ) {
            return;
        }

        trace("getting YouTube codes");

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = OAUTH_CODE_URL + "?client_id=" + clientId + "&scope=" + OAUTH_SCOPE;
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Headers["User-Agent"] = OAUTH_USER_AGENT;
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        const int respCode = req.ResponseCode();

        if (false
            or respCode < 200
            or respCode >= 400
        ) {
            error("error getting YouTube codes (" + respCode + "): " + req.String());
            return;
        }

        Json::Value@ json;
        try {
            @json           = req.Json();
            deviceCode      = json["device_code"];
            userCode        = json["user_code"];
            verificationUrl = json["verification_url"];
            trace("got YouTube codes");
        } catch {
            error("error getting YouTube codes: " + getExceptionInfo() + ": " + Json::Write(json));
        }
    }

    bool LoadToken() override {
        trace("loading YouTube token");

        if (!IO::FileExists(AUTH_FILE)) {
            warn("youtube.json not found");
            Init();
            return false;
        }

        Json::Value@ json;
        try {
            @json        = Json::FromFile(AUTH_FILE);
            access       = json["access"];
            clientSecret = json["clientSecret"];
            refresh      = json["refresh"];
            timestamp    = json["timestamp"];
            trace("loaded YouTube token");
            return true;
        } catch {
            error("error loading YouTube token: " + getExceptionInfo() + ": " + Json::Write(json));
            return false;
        }
    }

    void RefreshAsync() override {
        trace("refreshing YouTube token");

        const int64 diff = Time::Stamp - timestamp;
        if (diff < 5) {
            sleep(5 - diff);
        }

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = OAUTH_TOKEN_URL + "?client_secret=" + clientSecret + "&grant_type=refresh_token&refresh_token=" + refresh;
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        const int respCode = req.ResponseCode();

        if (false
            or respCode < 200
            or respCode >= 400
        ) {
            error("error refreshing YouTube token (" + respCode + "): " + req.String());
            return;
        }

        Json::Value@ json;
        try {
            @json  = req.Json();
            access = "Bearer " + string(json["access_token"]);
            trace("refreshed YouTube token");
            timestamp = Time::Stamp;
            Save();
        } catch {
            error("error refreshing YouTube token: " + getExceptionInfo() + ": " + Json::Write(json));
        }
    }

    Json::Value@ ToJson() override {
        Json::Value@ json = Token::ToJson();
        json["clientSecret"] = clientSecret;
        return json;
    }
}
