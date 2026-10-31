# Switcher

![Switcher: Randomly view your photos and videos with you in control](Images/Switcher-Banner.png)

Switcher turns your photo and video folders into a fresh, effortless slideshow for your Mac. Pick a folder, choose how long photos stay on screen, and let Switcher shuffle through your memories, inspiration, and media automatically.

Use it on your main display for a calm changing backdrop, or bring the experience to every connected screen. With support for both photos and videos, Switcher makes every glance at your desktop feel new.

## Features

- **Photo slideshows**: shows a random photo from the folder, switching every 0.5–30 seconds (your choice).
- **Video playback**: plays every video in the folder in shuffled order, then reshuffles once all of them have played. A thin red progress bar runs along the bottom edge of each video.
- **Multiple displays**: with "Display on all displays" turned on, each connected screen runs its own slideshow in its own random order. Only the main screen plays audio, so the videos don't talk over each other.
- **Media key control**: the keyboard's play/pause, fast-forward and rewind keys control the video on every screen together.
- **Keeps the screen awake**: display sleep and the screen saver are held off while a slideshow is running.

## Usage

1. Launch Switcher and click **Choose Folder…**.
2. Set the photo interval and choose whether to use all displays.
3. Click **Run**.

Switcher only looks at the top level of the folder you choose (it doesn't search subfolders) and skips hidden files. If the folder has any photos, it shows only the photos. It plays videos only when the folder has no photos.

### Controls

| Key | Action |
| --- | --- |
| Esc | Stop the slideshow and return to the main window |
| → (Right Arrow) | Skip to the next video |
| Play/Pause | Pause or resume the videos |
| Fast-forward / Next (hold) | Play forward at 8× speed while held |
| Rewind / Previous (hold) | Play in reverse at 4× speed while held, if the video supports it |

## Requirements

- macOS 26.5 or later
- Xcode 26 or later, to build it

## Building

1. Open `Switcher.xcodeproj` in Xcode.
2. Under the Switcher target's **Signing & Capabilities**, pick your own team (or **Sign to Run Locally**). If signing complains about the bundle identifier, change it to one of your own.
3. Build and run.

## License

Switcher is released under the MIT License. See [LICENSE](LICENSE).
