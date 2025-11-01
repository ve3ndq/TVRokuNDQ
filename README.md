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
4. Open your browser and go to `http://[ROKU_IP]:8060`
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

## Credits

Originally forked from [sudo97](https://github.com/sudo97)'s SimpleIPTVRoku project.

## License

Open source - feel free to modify and distribute.



