// c 2023-08-24
// m 2024-01-19

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
    Device(Json::Value@ json) {
        id             = json["id"];
        name           = json["name"];
        type           = json["type"];
        active         = json["is_active"];
        privateSession = json["is_private_session"];
        restricted     = json["is_restricted"];
        supportsVolume = json["supports_volume"];
        volume         = json["volume_percent"];
    }
}

void SetDevices(Json::Value@ json) {
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