/*
c 2023-08-22
m 2023-11-28
*/

[Setting category="General" name="Enabled"]
bool S_Enabled = false;

[Setting category="General" name="Show/hide with game UI"]
bool S_HideWithGame = true;

[Setting category="General" name="Show/hide with Openplanet UI"]
bool S_HideWithOP = false;

[Setting category="General" name="Show disclaimer window"]
bool S_Disclaimer = true;

[Setting category="General" name="Show setup window"]
bool S_Setup = false;

[Setting category="General" name="Show debug window"]
bool S_Debug = false;

[Setting category="General" name="Scroll text when too long"]
bool S_ScrollText = true;
bool _S_ScrollText;
bool _S_ScrollTextSet = false;

[Setting category="General" name="Text scrolling speed" min=1 max=100]
int S_ScrollSpeed = 75;

[Setting category="General" name="Show album cover"]
bool S_Album = true;

[Setting category="General" name="Album cover width" min=10 max=128]
int S_AlbumArtWidth = 64;

[Setting category="General" name="Show song name"]
bool S_Song = true;

[Setting category="General" name="Show artist(s)"]
bool S_Artists = true;

[Setting category="General" name="Show album name"]
bool S_AlbumName = true;

[Setting category="General" name="Show release date"]
bool S_AlbumRelease = true;