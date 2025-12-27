# SimpleIPTVRoku

A simple Roku channel application for playing IPTV streams using local M3U playlists.

## Features

- 📺 Play IPTV streams directly from a local M3U playlist file
- 🎬 Full-screen video playback with intuitive controls
- 📋 Channel list organized by groups/categories
- 🎯 Support for multiple video formats: HLS, MP4, MKV, AVI, and more
- 🔄 No external URL configuration needed - uses bundled playlist

## Installation

### Enable Developer Mode on Roku

1. Press **Home** button 3 times, **Up** 2 times, **Right**, **Left**, **Right**, **Left**, **Right**
2. Enable developer mode and set a password
3. Note your Roku's IP address

For detailed instructions, see: [How to Enable Developer Mode on Roku](https://www.howtogeek.com/290787/how-to-enable-developer-mode-and-sideload-roku-apps/)

### Deploy the Channel

1. Create your `1.m3u` playlist file with your IPTV channels
2. Place the `1.m3u` file in the project root directory
3. Create a deployment package:
   ```bash
   zip -r SimpleIPTVRoku.zip manifest source/ components/ images/ 1.m3u
   ```
4. Open your browser and go to `http://[ROKU_IP]:8060` (or port 80)
5. Login with your developer credentials
6. Upload the `SimpleIPTVRoku.zip` file

## Usage

- **Navigate**: Use arrow keys to browse the channel list
- **Select Channel**: Press **OK** to play a channel in fullscreen
- **Return to List**: Press **Back** or **Left** arrow
- **Options**: Press **Options** button to manually enter a playlist URL (optional)

## M3U Playlist Format

The app reads from a local `1.m3u` file. Format example:

```m3u
#EXTM3U
#EXTINF:-1 tvg-id="Channel1" tvg-name="Channel Name" tvg-logo="logo_url" group-title="Category",Channel Name
http://stream-url.com/stream.m3u8
```

## Supported Formats

HLS, MP4, MKV, MP3, AVI, M4V, TS, MPEG-4, FLV, VOB, OGG, OGV, WebM, MOV, WMV, ASF, AMV, MPG, MP2, MPEG, MPE, MPV, MPEG2

## Home Assistant Integration

The app supports deep linking, allowing Home Assistant to launch and play specific channels automatically.

### Setup

1. **Add Roku to Home Assistant** - The Roku integration should auto-discover your device, or add it manually with your Roku's IP address.

2. **Find your Dev App ID** - After sideloading the app, it will have an ID like `dev` or a custom ID if you specified one in the manifest.

3. **Create Home Assistant Scripts** - Add these to your `configuration.yaml`:

```yaml
script:
  play_roku_channel:
    alias: "Play Roku IPTV Channel"
    fields:
      channel_number:
        description: "Channel index (0-based)"
        example: "0"
    sequence:
      - service: roku.launch
        data:
          entity_id: media_player.roku
          content_id: "{{ channel_number }}"
          content_type: "channel"
          media_type: "dev"  # or your custom app ID
  
  # Quick shortcuts for specific channels
  play_sportsnet_east:
    alias: "Play Sportsnet East"
    sequence:
      - service: script.play_roku_channel
        data:
          channel_number: "0"
  
  play_sportsnet_one:
    alias: "Play Sportsnet One"
    sequence:
      - service: script.play_roku_channel
        data:
          channel_number: "1"
```

### Usage Examples

**From Home Assistant UI:**
- Call the `play_roku_channel` script with a channel number

**From Automations:**
```yaml
automation:
  - alias: "Play sports at game time"
    trigger:
      - platform: time
        at: "19:00:00"
    action:
      - service: script.play_sportsnet_east
```

**Via REST API:**
```bash
curl -X POST http://homeassistant.local:8123/api/services/script/play_roku_channel \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"channel_number": "0"}'
```

### Channel Index Reference

Channels are indexed starting from 0 in the order they appear in your M3U file:
- 0: First channel
- 1: Second channel
- 2: Third channel
- etc.



## License

Open source - feel free to modify and distribute.



