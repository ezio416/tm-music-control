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

        if (UI::Button(Icons::Spotify + " Dashboard"))
            OpenBrowserURL("https://developer.spotify.com/dashboard");
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
                UI::Text("open in browser " + Icons::ExternalLinkSquare);
            UI::EndTooltip();
        }

        UI::Text(
            "    2. \\$F0FLogin\\$G with your Spotify account (a free account is fine)" +
            "\n        2b. If you weren't already logged in, click your name in the top-right and then \\$F0FDashboard\\$G" +
            "\n    3. Accept the \\$F0FTerms of Service\\$G" +
            "\n    4. Click \\$F0FCreate app\\$G" +
            "\n    5. Fill in the \\$F0FApp name\\$G and \\$F0FApp description\\$G fields (can be whatever you like)" +
            "\n    6. Click this button, then paste this into the \\$F0FRedirect URI\\$G field"
        );

        if (UI::Button(Icons::Retweet + " Redirect URI"))
            IO::SetClipboard("http://localhost:7777/callback");
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
                UI::Text("copy to clipboard " + Icons::Clipboard);
            UI::EndTooltip();
        }

        UI::Text(
            "    7. Agree to the \\$F0FTerms of Service and Design Guidelines\\$G" +
            "\n    8. Click \\$F0FSave\\$G" +
            "\n    9. In the new app page, click \\$F0FSettings\\$G in the top-right" +
            "\n    10. Copy the \\$F0FClient ID\\$G and paste it here"
        );

        clientId = UI::InputText("Client ID", clientId);

        UI::Text(
            "    11. Click this button to open the authorization page" +
            "\n        11b. After authorizing, the page will be blank. Don't close it!"
        );

        if (UI::Button(Icons::Lock + " Authorization"))
            AuthPage();
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
                UI::Text("open in browser " + Icons::ExternalLinkSquare);
            UI::EndTooltip();
        }

        UI::Text(
            "    12. Copy the full URL from the failed browser page and paste it here"
        );

        callbackUser = UI::InputText("Callback URL", callbackUser);

        UI::Text(
            "    13. Click this button to proceed to MusicControl!"
        );

        if (UI::Button(Icons::Check + " Done"))
            auth = true;

    UI::End();
}