// c 2023-08-22
// m 2024-09-27

[Setting category="General" name="Enabled"]
bool S_Enabled = false;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Show on-screen error messages" description="If disabled, you can still check the Openplanet log"]
bool S_Errors = true;


[Setting category="Player" name="Show album cover"]
bool S_AlbumArt = true;

[Setting category="Player" name="Album cover width" min=10 max=128]
int S_AlbumArtWidth = 128;

[Setting category="Player" name="Show if song is in library" description="Only shows when album art is also shown. I couldn't find a good place to put this in every circumstance. If you have a suggestion, please make an issue on the GitHub!"]
bool S_InLibrary = false;

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

[Setting category="Player" name="Show button controls"]
bool S_ButtonControls = true;

[Setting category="Player" name="Stretch buttons to fill width"]
bool S_StretchButtons = true;

[Setting category="Player" name="Show scrubber bar"]
bool S_Scrubber = true;

[Setting category="Player" name="Show volume bar" description="The same change (i.e. 5%) at a high volume has a greater effect than at low volume. This should be solved in the future."]
bool S_Volume = false;

[Setting category="Player" name="Show playlists menu" description="Because of stricter API limits on this endpoint, playlists are checked less frequently"]
bool S_Playlists = false;


[Setting category="Windows" name="Show disclaimer window"]
bool S_Disclaimer = true;

[Setting category="Windows" name="Show setup window"]
bool S_Setup = false;

[Setting category="Windows" name="Show playlists setup window"]
bool S_PlaylistSetup = false;


[Setting category="Premium" name="I know I have Premium" description="Only change if the plugin made a mistake!"]
bool S_Premium = true;
