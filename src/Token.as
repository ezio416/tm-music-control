SpotifyToken@ spotify;
YoutubeToken@ youtube;

Token@ get_token() {
    switch (S_API) {
        case TokenType::Spotify: return spotify;
        case TokenType::YouTube: return youtube;
        default:                 return null;
    }
}

enum TokenType {
    Spotify,
    YouTube
}

abstract class Token {
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

    void GetToken() final {
        startnew(CoroutineFunc(GetTokenAsync));
    }

    void GetTokenAsync() {
        throw("implemented elsewhere");
    }

    void Init() {
        access = clientId = clientSecret = refresh = "";
    }

    bool LoadToken() {
        throw("implemented elsewhere");
        return false;  // for compiler
    }

    void Refresh() final {
        startnew(CoroutineFunc(RefreshAsync));
    }

    void RefreshAsync() {
        throw("implemented elsewhere");
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

    void SetCode() {
        code = callbackUrl.Split(REDIRECT_URI + "?code=")[1];
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
    // private string YTM_DOMAIN       = "https://music.youtube.com";
    // private string YTM_BASE_API     = YTM_DOMAIN + "/youtubei/v1/";
    // private string YTM_PARAMS       = "?alt=json";
    // private string YTM_PARAMS_KEY   = "&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30";

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
