// ccn-notify — macOS notification with click-to-focus for Claude Code.
//
// Posts a banner via UNUserNotificationCenter (UserNotifications framework).
// When the user clicks, runs an optional focus script to bring the right
// terminal/tmux pane to the foreground.
//
// Must be invoked from inside the "Claude Code Notification.app" bundle so
// that UNUserNotificationCenter can resolve a bundle identity. Running the
// bare binary directly will fail.
//
// Usage:  ccn-notify <title> <subtitle> <message> [focus-script-path]
// Build:  swiftc -O -o ccn-notify ccn-notify.swift

import Cocoa
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let focusScript: String?

    init(focusScript: String?) {
        self.focusScript = focusScript
    }

    // Present the banner even when this app is frontmost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list])
    }

    // Banner clicked (or tapped from Notification Center).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let script = focusScript, !script.isEmpty {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = [script]
            try? task.run()
            task.waitUntilExit()
        }
        completionHandler()
        NSApplication.shared.terminate(nil)
    }
}

let args = CommandLine.arguments
guard args.count >= 4 else {
    fputs("usage: ccn-notify <title> <subtitle> <message> [focus-script]\n", stderr)
    exit(1)
}

let title = args[1]
let subtitle = args[2]
let message = args[3]
let focusScript = args.count >= 5 ? args[4] : nil

let delegate = NotificationDelegate(focusScript: focusScript)
let center = UNUserNotificationCenter.current()
center.delegate = delegate

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon, but may present UI

// Auto-exit after 120s if the banner was never clicked.
Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
    NSApplication.shared.terminate(nil)
}

// Request auth on first run; subsequent launches short-circuit to granted.
center.requestAuthorization(options: [.alert, .sound]) { _, authError in
    if let authError = authError {
        fputs("auth error: \(authError)\n", stderr)
    }

    let content = UNMutableNotificationContent()
    content.title = title
    if !subtitle.isEmpty { content.subtitle = subtitle }
    content.body = message

    let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil  // deliver immediately
    )
    center.add(request) { deliverError in
        if let deliverError = deliverError {
            fputs("deliver error: \(deliverError)\n", stderr)
            DispatchQueue.main.async { NSApplication.shared.terminate(nil) }
        }
    }
}

app.run()
