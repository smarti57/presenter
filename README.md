# Presenter

A lightweight PDF slide deck presenter for macOS and iOS. Open a PDF, browse slides with thumbnails, pick a transition style, and present fullscreen.

## Features

- **Review mode** -- thumbnail sidebar, slide preview, transition picker, and monitor selector
- **Fullscreen presentation** -- keyboard, mouse, and presenter remote navigation
- **Transition effects** -- fade, push, reveal, move-in, cube, and flip (via Core Animation)
- **Multi-monitor** -- present on an external display while keeping review mode on the primary screen
- **iOS support** -- SwiftUI companion app with swipe/tap navigation and AirPlay output

## Requirements

| Platform | Minimum version |
|----------|----------------|
| macOS    | 13.0 Ventura   |
| iOS      | 17.0           |

Swift 5.9+ and the Swift Package Manager are required. No Xcode project is needed for the macOS build.

## Building

### macOS

```bash
swift build
```

To produce the `.app` bundle for Finder:

```bash
swift build
cp .build/debug/Presenter Presenter.app/Contents/MacOS/Presenter
```

Then double-click `Presenter.app` or run from the command line:

```bash
swift run Presenter
# or open a PDF directly:
swift run Presenter /path/to/slides.pdf
```

### iOS

Open the project in Xcode, select the **PresenterMobile** scheme, and run on an iOS Simulator or device.

```bash
open Package.swift  # opens in Xcode
```

## Usage

### macOS

1. Launch the app and drag a PDF onto the window, or use **File > Open**.
2. Browse slides in the thumbnail sidebar; the preview updates as you select.
3. Choose a transition style and target monitor from the toolbar.
4. Click **Present** (or press Return) to enter fullscreen.

**Presentation controls:**

| Key / Action       | Effect               |
|-------------------|----------------------|
| Right / Down / Space / Return / Click | Next slide |
| Left / Up / Page Up | Previous slide      |
| Page Down          | Next slide           |
| B                  | Blank / unblank screen |
| T                  | Cycle transition style |
| Escape             | End presentation     |

### iOS

1. Tap **Open PDF** and select a file.
2. Browse thumbnails (sidebar on iPad, bottom strip on iPhone).
3. Pick a transition and tap **Present** for fullscreen.
4. Swipe left/right to navigate, tap to advance, swipe down to exit.

## Project Structure

```
Sources/
  Presenter/            # macOS target (AppKit)
    main.swift          # App bootstrap
    AppDelegate.swift   # Window and lifecycle management
    ReviewModeView.swift      # Thumbnail sidebar + preview
    PresentationController.swift  # Fullscreen presentation engine
    SlideView.swift     # CALayer-based slide display
    PDFImageCache.swift # Threadsafe PDF page renderer
    TransitionStyle.swift     # Core Animation transitions
    ...
  PresenterMobile/      # iOS target (SwiftUI)
    PresenterApp.swift  # @main entry point
    PresentationState.swift   # @Observable shared state
    ReviewView.swift    # iPad sidebar / iPhone strip layouts
    SlidePresenterView.swift  # UIViewRepresentable + CATransition
    ExternalDisplayManager.swift  # AirPlay / HDMI output
    ...
Presenter.app/          # macOS app bundle (Info.plist, icon, binary)
Package.swift
```

## License

MIT
