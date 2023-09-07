/*
c 2023-08-24
m 2023-09-07
*/

Device@  activeDevice;
Device[] devices;
Device@  lastDevice;

[Setting hidden]
string lastDeviceId;

class Device {
    string id;
    string name;
    string type;
    bool   active;
    bool   privateSession;
    bool   restricted;
    bool   supportsVolume;
    int    volume;

    Device() { }
    Device(Json::Value json) {
        id             = string(json["id"]);
        name           = string(json["name"]);
        type           = string(json["type"]);
        active         = bool(json["is_active"]);
        privateSession = bool(json["is_private_session"]);
        restricted     = bool(json["is_restricted"]);
        supportsVolume = bool(json["supports_volume"]);
        volume         = int(json["volume_percent"]);
    }
}

void SetDevices(Json::Value json) {
    @activeDevice = null;
    devices.RemoveRange(0, devices.Length);

    for (uint i = 0; i < json.Length; i++) {
        Device dev = Device(json[i]);
        devices.InsertLast(dev);
        if (dev.active)
            @activeDevice = devices[devices.Length - 1];
    }

    if (activeDevice !is null) {
        @lastDevice = @activeDevice;

        if (lastDeviceId != lastDevice.id) {
            lastDeviceId = lastDevice.id;
            Meta::SaveSettings();
        }
    }
}