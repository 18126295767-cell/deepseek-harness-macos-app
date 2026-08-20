import AppKit
import WebKit

private let harnessURL = URL(string: "http://127.0.0.1:3080/")!
private let serviceName = "com.houxinran.deepseek-harness"

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKUIDelegate {
    private var window: NSWindow!
    private var webView: WKWebView!
    private var loadingView: NSVisualEffectView!
    private var statusLabel: NSTextField!
    private var spinner: NSProgressIndicator!
    private var retryTimer: Timer?
    private var retryCount = 0
    private var serviceStartRequested = false

    private var serviceLabel: String {
        "gui/\(getuid())/\(serviceName)"
    }

    private var launchAgentPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(serviceName).plist").path
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureMenus()
        createWindow()
        ensureHarnessIsRunning()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        ensureHarnessIsRunning()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        retryTimer?.invalidate()
        runLaunchctl(["kill", "SIGTERM", serviceLabel])
    }

    @objc private func reloadHarness(_ sender: Any?) {
        showLoading(message: "正在重新载入 DeepSeek Harness...")
        ensureHarnessIsRunning(forceReload: true)
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "DeepSeek Harness",
            .applicationVersion: "0.1.0-rc.6",
            .credits: NSAttributedString(string: "DeepSeek Harness 的非官方本地 macOS 客户端")
        ])
    }

    private func configureMenus() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 DeepSeek Harness", action: #selector(showAbout(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "隐藏 DeepSeek Harness", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            .keyEquivalentModifierMask = [.option, .command]
        appMenu.addItem(withTitle: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "退出 DeepSeek Harness", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "显示")
        let reloadItem = viewMenu.addItem(withTitle: "重新载入", action: #selector(reloadHarness(_:)), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "进入全屏幕", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
            .keyEquivalentModifierMask = [.control, .command]
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "窗口")
        windowMenu.addItem(withTitle: "最小化", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "缩放", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }

    private func createWindow() {
        let frame = NSRect(x: 0, y: 0, width: 1280, height: 820)
        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeepSeek Harness"
        window.minSize = NSSize(width: 900, height: 620)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        webView = WKWebView(frame: frame, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsMagnification = true
        webView.autoresizingMask = [.width, .height]

        let container = NSView(frame: frame)
        container.autoresizingMask = [.width, .height]
        container.addSubview(webView)

        loadingView = NSVisualEffectView(frame: frame)
        loadingView.material = .sidebar
        loadingView.blendingMode = .withinWindow
        loadingView.state = .active
        loadingView.autoresizingMask = [.width, .height]

        spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .large
        spinner.startAnimation(nil)
        spinner.translatesAutoresizingMaskIntoConstraints = false

        statusLabel = NSTextField(labelWithString: "正在启动 DeepSeek Harness...")
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        loadingView.addSubview(spinner)
        loadingView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -18),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            statusLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: loadingView.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: loadingView.trailingAnchor, constant: -24)
        ])
        container.addSubview(loadingView)

        window.contentView = container
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func ensureHarnessIsRunning(forceReload: Bool = false) {
        checkServer { [weak self] ready in
            guard let self else { return }
            if ready {
                self.loadHarness(forceReload: forceReload)
                return
            }

            self.showLoading(message: "正在启动本地服务...")
            if !self.serviceStartRequested {
                self.serviceStartRequested = true
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.startLaunchAgent()
                }
            }
            self.beginReadinessPolling(forceReload: forceReload)
        }
    }

    private func beginReadinessPolling(forceReload: Bool) {
        retryTimer?.invalidate()
        retryCount = 0
        retryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.retryCount += 1
            self.checkServer { [weak self] ready in
                guard let self else { return }
                if ready {
                    timer.invalidate()
                    self.serviceStartRequested = false
                    self.loadHarness(forceReload: forceReload)
                } else if self.profileIntegrityFailureDetected() {
                    timer.invalidate()
                    self.serviceStartRequested = false
                    self.showProfileIntegrityFailure()
                } else if self.retryCount >= 120 {
                    timer.invalidate()
                    self.serviceStartRequested = false
                    self.showStartupFailure()
                }
            }
        }
    }

    private func startLaunchAgent() {
        if runLaunchctl(["kickstart", serviceLabel]) == 0 {
            return
        }
        _ = runLaunchctl(["bootstrap", "gui/\(getuid())", launchAgentPath])
        _ = runLaunchctl(["kickstart", serviceLabel])
    }

    @discardableResult
    private func runLaunchctl(_ arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            return -1
        }
    }

    private func checkServer(completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: harnessURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 2
        URLSession.shared.dataTask(with: request) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode
            let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let ready = status == 200 && body.contains("<title>DeepSeek Harness</title>")
            DispatchQueue.main.async {
                completion(ready)
            }
        }.resume()
    }

    private func loadHarness(forceReload: Bool) {
        showLoading(message: "正在载入界面...")
        if forceReload, webView.url != nil {
            webView.reloadFromOrigin()
        } else if webView.url == nil {
            webView.load(URLRequest(url: harnessURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30))
        } else {
            hideLoading()
        }
    }

    private func showLoading(message: String) {
        statusLabel?.stringValue = message
        spinner?.startAnimation(nil)
        loadingView?.isHidden = false
        loadingView?.superview?.addSubview(loadingView, positioned: .above, relativeTo: webView)
    }

    private func hideLoading() {
        spinner?.stopAnimation(nil)
        loadingView?.isHidden = true
    }

    private func showStartupFailure() {
        statusLabel.stringValue = "本地服务启动失败"
        spinner.stopAnimation(nil)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "DeepSeek Harness 无法启动"
        alert.informativeText = "请查看 ~/Library/Logs/DeepSeekHarness.log 了解详细信息。"
        alert.addButton(withTitle: "打开日志")
        alert.addButton(withTitle: "重试")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/DeepSeekHarness.log"))
        } else {
            ensureHarnessIsRunning(forceReload: true)
        }
    }

    private func profileIntegrityFailureDetected() -> Bool {
        FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DeepSeekHarness.profile-error").path)
    }

    private func showProfileIntegrityFailure() {
        statusLabel.stringValue = "检测到插件依赖冲突"
        spinner.stopAnimation(nil)

        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "DeepSeek Harness 已阻止不兼容的 profile 启动"
        alert.informativeText = "某个插件安装了 DSH 核心包的第二个副本，可能导致工具调用中断。请打开日志查看冲突插件并升级或移除它；不要继续使用已损坏的旧会话，请新建会话重新发送任务。检查器没有删除任何文件。"
        alert.addButton(withTitle: "打开诊断日志")
        alert.addButton(withTitle: "关闭")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Logs/DeepSeekHarness.log"))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideLoading()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        ensureHarnessIsRunning(forceReload: true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        ensureHarnessIsRunning(forceReload: true)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if url.host == "127.0.0.1" || url.host == "localhost" || url.scheme == "about" {
            decisionHandler(.allow)
        } else {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
