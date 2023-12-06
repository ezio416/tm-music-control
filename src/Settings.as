/*
c 2023-08-22
m 2023-12-06
*/

[Setting category="General" name="Enabled"]
bool S_Enabled = false;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Show on-screen error messages" description="if disabled, you can still check the Openplanet log"]
bool S_Errors = true;

[Setting category="Player" name="Show album cover"]
bool S_AlbumArt = true;

[Setting category="Player" name="Album cover width" min=10 max=128]
int S_AlbumArtWidth = 128;

[Setting category="Player" name="Show song name"]
bool S_Song = true;

[Setting category="Player" name="Show artist(s)"]
bool S_Artists = true;

[Setting category="Player" name="Show album name"]
bool S_AlbumName = true;

[Setting category="Player" name="Show release date"]
bool S_AlbumRelease = true;

[Setting category="Windows" name="Show disclaimer window"]
bool S_Disclaimer = true;

[Setting category="Windows" name="Show setup window"]
bool S_Setup = false;

[Setting category="Windows" name="Show debug window"]
bool S_Debug = false;

[Setting category="Premium" name="I know I have Premium" description="Only change if the plugin made a mistake!"]
bool S_Premium = true;