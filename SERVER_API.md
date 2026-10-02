# HackDavis Air Quality Server

This README is for the app/server team so everyone knows what JSON commands the server accepts and what the server does with them.

## Server Connection

```text
Host: 192.7846.9724
Port: 6967
Protocol: Raw TCP
Data Format: JSON
```

This is not an HTTP server.  
The app should open a TCP connection, send one JSON object, read the JSON response, then close the connection.

---

# Possible Commands

The server currently supports these commands:

```text
upload
get_all
clear_all
```

Every command must include a `"type"` field.

---

# 1. `upload`

Sends one air quality reading from one device to the server.

## Request JSON

```json
{
  "type": "upload",
  "device_id": "AA:BB:CC:DD:EE:FF",
  "latitude": 38.5449,
  "longitude": -121.7405,
  "air_quality": 42.5
}
```

## Required Fields

```text
type          must be "upload"
device_id     MAC address of the air quality device
latitude      latitude from the phone
longitude     longitude from the phone
air_quality   one clean air quality value
```

## Server Logic

When the server receives `upload`:

```text
1. It checks that the JSON is valid.
2. It checks that device_id, latitude, longitude, and air_quality exist.
3. It creates a timestamp using the server's current UTC time.
4. It stores the reading in memory.
5. The device_id is used as the key.
6. If the same device_id uploads again, the old reading is replaced.
7. The server sends back status ok.
```

## Success Response

```json
{
  "status": "ok"
}
```

## Error Response Example

```json
{
  "status": "error",
  "message": "Missing device_id"
}
```

---

# 2. `get_all`

Requests all current device readings from the server.

## Request JSON

```json
{
  "type": "get_all"
}
```

## Server Logic

When the server receives `get_all`:

```text
1. It checks that the JSON is valid.
2. It looks through all currently stored device readings.
3. It creates a JSON array called devices.
4. Each device entry includes device_id, latitude, longitude, air_quality, and timestamp.
5. It sends the full device list back to the app.
```

This is the command the app should use when it needs data for the map.

## Success Response

```json
{
  "status": "ok",
  "devices": [
    {
      "device_id": "AA:BB:CC:DD:EE:FF",
      "latitude": 38.5449,
      "longitude": -121.7405,
      "air_quality": 42.5,
      "timestamp": "2026-05-09T18:30:00Z"
    }
  ]
}
```

If no readings are stored:

```json
{
  "status": "ok",
  "devices": []
}
```

---

# 3. `clear_all`

Deletes all currently stored readings.

This is mainly for testing.

## Request JSON

```json
{
  "type": "clear_all"
}
```

## Server Logic

When the server receives `clear_all`:

```text
1. It checks that the JSON is valid.
2. It counts how many device readings are currently stored.
3. It deletes all readings from memory.
4. It sends back how many entries were deleted.
```

## Success Response

```json
{
  "status": "ok",
  "message": "All readings cleared",
  "deleted_count": 2
}
```

---

# General Server Logic

The server stores readings in memory using this idea:

```text
device_id -> latest reading for that device
```

Example:

```text
AA:BB:CC:DD:EE:FF -> latitude, longitude, air_quality, timestamp
11:22:33:44:55:66 -> latitude, longitude, air_quality, timestamp
```

Important behavior:

```text
Only the latest reading for each device is stored.
If the same device uploads again, its previous reading is overwritten.
If the server stops or restarts, all readings are lost.
The server does not currently use a database.
```

---

# Device ID Format

The `device_id` should be the MAC address of the air quality device.

Use this format:

```text
AA:BB:CC:DD:EE:FF
```

Try to keep the format consistent. These could be treated differently if the app sends them differently:

```text
AA:BB:CC:DD:EE:FF
aa:bb:cc:dd:ee:ff
AA-BB-CC-DD-EE-FF
AABBCCDDEEFF
```

---

# Example Testing Commands

## Upload a reading

```bash
echo '{"type":"upload","device_id":"AA:BB:CC:DD:EE:FF","latitude":38.5449,"longitude":-121.7405,"air_quality":42.5}' | nc -w 5 75.33.176.134 2527
```

Expected:

```json
{"status":"ok"}
```

## Get all readings

```bash
echo '{"type":"get_all"}' | nc -w 5 75.33.176.134 2527
```

Expected:

```json
{"devices":[{"air_quality":42.5,"device_id":"AA:BB:CC:DD:EE:FF","latitude":38.5449,"longitude":-121.7405,"timestamp":"..."}],"status":"ok"}
```

## Clear all readings

```bash
echo '{"type":"clear_all"}' | nc -w 5 75.33.176.134 2527
```

Expected:

```json
{"deleted_count":1,"message":"All readings cleared","status":"ok"}
```
