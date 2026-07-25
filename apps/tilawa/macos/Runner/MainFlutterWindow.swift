import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    RegisterGeneratedPlugins(registry: flutterViewController)

    // Prevent macOS from restoring a prior tiny frame over our desktop size.
    isRestorable = false
    minSize = NSSize(width: 515, height: 700)

    super.awakeFromNib()

    // xib default is 800×600; prior launches may also restore a narrow frame.
    // Apply after the run loop turn so restoration cannot override us.
    // Full visible-screen frame → dual-page columns wide enough for Ayah-scale
    // line images (lineHeight = pageWidth × 174/1080).
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      let screenFrame =
          self.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
      guard let screenFrame else { return }
      self.setFrame(screenFrame, display: true)
    }
  }
}
