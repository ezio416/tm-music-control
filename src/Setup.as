void RenderSetup() {
    if (false
        or !S_Setup
        or !disclaimerAccepted
    ) {
        return;
    }

    if (UI::Begin(title + " Setup", S_Setup, UI::WindowFlags::AlwaysAutoResize)) {
        UI::Text(
            "Welcome to MusicControl!\nSome setup is required to authorize this plugin with your Spotify account."
            "\n\nRead all of these instructions BEFORE starting (good practice with any instructions)."
            "\n\\$F0FPurple text\\$G indicates things on the Spotify website, not here."
            "\n\nYou will need to create an app in the Spotify Developer Dashboard, like so:"
            "\n    1. Click this button to open the Developer Dashboard in your browser"
        );

        if (UI::Button(Icons::Spotify + " Developer Dashboard")) {
            OpenBrowserURL("https://developer.spotify.com/dashboard");
        }
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);

        UI::Text(
            "    2. \\$F0FLogin\\$G with your Spotify account (a Premium account is mostly required)"
            "\n        2a. If you weren't already logged in, click your name in the top-right then \\$F0FDashboard\\$G"
            "\n    3. Accept the \\$F0FTerms of Service\\$G"
            "\n    4. Click \\$F0FCreate app\\$G"
            "\n    5. Fill in the \\$F0FApp name\\$G and \\$F0FApp description\\$G fields (can be whatever you like)"
            "\n    6. Click this button, then paste this into the \\$F0FRedirect URI\\$G field"
        );

        if (UI::Button(Icons::Retweet + " Redirect URI")) {
            IO::SetClipboard(redirectUri);
        }
        HoverTooltip("copy to clipboard " + Icons::Clipboard);

        UI::Text(
            "    7. Agree to the \\$F0FTerms of Service and Design Guidelines\\$G"
            "\n    8. Click \\$F0FSave\\$G"
            "\n    9. In your new app's page, click \\$F0FSettings\\$G in the top-right"
            "\n    10. Copy the \\$F0FClient ID\\$G and \\$F0FClient secret\\$G and paste them here"
            "\n        10a. You can share the ID, but don't share the secret with anyone!"
        );

        clientId = UI::InputText("Client ID", clientId);
        clientSecret = UI::InputText("Client secret", clientSecret, UI::InputTextFlags::Password);

        UI::Text(
            "    11. Click this button to open the authorization page"
            "\n        11a. Make sure you understand these permissions (you can easily revoke)"
        );

        UI::BeginDisabled(clientId.Length != 32);
        if (UI::Button(Icons::Spotify + " Authorization Page")) {
            Auth::OpenPage();
        }
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);
        UI::EndDisabled();

        UI::SameLine();
        if (UI::Button(Icons::Spotify + " Manage Apps")) {
            OpenBrowserURL("https://www.spotify.com/us/account/apps/");
        }
        HoverTooltip("open in browser " + Icons::ExternalLinkSquare);

        UI::Text(
            "    12. After clicking \\$F0FAgree\\$G:"
            "\n        12a. If the page doesn't load at all, that's good! Don't close it yet!"
            "\n        12b. If the page says, \"\\$F0FInvalid client\\$G\", you somehow copied the client ID wrong"
            "\n    13. Copy the full URL from the failed browser page and paste it here"
        );

        callbackUrl = UI::InputText("Localhost callback URL", callbackUrl);

        UI::BeginDisabled(true
            and clientId.Length != 32
            and clientSecret.Length != 32
        );
        if (UI::Button(Icons::Unlock + " Finish Authorization")) {
            auth["basic"] = "Basic " + Text::EncodeBase64(clientId + ":" + clientSecret);
            try {
                code = callbackUrl.Split(redirectUri + "?code=")[1];
                startnew(Auth::Get);
            } catch {
                Error("Error with callback URL - make sure you copy the entire thing!");
                warn("bad callback URL: " + callbackUrl);
                code = "";
            }
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(true
            and clientId.Length == 0
            and clientSecret.Length == 0
            and callbackUrl.Length == 0
        );
        if (UI::Button(Icons::Times + " Clear Fields")) {
            clientId = "";
            clientSecret = "";
            callbackUrl = "";
        }
        UI::EndDisabled();

        const bool authorized = Auth::Authorized();

        UI::SameLine();
        UI::BeginDisabled(!authorized);
        if (UI::Button(Icons::ChainBroken + " Unauthorize")) {
            Auth::Clear();
        }
        HoverTooltip("You'll need to repeat steps 9-13!");
        UI::EndDisabled();

        UI::Text("Authorized: " + (authorized ? "\\$0F0YES \\$G(you can close this window)" : "\\$F00NO"));

        if (authorized) {
            if (UI::Button(Icons::Times + " Close setup window")) {
                S_Setup = false;
            }
        }
    }

    UI::End();
}

void RenderSetupPlaylists() {
    if (!S_PlaylistSetup) {
        return;
    }

    UI::SetNextWindowSize(375, 200);

    if (UI::Begin(title + " Playlists Setup", S_PlaylistSetup, UI::WindowFlags::AlwaysAutoResize)) {
        UI::TextWrapped(
            "If you authorized this plugin in a version prior to 0.4.0 (current is " + version + "), a new permission is required to view "
            "private playlists, otherwise you can only view your public ones. This permission is also needed to check if a song is in your "
            "library. You will need to partially go through setup again to grant this permission. Don't worry, you don't have to do everything "
            "over again! Just do steps \\$F801\\$G and \\$F809-13\\$G again and the new permission should be good to go. The feature is currently limited to 50 playlists."
        );

        UI::BeginDisabled(S_Setup);
        if (UI::Button(Icons::ExternalLink + " Open Setup")) {
            S_Setup = true;
        }
        UI::EndDisabled();
    }

    UI::End();
}

[Setting hidden]
bool uriChanged = false;

void RenderURISetup() {
    if (true
        and !S_URISetup
        and uriChanged
    ) {
        return;
    }

    UI::SetNextWindowSize(550, 350);

    if (UI::Begin(title + " URI Setup (v0.6.0+)", S_URISetup, UI::WindowFlags::AlwaysAutoResize)) {
        UI::TextWrapped(
            "Spotify is making a change to how authorization works. It's a small change, but we must deal with it nonetheless. "
            "When you went through setup, you copy-pasted something called a \"Redirect URI.\" The one originally provided with "
            "the plugin will no longer be valid in late 2025, so you'll need to change it soon, and you may as well do it now "
            "to get it out of the way.\n\nIn the setup window, do the following (again, \\$F0Fpurple text \\$Gmeans on the website):"
            "\n    - step 1\n    \\$F0F- click the app you created\n    - click edit\n    - remove existing redirect URI\\$G\n    "
            "- step 6, but \\$F0Fpaste it as a new URI right under where you removed the old one\n    - click \"Add\" then \"Save\""
            "\\$G\n    - click \"Unauthorize\" at the bottom\n    - steps 10-13"
        );

        UI::BeginDisabled(S_Setup);
        if (UI::Button(Icons::ExternalLink + " Open Setup")) {
            S_Setup = true;
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(false
            or uriChanged
            or !Auth::Authorized()
        );
        if (UI::Button(Icons::Check + " I've made the change!")) {
            uriChanged = true;
            S_URISetup = false;
        }
        HoverTooltip("You can show this window again from settings");
        UI::EndDisabled();
    }

    UI::End();
}
