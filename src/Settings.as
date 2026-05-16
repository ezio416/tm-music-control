[Setting category="General" name="Show player"]
bool S_Enabled = false;

[Setting category="General" name="Show setup window"]
bool S_Setup = true;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

enum UpdateFreq {
    Slowest = 5000,
    Slower  = 3000,
    Slow    = 1500,
    Normal  = 1000,
    Fast    = 750,
    Faster  = 500
}

[Setting category="General" name="Update frequency" description="Only change this if you're getting rate-limit errors."]
UpdateFreq S_UpdateFreq = UpdateFreq::Normal;

[Setting category="General" name="API" hidden]
TokenType S_API = TokenType::Spotify;


[Setting category="Player" name="Hide when inactive" description="When music is paused for a certain time"]
bool S_HideInactive = false;

[Setting category="Player" name="Inactivity time (seconds)" if="S_HideInactive"]
uint S_Inactivity = 30;

[Setting category="Player" name="Opacity" min=0.05f max=1.0f]
float S_Opacity = 1.0f;

[Setting category="Player" name="Font" hidden]
Font S_Font = Font::DroidSans;

[Setting category="Player" name="Font (system)" hidden]
string S_SystemFont;

[Setting category="Player" name="Font size" min=8 max=72 hidden]
int S_FontSize = 16;

[Setting category="Player" name="Show album artwork"]
bool S_AlbumArt = true;

enum AlbumArtRes {
    x64,
    x300,
    x640
}

class SettingsAlbumArt {
    [Setting min=10 max=256]
    uint width = 128;

    [Setting]
    AlbumArtRes resolution = AlbumArtRes::x64;

    [Setting name="heart for liked song" description="Because of stricter API limits on this endpoint, this is checked less frequently. I couldn't find a good place to put this in every circumstance, so if you have a suggestion, please make an issue on the GitHub!"]
    bool heart = false;
}

[Setting category="Player" name="Album artwork" if="S_AlbumArt"]
SettingsAlbumArt S_AlbumArt_Cond;

[Setting category="Player" name="Show song name"]
bool S_Song = true;

[Setting category="Player" name="Show artist(s)"]
bool S_Artists = true;

[Setting category="Player" name="Show album name"]
bool S_AlbumName = true;

[Setting category="Player" name="Show release date"]
bool S_AlbumRelease = true;

[Setting category="Player" name="Truncate date if January 1" description="Many albums claim to be released on January 1 which is generally not true"]
bool S_AlbumReleaseTruncate = true;

[Setting category="Player" name="Limit text length" min=-1 max=200 description="Some details, usually album names, can have really long names. -1 means no limit. This setting is a temporary solution until scrolling text can be figured out."]
int S_MaxTextLength = -1;

[Setting category="Player" name="Show buttons"]
bool S_Buttons = true;

class SettingsButtons {
    [Setting name="stretch to fill width"]
    bool stretch = true;

    [Setting]
    bool tooltips = true;

    [Setting step=0.1f]
    float height = 1.2f;
}

[Setting category="Player" name="Buttons" if="S_Buttons"]
SettingsButtons S_Buttons_Cond;

[Setting category="Player" name="Show progress bar"]
bool S_Progress = true;

class SettingsProgress {
    [Setting name="scroll to seek"]
    bool scroll = true;

    [Setting name="scroll step percentage"]
    uint step = 10;
}

[Setting category="Player" name="Progress" if="S_Progress"]
SettingsProgress S_Progress_Cond;

[Setting category="Player" name="Show volume bar" description="The same change (i.e. 5%) at a high volume has a greater effect than at low volume. This should be solved in the future."]
bool S_Volume = false;

class SettingsVolume {
    [Setting name="show when unsupported" description="If a device does not support volume, it would be useless to show it."]
    bool unsupported = false;

    [Setting name="scroll to adjust"]
    bool scroll = true;

    [Setting name="scroll step percentage"]
    uint step = 10;

    [Setting name="Easter egg"]
    bool egg = false;
}

[Setting category="Player" name="Volume" if="S_Volume"]
SettingsVolume S_Volume_Cond;

[Setting category="Player" name="Show playlists menu" description="Because of stricter API limits on this endpoint, this is checked less frequently."]
bool S_Playlists = false;


[Setting category="Premium" name="I know I have Premium" description="Only change if the plugin made a mistake!"]
bool S_Premium = true;
