// c 2023-08-24
// m 2024-09-27

bool  inLibrary = false;  // to prevent flickering when checking, probably a better way to do this?
State state;

enum PlayingType {
    track,
    episode,
    ad,
    unknown
}

enum Repeat {
    off,
    context,
    track
}

class State {
    string      album;
    string      albumArtUrl64;
    string      albumRelease;
    string      artists;
    string      context;
    string      deviceId;
    bool        playing;
    Repeat      repeat;
    bool        shuffle;
    string      song;
    int         songDuration;
    string      songId;
    bool        songInLibrary = inLibrary;
    int         songProgress;
    int         songProgressPercent;
    PlayingType type;

    State() { }
    State(Json::Value@ json) {
        try {
            context = string(json.Get("context")["uri"]);
        } catch {
            return;
        }

        deviceId = string(json.Get("device")["id"]);

        Json::Value@ _item = json.Get("item");

        try {
            song = ReplaceBadQuotes(_item["name"]);
        } catch {
            return;
        }

        songId = _item["id"];

        Json::Value@ _album = _item.Get("album");
        album = ReplaceBadQuotes(_album["name"]);
        albumRelease = string(_album["release_date"]);
        Json::Value@ _albumImages = _album.Get("images");
        albumArtUrl64 = string(_albumImages[2]["url"]);

        Json::Value@ _artists = _item.Get("artists");
        for (uint i = 0; i < _artists.Length; i++) {
            if (i > 0)
                artists += ", ";
            artists += ReplaceBadQuotes(_artists[i]["name"]);
        }

        playing = bool(json["is_playing"]);

        const string _repeat = string(json["repeat_state"]);
        if      (_repeat == "off")     repeat = Repeat::off;
        else if (_repeat == "context") repeat = Repeat::context;
        else if (_repeat == "track")   repeat = Repeat::track;

        shuffle = bool(json["shuffle_state"]);
        songDuration = int(_item["duration_ms"]);
        songProgress = int(json["progress_ms"]);
        songProgressPercent = int(float(songProgress) / float(songDuration) * 100);

        const string _type = string(json["currently_playing_type"]);
        if      (_type == "track")   type = PlayingType::track;
        else if (_type == "episode") type = PlayingType::episode;
        else if (_type == "ad")      type = PlayingType::ad;
        else if (_type == "unknown") type = PlayingType::unknown;
    }
}
