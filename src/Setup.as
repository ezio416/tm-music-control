void RenderSetup() {
    if (UI::Begin(PLUGIN_TITLE + " Setup \\$777v" + PLUGIN_VERSION + "###window-setup-" + PLUGIN.Name, S_Setup, UI::WindowFlags::AlwaysAutoResize)) {
        if (UI::RadioButton("\\$4F4" + Icons::Spotify + " Spotify", S_API == TokenType::Spotify)) {
            S_API = TokenType::Spotify;
        }

        UI::SameLine();
        if (UI::RadioButton("\\$F44" + Icons::Youtube + " Youtube", S_API == TokenType::Youtube)) {
            S_API = TokenType::Youtube;
        }

UI::BeginTabBar("##tabbar-setup");

        if (UI::BeginTabItem("Disclaimer")) {
            switch (S_API) {
                case TokenType::Spotify:
                    UI::TextWrapped("""
Can I use a Free or Basic account?
    - Nope. This used to be possible, but due to Spotify's API changes in 2026, a Premium account is required.

Can my \$FA0username and password\$G be stolen?
    - No, we don't need those, so they are safe. However, we do store an app's client ID/secret in a simple text file, so those could be stolen.

Should I be worried about this "client ID/secret"?
    - If someone gets access to these, they may be able to control your music \$FA0without your consent.\$G
    - They may also be able to see your taste in music, which could be a good or bad thing, depending on how cringe you are.
    - At best, this will be annoying, and at worst, this will be annoying. When you go through the setup, make sure you understand what permissions you are giving to the app.

How hard is it to set up?
    - Not very hard, but there are some steps you have to do with your account in a browser. Don't worry - the authorization tab will hold your hand through it.

Why do I have to do this setup at all?
    - Due to Spotify's terms of service, they won't accept an app that allows for an easy one-click authorization. Someone in the community has already tried and been rejected, so this solution will have to do.

What can I not do with this plugin?
    - Play music within the game
    - Modify your library
    - Change playback device (yet)

If you still want to proceed into the setup, open the 'Authorization' tab at the top. Otherwise, you may want to uninstall this plugin.""");

                    break;

                case TokenType::Youtube:
                    ;
            }

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Authorization")) {
            switch (S_API) {
                case TokenType::Spotify:
                    if (spotify is null) {
                        @spotify = SpotifyToken();
                    }

                    UI::Text(
                        "Some setup is required to authorize this plugin with your Spotify account."
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
                        "    2. \\$F0FLogin\\$G with your Spotify account (a Premium account is required)"
                        "\n        2a. If you weren't already logged in, click your name in the top-right then \\$F0FDashboard\\$G"
                        "\n    3. Accept the \\$F0FTerms of Service\\$G"
                        "\n    4. Click \\$F0FCreate app\\$G (you can only have one and may need to reuse one from another project)"
                        "\n    5. Fill in the \\$F0FApp name\\$G and \\$F0FApp description\\$G fields (can be whatever you like)"
                        "\n    6. Click this button, then paste this into the \\$F0FRedirect URI\\$G field"
                    );

                    if (UI::Button(Icons::Retweet + " Redirect URI")) {
                        spotify.CopyRedirect();
                    }
                    HoverTooltip("copy to clipboard " + Icons::Clipboard);

                    UI::Text(
                        "    7. Agree to the \\$F0FTerms of Service and Design Guidelines\\$G"
                        "\n    8. Click \\$F0FSave\\$G"
                        "\n    9. In your new app's page, click \\$F0FSettings\\$G in the top-right"
                        "\n    10. Copy the \\$F0FClient ID\\$G and \\$F0FClient secret\\$G and paste them here"
                        "\n        10a. You can share the ID, but don't share the secret with anyone!"
                    );

                    spotify.clientId     = UI::InputText("Client ID", spotify.clientId);
                    spotify.clientSecret = UI::InputText("Client secret", spotify.clientSecret, UI::InputTextFlags::Password);

                    UI::Text(
                        "    11. Click this button to open the authorization page"
                        "\n        11a. Make sure you understand these permissions (you can easily revoke)"
                    );

                    UI::BeginDisabled(spotify.clientId.Length != 32);
                    if (UI::Button(Icons::Spotify + " Authorization Page")) {
                        spotify.OpenAuthPage();
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

                    spotify.callbackUrl = UI::InputText("Localhost callback URL", spotify.callbackUrl);

                    UI::BeginDisabled(true
                        and spotify.clientId.Length != 32
                        and spotify.clientSecret.Length != 32
                    );
                    if (UI::Button(Icons::Unlock + " Finish Authorization")) {
                        spotify.basic = "Basic " + Text::EncodeBase64(spotify.clientId + ":" + spotify.clientSecret);
                        try {
                            spotify.SetCode();
                            spotify.Get();
                        } catch {
                            Error("Error with callback URL - make sure you copy the entire thing!");
                            warn("bad callback URL: " + spotify.callbackUrl);
                            spotify.code = "";
                        }
                    }
                    UI::EndDisabled();

                    UI::SameLine();
                    UI::BeginDisabled(true
                        and spotify.clientId.Length == 0
                        and spotify.clientSecret.Length == 0
                        and spotify.callbackUrl.Length == 0
                    );
                    if (UI::Button(Icons::Times + " Clear Fields")) {
                        spotify.clientId = "";
                        spotify.clientSecret = "";
                        spotify.callbackUrl = "";
                    }
                    UI::EndDisabled();

                    UI::SameLine();
                    UI::BeginDisabled(!spotify.authorized);
                    if (UI::Button(Icons::ChainBroken + " Unauthorize")) {
                        spotify.Init();
                    }
                    HoverTooltip("You'll need to repeat steps 9-13!");
                    UI::EndDisabled();

                    UI::Text("Authorized: " + (spotify.authorized ? "\\$0F0YES \\$G(you can close this window)" : "\\$F00NO"));

                    break;

                case TokenType::Youtube:
                    // if (youtube is null) {
                    //     @youtube = YoutubeToken();
                    // }

                    // TODO yt auth
            }

            UI::EndTabItem();
        }

        if (true
            and S_API == TokenType::Spotify
            and UI::BeginTabItem("Private Playlists (0.4.0)")
        ) {
            UI::TextWrapped(
                "If you authorized this plugin in a version prior to 0.4.0, a new permission is required to view "
                "private playlists, otherwise you can only view your public ones. This permission is also needed to "
                "check if a song is in your library. You will need to partially go through setup again to grant this "
                "permission. Don't worry, you don't have to do everything over again! Just do steps \\$F801\\$G and "
                "\\$F809-13\\$G in the 'Authorization' tab again and the new permission should be good to go. The "
                "feature is currently limited to 50 playlists."
            );

            UI::EndTabItem();
        }

        if (true
            and S_API == TokenType::Spotify
            and UI::BeginTabItem("New URI (0.6.1)")
        ) {
            UI::TextWrapped(
                "Spotify is making a change to how authorization works. It's a small change, but we must deal with it "
                "nonetheless. When you went through setup, you copy-pasted something called a \"Redirect URI.\" The one"
                " originally provided with the plugin will no longer be valid in late 2025, so you'll need to change it"
                " soon, and you may as well do it now to get it out of the way.\n\nIn the 'Authorization' tab up top, "
                "do the following (again, \\$F0Fpurple text \\$Gmeans on the website):\n    - step 1\n    \\$F0F- click"
                " the app you created\n    - click edit\n    - remove existing redirect URI\\$G\n    - step 6, but "
                "\\$F0Fpaste it as a new URI right under where you removed the old one\n    - click \"Add\" then "
                "\"Save\"\\$G\n    - click \"Unauthorize\" at the bottom\n    - steps 10-13"
            );

            UI::EndTabItem();
        }

        UI::EndTabBar();
    }

    UI::End();
}
