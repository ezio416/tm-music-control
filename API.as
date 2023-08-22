/*
c 2023-08-22
m 2023-08-22
*/

void AuthPage() {
    OpenBrowserURL(
        "https://accounts.spotify.com/authorize?" +
        "client_id=" + clientId +
        "&response_type=code" +
        "&redirect_uri=http://localhost:7777/callback" +
        "&scope=user-read-playback-state"
        // "&scope=user-modify-playback-state"
    );
}