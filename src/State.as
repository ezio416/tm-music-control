int64 lastActive;
bool  liked = false;  // to prevent flickering when checking, probably a better way to do this?
State state;

enum PlayingType {
    track,
    episode,
    ad,
    unknown
}

enum ReleasePrecision {
    day,
    month,
    year
}

enum Repeat {
    off,
    context,
    track
}

class State {
    string           album;
    string           albumArtUrl64;
    string           albumArtUrl300;
    string           albumArtUrl640;
    string           albumArtUrlSelected;
    string           albumRelease;
    ReleasePrecision albumReleasePrecision;
    string           artists;
    string           context;
    string           deviceId;
    uint64           lastUpdate;
    bool             playing;
    Repeat           repeat;
    bool             shuffle;
    bool             smartShuffle;
    string           song;
    int              songDuration;
    string           songId;
    bool             songLiked;
    int              songProgress;
    int              songProgressPredicted;
    int              songProgressPercent;
    int              songProgressPercentPredicted;
    PlayingType      type;

    State() {
        Clear();
        startnew(CoroutineFunc(PredictProgressAsync));
    }

    void Clear() {
        album                        = "";
        albumArtUrl64                = "";
        albumArtUrl300               = "";
        albumArtUrl640               = "";
        albumArtUrlSelected          = "";
        albumRelease                 = "";
        albumReleasePrecision        = ReleasePrecision::day;
        artists                      = "";
        context                      = "";
        deviceId                     = "";
        lastUpdate                   = 0;
        playing                      = false;
        repeat                       = Repeat::off;
        shuffle                      = false;
        smartShuffle                 = false;
        song                         = "";
        songDuration                 = 0;
        songId                       = "";
        songLiked                    = liked;
        songProgress                 = 0;
        songProgressPredicted        = 0;
        songProgressPercent          = 0;
        songProgressPercentPredicted = 0;
        type                         = PlayingType::track;
    }

    void Update(Json::Value@ json = null) {
        lastUpdate = Time::Now;

        if (json is null) {
            return;
        }

        try {
            context = string(json.Get("context")["uri"]);
        } catch {
            context = "";
            return;
        }

        deviceId = string(json.Get("device")["id"]);

        Json::Value@ _item = json.Get("item");

        try {
            song = ReplaceBadQuotes(_item["name"]);
        } catch {
            song = "";
            return;
        }

        songId = _item["id"];

        Json::Value@ _album = _item.Get("album");
        album = ReplaceBadQuotes(_album["name"]);
        albumRelease = string(_album["release_date"]);

        const string _relPrec = string(_album["release_date_precision"]);
        if      (_relPrec == "day")   albumReleasePrecision = ReleasePrecision::day;
        else if (_relPrec == "month") albumReleasePrecision = ReleasePrecision::month;
        else if (_relPrec == "year")  albumReleasePrecision = ReleasePrecision::year;

        Json::Value@ _albumImages = _album.Get("images");
        albumArtUrl640 = string(_albumImages[0]["url"]);
        albumArtUrl300 = string(_albumImages[1]["url"]);
        albumArtUrl64  = string(_albumImages[2]["url"]);
        switch (S_AlbumArt_Cond.resolution) {
            case AlbumArtRes::x64:  albumArtUrlSelected = albumArtUrl64;  break;
            case AlbumArtRes::x300: albumArtUrlSelected = albumArtUrl300; break;
            case AlbumArtRes::x640: albumArtUrlSelected = albumArtUrl640; break;
        }

        artists = "";
        Json::Value@ _artists = _item.Get("artists");
        for (uint i = 0; i < _artists.Length; i++) {
            if (i > 0) {
                artists += ", ";
            }
            artists += ReplaceBadQuotes(_artists[i]["name"]);
        }

        playing = bool(json["is_playing"]);
        if (playing) {
            lastActive = Time::Stamp;
        }

        const string _repeat = string(json["repeat_state"]);
        if      (_repeat == "off")     repeat = Repeat::off;
        else if (_repeat == "context") repeat = Repeat::context;
        else if (_repeat == "track")   repeat = Repeat::track;

        shuffle = bool(json["shuffle_state"]);
        smartShuffle = bool(json["smart_shuffle"]);
        songDuration = int(_item["duration_ms"]);
        songProgress = int(json["progress_ms"]);
        songProgressPercent = int(float(songProgress) / float(songDuration) * 100.0f);

        const string _type = string(json["currently_playing_type"]);
        if      (_type == "track")   type = PlayingType::track;
        else if (_type == "episode") type = PlayingType::episode;
        else if (_type == "ad")      type = PlayingType::ad;
        else if (_type == "unknown") type = PlayingType::unknown;
    }

    void PredictProgressAsync() {
        while (true) {
            yield();

            songProgressPredicted = songProgress;
            songProgressPercentPredicted = songProgressPercent;

            if (playing) {
                songProgressPredicted = Math::Min(
                    songDuration,
                    songProgress + Time::Now - lastUpdate
                );

                songDuration = Math::Max(songDuration, 1);
                songProgressPercentPredicted = int(float(songProgressPredicted) / float(songDuration) * 100.0f);
            }
        }
    }
}
