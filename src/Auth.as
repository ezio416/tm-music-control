// c 2023-08-22
// m 2024-01-19

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

        int respCode = req.ResponseCode();
        string resp = req.String();
        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("authorization error - please check Openplanet log");
            error("error getting authorization tokens");
            warn("response: " + respCode + " " + resp);
            return;
        }

        Json::Value json = Json::Parse(resp);
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

        if (
            !auth.HasKey("basic") ||
            !auth.HasKey("access") ||
            !auth.HasKey("refresh")
        ) {
            error("error in data from auth.json!");
            Init();
        }
    }

    void OpenPage() {
        OpenBrowserURL(
            "https://accounts.spotify.com/authorize?" +
            "client_id=" + clientId +
            "&response_type=code" +
            "&redirect_uri=" + redirectUri +
            "&scope=user-modify-playback-state user-read-playback-state user-read-recently-played playlist-read-private"
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

        int respCode = req.ResponseCode();
        string resp = req.String();
        if (respCode < 200 || respCode >= 400) {
            NotifyWarn("authorization error - please check Openplanet log");
            error("error refreshing authorization token");
            warn("response: " + respCode + " " + resp);
            return;
        }

        auth["access"] = "Bearer " + string(Json::Parse(resp)["access_token"]);
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