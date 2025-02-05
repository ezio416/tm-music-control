// c 2023-08-22
// m 2024-10-01

[Setting category="General" name="Enabled"]
bool S_Enabled = false;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Show/hide with Playback"]
bool S_HideWithPlayback = false;

[Setting category="General" name="Show on-screen warning messages" description="If disabled, you can still check the Openplanet log."]
bool S_Warnings = false;

[Setting category="General" name="Show on-screen error messages" description="If disabled, you can still check the Openplanet log."]
bool S_Errors = true;

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

[Setting category="Player" name="Font style/size" description="Loading a font for the first time causes game to hang for a bit."]
Font S_Font = Font::DroidSans_16;

[Setting category="Player" name="Show album artwork"]
bool S_AlbumArt = true;

class SettingsAlbumArt {
    [Setting min=10 max=256]
    uint width = 128;

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


[Setting category="Windows" name="Show disclaimer window"]
bool S_Disclaimer = true;

[Setting category="Windows" name="Show setup window"]
bool S_Setup = false;

[Setting category="Windows" name="Show playlists setup window"]
bool S_PlaylistSetup = false;


[Setting category="Premium" name="I know I have Premium" description="Only change if the plugin made a mistake!"]
bool S_Premium = true;
