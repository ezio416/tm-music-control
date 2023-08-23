/*
c 2023-08-22
m 2023-08-22
*/

string redirectUri = "http://localhost:7777/callback";

[Setting hidden] string access_token  = "";
[Setting hidden] string callbackUser  = "";
[Setting hidden] string clientId      = "";
[Setting hidden] string clientSecret  = "";
[Setting hidden] string code          = "";
[Setting hidden] string refresh_token = "";

void AuthPage(const string &in scope = "user-read-playback-state") {
    OpenBrowserURL(
        "https://accounts.spotify.com/authorize?" +
        "client_id=" + clientId +
        "&response_type=code" +
        "&redirect_uri=" + redirectUri +
        "&scope=" + scope
    );
}

void GetTokensCoro() {
    // auth code seems to become invalid after one use

    auto req = Net::HttpRequest();
    req.Url = "https://accounts.spotify.com/api/token?grant_type=authorization_code&code=" + code + "&redirect_uri=" + redirectUri;
    req.Headers["Authorization"] = "Basic " + Text::EncodeBase64(clientId + ":" + clientSecret);
    req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
    req.Method = Net::HttpMethod::Post;
    req.Start();
    while (!req.Finished()) yield();

    int responseCode = req.ResponseCode();
    string resp = req.String();
    Json::Value json = Json::Parse(resp);
    if (responseCode < 200 || responseCode >= 400) {
        error("error getting tokens");
        warn("resp code: " + responseCode);
        warn("resp: " + resp);
    } else {
        // print("resp: " + resp);
        access_token = json.Get("access_token");
        refresh_token = json.Get("refresh_token");
    }
}