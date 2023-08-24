/*
c 2023-08-22
m 2023-08-23
*/

Json::Value auth;
string      authFile     = IO::FromStorageFolder("auth.json");
string      authUrl      = "https://accounts.spotify.com/api/";
string      callbackUrl  = "";
string      clientId     = "";
string      clientSecret = "";
string      code         = "";
string      redirectUri  = "http://localhost:7777/callback";

bool Authorized() {
    return string(auth["access"]).Length > 0;
}

void ClearAuth() {
    InitAuth();
    SaveAuth();
}

void GetAuthCoro() {
    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Post;
    req.Url = authUrl + "token?grant_type=authorization_code&code=" + code + "&redirect_uri=" + redirectUri;
    req.Headers["Authorization"] = string(auth["basic"]);
    req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("Authorization error - please check Openplanet log");
        error("error getting tokens");
        warn("response: " + respCode + " " + resp);
        return;
    }

    Json::Value json = Json::Parse(resp);
    auth["access"] = json["access_token"];
    auth["refresh"] = json["refresh_token"];
    SaveAuth();
}

void InitAuth() {
    auth = Json::Object();
    auth["basic"] = "";
    auth["access"] = "";
    auth["refresh"] = "";
}

void LoadAuth() {
    print("loading auth.json...");

    if (!IO::FileExists(authFile)) {
        warn("auth.json not found!");
        InitAuth();
        return;
    }

    try {
        auth = Json::FromFile(authFile);
    } catch {
        error("error loading auth.json!");
        warn(getExceptionInfo());
        InitAuth();
        return;
    }

    if (
        !auth.HasKey("basic") ||
        !auth.HasKey("access") ||
        !auth.HasKey("refresh")
    ) {
        error("error in data from auth.json!");
        InitAuth();
    }
}

void OpenAuthPage() {
    OpenBrowserURL(
        "https://accounts.spotify.com/authorize?" +
        "client_id=" + clientId +
        "&response_type=code" +
        "&redirect_uri=" + redirectUri +
        "&scope=user-modify-playback-state user-read-playback-state"
    );
}

void RefreshCoro() {
    print("refreshing access token...");

    auto req = Net::HttpRequest();
    req.Method = Net::HttpMethod::Post;
    req.Url = authUrl + "token?grant_type=refresh_token&refresh_token=" + string(auth["refresh"]);
    req.Headers["Authorization"] = string(auth["basic"]);
    req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
    req.Start();
    while (!req.Finished()) yield();

    int respCode = req.ResponseCode();
    string resp = req.String();
    if (respCode < 200 || respCode >= 400) {
        NotifyWarn("Authorization error - please check Openplanet log");
        error("error refreshing token");
        warn("response: " + respCode + " " + resp);
        return;
    }

    auth["access"] = Json::Parse(resp)["access_token"];
    SaveAuth();
}

void SaveAuth() {
    print("saving auth.json...");

    try {
        Json::ToFile(authFile, auth);
    } catch {
        error("error saving auth.json!");
        warn(getExceptionInfo());
    }
}