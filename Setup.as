/*
c 2023-08-22
m 2023-08-22
*/

void RenderSetup() {
    UI::Begin(title + " Setup", UI::WindowFlags::AlwaysAutoResize);
        UI::Text(
            "Welcome to MusicControl!\nSome setup is required to authorize this plugin with your Spotify account." +
            "\n\nRead all of these instructions BEFORE starting (good practice with any instructions)."
            "\n\\$F0FPurple text\\$G indicates buttons/fields in the Spotify webpage, not here." +
            "\n\nYou will need to create an app in the Spotify Developer Dashboard, like so:" +
            "\n    1. Click this button to open the Developer Dashboard in your browser"
        );

        if (UI::Button(Icons::Spotify + " Developer Dashboard"))
            OpenBrowserURL("https://developer.spotify.com/dashboard");
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);

        UI::Text(
            "    2. \\$F0FLogin\\$G with your Spotify account (a free account is fine)" +
            "\n        2a. If you weren't already logged in, click your name in the top-right then \\$F0FDashboard\\$G" +
            "\n    3. Accept the \\$F0FTerms of Service\\$G" +
            "\n    4. Click \\$F0FCreate app\\$G" +
            "\n    5. Fill in the \\$F0FApp name\\$G and \\$F0FApp description\\$G fields (can be whatever you like)" +
            "\n    6. Click this button, then paste this into the \\$F0FRedirect URI\\$G field"
        );

        if (UI::Button(Icons::Retweet + " Redirect URI"))
            IO::SetClipboard(redirectUri);
        HoverTooltip("copy to clipboard " + Icons::Clipboard);

        UI::Text(
            "    7. Agree to the \\$F0FTerms of Service and Design Guidelines\\$G" +
            "\n    8. Click \\$F0FSave\\$G" +
            "\n    9. In your new app's page, click \\$F0FSettings\\$G in the top-right" +
            "\n    10. Copy the \\$F0FClient ID\\$G and \\$F0FClient secret\\$G and paste them here" +
            "\n        10a. You can share the ID, but don't share the secret with anyone!"
        );

        clientId = UI::InputText("Client ID", clientId);
        clientSecret = UI::InputText("Client secret", clientSecret);

        UI::Text(
            "    11. Click this button to open the authorization page" +
            "\n        11a. Make sure you understand these permissions (you can easily revoke)"
        );

        UI::BeginDisabled(clientId == "");
        if (UI::Button(Icons::Spotify + " Authorization"))
            AuthPage();
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);
        UI::EndDisabled();

        UI::SameLine();
        if (UI::Button(Icons::Spotify + " Manage Apps"))
            OpenBrowserURL("https://www.spotify.com/us/account/apps/");
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);

        UI::Text(
            "    12. After authorizing:" +
            "\n        12a. If the page doesn't load at all, that's good! Don't close it yet!" +
            "\n        12b. If the page says, \"\\$F0FInvalid client\\$G\", you somehow copied the client ID wrong" +
            "\n    13. Copy the full URL from the failed browser page and paste it here"
        );

        callbackUser = UI::InputText("Localhost Callback URL", callbackUser);
        UI::SameLine();
        if (UI::Button("clear code"))
            code = "";

        if (callbackUser != "" && code == "") {
            try {
                code = callbackUser.Split("http://localhost:7777/callback?code=")[1];
            } catch {
                UI::Text("bad callback URL");
            }
        }
        UI::Text("code: " + code);

        if (UI::Button("get tokens"))
            startnew(CoroutineFunc(GetTokensCoro));

        UI::Text("access_token: " + access_token);
        UI::Text("refresh_token: " + refresh_token);

    UI::End();
}

void GetTokensCoro() {
    auto req = Net::HttpRequest();
    req.Url = "https://accounts.spotify.com/api/token?grant_type=authorization_code&code=" + code + "&redirect_uri=" + redirectUri;
    req.Headers["Authorization"] = "Basic " + Text::EncodeBase64(clientId + ":" + clientSecret);
    req.Headers["Content-Type"] = "application/x-www-form-urlencoded";
    req.Method = Net::HttpMethod::Post;
    req.Start();
    while (!req.Finished()) yield();

    int responseCode = req.ResponseCode();
    string err = req.Error();
    if (responseCode < 200 || responseCode >= 400 || err.Length > 0) {
        error("error getting token");
        warn("resp code: " + responseCode);
        warn("error" + err);
    } else {
        string resp = req.String();
        print("resp: " + resp);
        auto json = Json::Parse(resp);
        access_token = json.Get("access_token");
        refresh_token = json.Get("refresh_token");
    }
}