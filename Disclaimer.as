/*
c 2023-11-23
m 2023-11-23
*/

[Setting hidden]
bool disclaimerAccepted = false;

int64 disclaimerOpened = 0;

void RenderDisclaimer() {
    if (!S_Disclaimer) {
        disclaimerOpened = 0;
        return;
    }

    if (disclaimerOpened == 0)
        disclaimerOpened = Time::Stamp;

    UI::Begin(title + " Disclaimer", UI::WindowFlags::AlwaysAutoResize);
        UI::Text("\\$F50DISCLAIMER:\n");
        UI::NewLine();
        UI::TextWrapped("""
Can my Spotify \$FA0username and password\$G be stolen?
    - No, we don't need those, so they are safe. However, we do store an app's client ID/secret in a simple text file, so those could be stolen.

Should I be worried about this "client ID/secret"?
    - If someone gets access to these, they may be able to control your music \$FA0without your consent.\$G
    - At best, this will be annoying, and at worst, this will be annoying. When you go through the setup, make sure you understand what permissions you are giving to the app.

How hard is it to set up?
    - Not very hard, but there are some steps you have to do with your account in a browser. Don't worry - the setup window will hold your hand through it.

What can I not do with this plugin?
    - Modify your library
    - Seek within a song (yet)
    - Change playback device (yet)

If you still want to proceed into the setup, click the button below. Otherwise, you may want to uninstall this plugin. (Button will be active after 15 seconds)
        """);

        UI::BeginDisabled(Time::Stamp - disclaimerOpened < 15);
        if (UI::Button(Icons::Check + " I understand the risks and limitations above")) {
            disclaimerAccepted = true;
            S_Disclaimer = false;
        }
        UI::EndDisabled();
    UI::End();
}