// Test-only entry point; persistence spies do not access Keychain or write user settings.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    KeyStore.useForSession("lifecycle-test-key"); GeneratorKeyStore.useForSession("generator-lifecycle-key")
    let delegate = AppDelegate()
    var saved = 0; var keys = 0
    delegate.persistConfiguration = { _ in saved += 1 }
    delegate.persistAPIKey = { key in precondition(key == "lifecycle-test-key"); keys += 1 }
    delegate.persistGeneratorKey = { key in precondition(key == "generator-lifecycle-key") }
    app.delegate = delegate; app.setActivationPolicy(.regular)
    var step = 0
    let testTimer = Timer.scheduledTimer(withTimeInterval:0.2,repeats:true) { timer in
        MainActor.assumeIsolated {
            precondition(delegate.panel != nil && delegate.panel.isVisible)
            precondition(!delegate.applicationShouldTerminateAfterLastWindowClosed(app))
            switch step {
            case 0: delegate.showSettings(); delegate.storeSettings()
            case 1:
                precondition(delegate.configWindow == nil && saved == 1 && keys == 1)
                delegate.showSettings(); delegate.sessionSettings()
            case 2:
                precondition(delegate.configWindow == nil && saved == 2 && keys == 1)
                delegate.showSettings(); delegate.cancelSettings()
            case 3:
                precondition(delegate.configWindow == nil)
                delegate.showSettings(); delegate.configWindow!.performClose(nil)
            case 4:
                precondition(delegate.configWindow == nil)
                delegate.showSettings(); delegate.storeSettings()
            default:
                precondition(delegate.configWindow == nil && saved == 3 && keys == 2)
                print("PASS: Save Key, session save, cancel, red close, repeated save; sidebar and AppKit event loop remain alive; real settings and Keychain untouched")
                timer.invalidate(); exit(0)
            }
            step += 1
        }
    }
    withExtendedLifetime((delegate, testTimer)) { app.run() }
}
