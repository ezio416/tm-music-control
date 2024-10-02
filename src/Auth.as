// c 2023-08-22
// m 2024-10-01

Json::Value@ auth             = Json::Object();
const string authFile         = IO::FromStorageFolder("auth.json");
const string authUrl          = "https://accounts.spotify.com/api";
string       callbackUrl      = "";
string       clientId         = "";
string       clientSecret     = "";
string       code             = "";
const string redirectUri      = "http://localhost:7777/callback";
int64        refreshTimestamp = 0;

namespace Auth {
    bool Authorized() {
        return string(auth["access"]).Length > 0;
    }

    void Clear() {
        Init();
        Save();
        S_Premium = true;
    }

    void Get() {
        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = authUrl + "/token?grant_type=authorization_code&code=" + code + "&redirect_uri=" + redirectUri;
        req.Headers["Authorization"] = string(auth["basic"]);
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Start();
        while (!req.Finished())
            yield();

        const int respCode = req.ResponseCode();

        if (respCode < 200 || respCode >= 400) {
            Error("Error getting authorization tokens");
            warn("response: " + respCode + " " + req.String());
            return;
        }

        Json::Value@ json = req.Json();
        auth["access"] = "Bearer " + string(json["access_token"]);
        auth["refresh"] = json["refresh_token"];
        Save();
    }

    void Init() {
        auth["basic"] = "";
        auth["access"] = "";
        auth["refresh"] = "";
    }

    void Load() {
        trace("loading auth.json...");

        if (!IO::FileExists(authFile)) {
            warn("auth.json not found!");
            Init();
            return;
        }

        try {
            auth = Json::FromFile(authFile);
        } catch {
            error("error loading auth.json!");
            warn(getExceptionInfo());
            Init();
            return;
        }

        if (false
            || !auth.HasKey("basic")
            || !auth.HasKey("access")
            || !auth.HasKey("refresh")
        ) {
            error("error in data from auth.json!");
            Init();
        }
    }

    void OpenPage() {
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
            "&redirect_uri=" + redirectUri +
            "&scope=" + string::Join(perms, " ")
        );
    }

    void Refresh() {
        trace("refreshing access token...");

        if (refreshTimestamp > 0)  // wait 5 seconds between refreshes just in case
            while (Time::Stamp - refreshTimestamp < 5)
                yield();

        Net::HttpRequest@ req = Net::HttpRequest();
        req.Method = Net::HttpMethod::Post;
        req.Url = authUrl + "/token?grant_type=refresh_token&refresh_token=" + string(auth["refresh"]);
        req.Headers["Authorization"] = string(auth["basic"]);
        req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
        req.Start();
        while (!req.Finished())
            yield();

        const int respCode = req.ResponseCode();

        if (respCode < 200 || respCode >= 400) {
            Error("Error refreshing authorization token");
            warn("response: " + respCode + " " + req.String());
            return;
        }

        auth["access"] = "Bearer " + string(req.Json()["access_token"]);
        Save();

        refreshTimestamp = Time::Stamp;
    }

    void Save() {
        trace("saving auth.json...");

        try {
            Json::ToFile(authFile, auth);
        } catch {
            error("error saving auth.json!");
            warn(getExceptionInfo());
        }
    }
}
