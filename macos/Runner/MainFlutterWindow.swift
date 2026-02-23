import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    // https://github.com/flutter/flutter/issues/142916
    // Add following two lines
    self.backgroundColor = NSColor.clear
    flutterViewController.backgroundColor = NSColor.clear
    // 手动指定下
    // let windowFrame = self.frame
    let windowFrame = NSRect(x: 0.0, y: 0.0, width: 1200.0, height: 720.0)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
