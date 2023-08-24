/*
c 2023-08-24
m 2023-08-24
*/

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
    string      albumRelease;
    string[]    artists;
    string      context;
    string      deviceId;
    bool        playing;
    Repeat      repeat;
    bool        shuffle;
    string      song;
    int         songDuration;
    int         songProgress;
    PlayingType type;

    State() { }
    State(Json::Value json) {
        context = string(json.Get("context")["uri"]);
        deviceId = string(json.Get("device")["id"]);

        Json::Value _item = json.Get("item");
            song = string(_item["name"]);
            songDuration = int(_item["duration_ms"]);
            Json::Value _album = _item.Get("album");
                album = string(_album["name"]);
                albumRelease = string(_album["release_date"]);

        playing = bool(json["is_playing"]);

        string _repeat = string(json["repeat_state"]);
            if      (_repeat == "off")     repeat = Repeat::off;
            else if (_repeat == "context") repeat = Repeat::context;
            else if (_repeat == "track")   repeat = Repeat::track;

        shuffle = bool(json["shuffle_state"]);
        songProgress = int(json["progress_ms"]);

        string _type = string(json["currently_playing_type"]);
            if      (_type == "track")   type = PlayingType::track;
            else if (_type == "episode") type = PlayingType::episode;
            else if (_type == "ad")      type = PlayingType::ad;
            else if (_type == "unknown") type = PlayingType::unknown;
    }
}