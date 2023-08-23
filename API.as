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