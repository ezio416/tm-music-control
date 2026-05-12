SpotifyToken@ spotify;
Token@        token;
// YoutubeToken@ youtube;

enum TokenType {
    Spotify,
    Youtube
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

    void Get() final {
        startnew(CoroutineFunc(GetAsync));
    }

    void GetAsync() {
        throw("implemented elsewhere");
    }

    void Init() {
        access = clientId = clientSecret = refresh = "";
    }

    bool Load() {
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

        if (!LoadOld()) {
            if (!Load()) {
                Get();
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

    void GetAsync() override {
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

    bool Load() override {
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

    bool LoadOld() {
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
            @json = req.Json();
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

// class YoutubeToken : Token {  // TODO yt token
//     YoutubeToken() {
//         AUTH_FILE = IO::FromStorageFolder("youtube.json");
//         type = TokenType::Youtube;
//     }

//     void Load() override {
//         if (!IO::FileExists(AUTH_FILE)) {
//             warn("youtube.json not found");
//         }

//         ;
//     }
// }
