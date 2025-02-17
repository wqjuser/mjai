import Cocoa
import FlutterMacOS
import Foundation

@main
class AppDelegate: FlutterAppDelegate {
    private var screenResolutionChannel: FlutterMethodChannel?
    private var permissionChannel: FlutterMethodChannel?
    private var clipboardChannel: FlutterMethodChannel?
    private var screenshotChannel: FlutterMethodChannel?
    private let mjaiFolder = "MJAI"
    private var securityScopedAccess: URL?
    private var monitor: DispatchSourceFileSystemObject?
    
    // 用于存储截图选择窗口
    private var selectionWindow: NSWindow?

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
      return true
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
            print("Failed to get FlutterViewController")
            return
        }
        
        // 应用启动时尝试恢复权限
        _ = restoreSecurityScopedAccess()
        
        // 初始化屏幕分辨率通道
        screenResolutionChannel = FlutterMethodChannel(
            name: "com.htx.nativeChannel/screenResolution",
            binaryMessenger: controller.engine.binaryMessenger)
        
        screenResolutionChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getSystemScreenResolution":
                self.getSystemScreenResolution(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // 初始化剪切板通道
        clipboardChannel = FlutterMethodChannel(
            name: "clipboard_listener",
            binaryMessenger: controller.engine.binaryMessenger)
        
        clipboardChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "getClipboardFiles":
                self.getClipboardFiles(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // 初始化权限通道
        permissionChannel = FlutterMethodChannel(
            name: "com.htx.macos/permissions",
            binaryMessenger: controller.engine.binaryMessenger)
        
        permissionChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "requestDocumentsAccess":
                if let path = self.getMJAIFolderPath() {
                    result(path)
                } else {
                    self.requestSystemDocumentsAccess { success in
                        if success {
                            if let path = self.getMJAIFolderPath() {
                                result(path)
                            } else {
                                result(FlutterError(code: "PATH_ERROR",
                                                    message: "无法获取 MJAI 文件夹路径",
                                                    details: nil))
                            }
                        } else {
                            result(FlutterError(code: "PERMISSION_DENIED",
                                                message: "权限被拒绝",
                                                details: nil))
                        }
                    }
                }
            case "getMJAIPath":
                result(self.getMJAIFolderPath())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // 初始化截图通道
        screenshotChannel = FlutterMethodChannel(
            name: "com.htx.nativeChannel/screenshot",
            binaryMessenger: controller.engine.binaryMessenger)
        
        screenshotChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "captureScreen":
                self.requestDesktopAccess { granted in
                    if granted {
                        self.captureScreen(result: result)
                    } else {
                        result(FlutterError(code: "PERMISSION_DENIED",
                                            message: "未获得桌面文件夹访问权限",
                                            details: nil))
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        super.applicationDidFinishLaunching(notification)
    }
    
    // MARK: - Clipboard Methods
    
    private func getClipboardFiles(result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        var filePaths: [String] = []
        
        if pasteboard.canReadObject(forClasses: [NSURL.self], options: nil) {
            if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL] {
                filePaths = urls.compactMap { url -> String? in
                    guard url.isFileURL else { return nil }
                    return url.path
                }
            }
        }
        
        if !filePaths.isEmpty {
            result(filePaths)
        } else {
            result(nil)
        }
    }
    
    // MARK: - Screen Resolution Methods
    
    private func getSystemScreenResolution(result: @escaping FlutterResult) {
        guard let screen = NSScreen.main else {
            result(FlutterError(code: "NO_SCREEN",
                                message: "无法获取主屏幕",
                                details: nil))
            return
        }
        
        let screenSize = screen.frame.size
        let screenScale = screen.backingScaleFactor
        
        let physicalWidth = Int(screenSize.width * screenScale)
        let physicalHeight = Int(screenSize.height * screenScale)
        
        result("\(physicalWidth)x\(physicalHeight)")
    }
    
    // MARK: - Permission Methods
    
    private func restoreSecurityScopedAccess() -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "SystemDocumentsBookmark") else {
            return false
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                return false
            }
            
            if url.startAccessingSecurityScopedResource() {
                securityScopedAccess = url
                return true
            }
            
            return false
        } catch {
            print("解析书签时出错: $error)")
            return false
        }
    }
    
    private func requestSystemDocumentsAccess(completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.message = "魔镜AI默认使用系统的文档文件夹，您可以选择任何您喜欢的文件夹"
        openPanel.prompt = "选择文件夹"
        
        let documentsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        openPanel.directoryURL = documentsURL
        
        openPanel.begin { [weak self] response in
            guard let self = self else { return }
            
            if response == .OK, let selectedURL = openPanel.url {
                if selectedURL.startAccessingSecurityScopedResource() {
                    self.securityScopedAccess = selectedURL
                    
                    do {
                        let bookmarkData = try selectedURL.bookmarkData(
                            options: .withSecurityScope,
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )
                        UserDefaults.standard.set(bookmarkData, forKey: "SystemDocumentsBookmark")
                        
                        let mjaiURL = selectedURL.appendingPathComponent(self.mjaiFolder)
                        try FileManager.default.createDirectory(
                            at: mjaiURL,
                            withIntermediateDirectories: true
                        )
                        
                        let readmeURL = mjaiURL.appendingPathComponent("README.txt")
                        if !FileManager.default.fileExists(atPath: readmeURL.path) {
                            let readmeContent = "这个文件夹用来存放 魔镜AI 的文件.\n请勿删除此文件夹，否则会影响程序正常运行。"
                            try readmeContent.write(to: readmeURL, atomically: true, encoding: .utf8)
                        }
                        
                        completion(true)
                    } catch {
                        print("创建书签或文件夹时出错: $error)")
                        selectedURL.stopAccessingSecurityScopedResource()
                        self.securityScopedAccess = nil
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private func getMJAIFolderPath() -> String? {
        if securityScopedAccess == nil && !restoreSecurityScopedAccess() {
            return nil
        }
        
        guard let url = securityScopedAccess else {
            return nil
        }
        
        let mjaiURL = url.appendingPathComponent(mjaiFolder)
        
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: mjaiURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
            return mjaiURL.path
        }
        
        return nil
    }
    
    private func requestDesktopAccess(completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "选择桌面文件夹以授予访问权限"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        
        openPanel.begin { (response) in
            if response == .OK, let url = openPanel.url {
                // 保存选择的路径以便后续使用
                UserDefaults.standard.set(url.path, forKey: "DesktopPath")
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Screenshot Methods
    private func captureScreen(result: @escaping FlutterResult) {
        guard let desktopPath = UserDefaults.standard.string(forKey: "DesktopPath") else {
            result(FlutterError(code: "NO_DESKTOP_PATH",
                                message: "未设置桌面文件夹路径",
                                details: nil))
            return
        }
        
        // 启动系统截图应用
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.screenshot.launcher") {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { (app, error) in
                if let error = error {
                    result(FlutterError(code: "APP_LAUNCH_FAILED",
                                        message: "无法启动截图应用: $error.localizedDescription)",
                                        details: nil))
                } else {
                    // 监听桌面文件夹中的新文件
                    self.monitorDesktopFolder(path: desktopPath, result: result)
                }
            }
        } else {
            result(FlutterError(code: "APP_NOT_FOUND",
                                message: "未找到截图应用",
                                details: nil))
        }
    }
    
    private func monitorDesktopFolder(path: String, result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        let desktopURL = URL(fileURLWithPath: path)
        
        // 打开文件夹的文件描述符，使用 O_EVTONLY 只监听事件，不进行读写
        let fileDescriptor = open(desktopURL.path, O_EVTONLY)
        if fileDescriptor == -1 {
            DispatchQueue.main.async {
                result(FlutterError(code: "FILE_ERROR",
                                    message: "无法打开桌面文件夹",
                                    details: String(cString: strerror(errno))))
            }
            return
        }
        
        // 创建文件系统对象源
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                               eventMask: .write,
                                                               queue: DispatchQueue.global())
        
        source.setEventHandler {
            do {
                // 获取桌面文件夹中的所有文件URL，并包含修改日期属性
                let fileURLs = try fileManager.contentsOfDirectory(at: desktopURL,
                                                                   includingPropertiesForKeys: [.contentModificationDateKey],
                                                                   options: .skipsHiddenFiles)
                
                // 根据修改日期排序，获取最新的文件
                if let latestFileURL = fileURLs.sorted(by: { (url1, url2) -> Bool in
                    let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                    return date1 > date2
                }).first {
                    let fullPath = latestFileURL.path
                    DispatchQueue.main.async {
                        result(fullPath)
                    }
                    source.cancel()
                } else {
                    // 桌面文件夹中没有文件
                    DispatchQueue.main.async {
                        result(FlutterError(code: "NO_FILES",
                                            message: "桌面文件夹中没有文件。",
                                            details: nil))
                    }
                    source.cancel()
                }
            } catch {
                // 处理读取文件夹内容时的错误
                DispatchQueue.main.async {
                    result(FlutterError(code: "READ_ERROR",
                                        message: "无法读取桌面文件夹内容。",
                                        details: error.localizedDescription))
                }
                source.cancel()
            }
        }
        
        source.setCancelHandler {
            close(fileDescriptor)
        }
        
        source.resume()
    }
    
    private func showSelectionWindow(result: @escaping FlutterResult) {
        // 创建一个透明窗口用于选择区域
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.level = .statusBar
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 创建并设置 SelectionView
        let selectionView = SelectionView(frame: screenFrame) { [weak self] selectedRect in
            window.close()
            self?.captureSelectedArea(rect: selectedRect, result: result)
        }
        
        window.contentView = selectionView
        window.makeKeyAndOrderFront(nil)
        self.selectionWindow = window
    }
    
    
    
    
    private func captureSelectedArea(rect: NSRect, result: @escaping FlutterResult) {
        // 先隐藏选区窗口
        self.selectionWindow?.orderOut(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                result(FlutterError(code: "FAILED",
                                    message: "无法捕捉屏幕",
                                    details: nil))
                return
            }
            
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                result(FlutterError(code: "FAILED",
                                    message: "无法转换图像",
                                    details: nil))
                return
            }
            
            guard let mjaiPath = self.getMJAIFolderPath() else {
                result(FlutterError(code: "PATH_ERROR",
                                    message: "无法获取 MJAI 文件夹路径",
                                    details: nil))
                return
            }
            
            let fileManager = FileManager.default
            let mjaiURL = URL(fileURLWithPath: mjaiPath)
            let timestamp = Int(Date().timeIntervalSince1970)
            let fileName = "screenshot_\(timestamp).png" // 修正字符串插值
            let fileURL = mjaiURL.appendingPathComponent(fileName)
            
            do {
                try pngData.write(to: fileURL)
                result(fileURL.path)
            } catch {
                result(FlutterError(code: "WRITE_ERROR",
                                    message: "无法将图像写入磁盘",
                                    details: error.localizedDescription))
            }
            
            // 重新显示选区窗口
            self.selectionWindow?.makeKeyAndOrderFront(nil)
        }
    }
    
    
    // MARK: - Application Lifecycle
    
    override func applicationWillTerminate(_ notification: Notification) {
        if let url = securityScopedAccess {
            url.stopAccessingSecurityScopedResource()
        }
        super.applicationWillTerminate(notification)
    }
}

// MARK: - SelectionView

class SelectionView: NSView {
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var selectionRect: NSRect = .zero
    private var completion: ((NSRect) -> Void)?
    
    init(frame frameRect: NSRect, completion: @escaping (NSRect) -> Void) {
        self.completion = completion
        super.init(frame: frameRect)
        self.wantsLayer = true
        let trackingArea = NSTrackingArea(rect: frameRect,
                                          options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if selectionRect != .zero {
            // 设置填充颜色为透明
            NSColor.clear.setFill()
            
            // 创建一个路径并描边
            let path = NSBezierPath(rect: selectionRect)
            NSColor.selectedControlColor.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        startPoint = location
        currentPoint = location
        selectionRect = NSRect(origin: location, size: .zero)
        setNeedsDisplay(bounds)
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let location = convert(event.locationInWindow, from: nil)
        currentPoint = location
        selectionRect = NSRect(x: min(start.x, location.x),
                               y: min(start.y, location.y),
                               width: abs(location.x - start.x),
                               height: abs(location.y - start.y))
        setNeedsDisplay(bounds)
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let start = startPoint, let end = currentPoint else { return }
        let rect = NSRect(x: min(start.x, end.x),
                          y: min(start.y, end.y),
                          width: abs(end.x - start.x),
                          height: abs(end.y - start.y))
        completion?(rect)
    }
}
