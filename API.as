/*
c 2023-08-22
m 2023-08-22
*/

string callbackUri  = "http://localhost:7777/callback";
string callbackUser = "";
string clientId     = "";
string clientSecret = "";
string code         = "";
string token        = "";

void AuthPage(const string &in scope = "user-read-playback-state") {
    OpenBrowserURL(
        "https://accounts.spotify.com/authorize?" +
        "client_id=" + clientId +
        "&response_type=code" +
        "&redirect_uri=" + callbackUri +
        "&scope=" + scope
    );
}