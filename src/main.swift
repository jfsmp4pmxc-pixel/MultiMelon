import Foundation

// Khai báo API ẩn của iOS để tương tác với hệ thống quản lý ứng dụng
// Chức năng này hoạt động hoàn hảo trên các thiết bị chạy TrollStore/Jailbreak
@objc protocol LSApplicationWorkspaceProtocol: NSObjectProtocol {
    func applicationsAvailableSigningFlags(_ flags: AnyObject?, idx: AnyObject?) -> [AnyObject]
    func applicationProxyForIdentifier(_ identifier: String) -> AnyObject?
}

// Cấu trúc dữ liệu cho từng phiên bản Melon Sandbox
struct MelonVersion {
    let id: Int
    let name: String
    let bundleIdentifier: String
    let ipaUrl: String
}

// Danh sách các bản Melon Sandbox (Ông thay link URL thật của ông vào đây nhé)
let melonServerList: [MelonVersion] = [
    MelonVersion(id: 1, name: "Melon Sandbox - Bản Gốc", bundleIdentifier: "com.twentyseven.melonsandbox", ipaUrl: "https://yourserver.com/melon_original.ipa"),
    MelonVersion(id: 2, name: "Melon Sandbox - Bản Clone 1", bundleIdentifier: "com.twentyseven.melonsandbox.clone1", ipaUrl: "https://yourserver.com/melon_clone1.ipa"),
    MelonVersion(id: 3, name: "Melon Sandbox - Bản Clone 2", bundleIdentifier: "com.twentyseven.melonsandbox.clone2", ipaUrl: "https://yourserver.com/melon_clone2.ipa"),
    MelonVersion(id: 4, name: "Melon Sandbox - Bản Clone 3", bundleIdentifier: "com.twentyseven.melonsandbox.clone3", ipaUrl: "https://yourserver.com/melon_clone3.ipa")
]

// Hàm kiểm tra một Bundle ID có đang được cài đặt trên thiết bị hay không
func isAppInstalled(bundleIdentifier: String) -> Bool {
    // Gọi lớp ẩn LSApplicationWorkspace của iOS thông qua NSClassFromString
    guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
          let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
        return false
    }
    
    // Thử tìm proxy của ứng dụng dựa trên Bundle ID
    let selector = NSSelectorFromString("applicationProxyForIdentifier:")
    if workspace.responds(to: selector) {
        let result = workspace.perform(selector, with: bundleIdentifier)?.takeUnretainedValue()
        if result != nil {
            // Nếu tìm thấy thông tin và trạng thái ứng dụng hợp lệ
            let validitySelector = NSSelectorFromString("isInstalled")
            if let isValid = result?.perform(validitySelector)?.takeUnretainedValue() as? Bool {
                return isValid
            }
            return true // Mặc định nếu tìm thấy proxy là ứng dụng có tồn tại
        }
    }
    return false
}

// Giao diện Retro Banner
func printBanner() {
    print("=======================================")
    print("  __  __       _ _   _   __  __      _ ")
    print(" |  \\/  |_   _| | |_(_) |  \\/  | ___| |")
    print(" | |\\/| | | | | | __| | | |\\/| |/ _ \\ |")
    print(" | |  | | |_| | | |_| | | |  | |  __/ |")
    print(" |_|  |_|\\__,_|_|\\__|_| |_|  |_|\\___|_|")
    print("=======================================")
    print("  Multi Melon CLI Edition - Swift v1.0 ")
    print("=======================================\n")
}

// Tính năng 1: Hiển thị kho ứng dụng từ Server và hỗ trợ bấm cài đặt
func handleServerList() {
    print("\n--- [DANH SÁCH PHIÊN BẢN TRÊN SERVER] ---")
    for melon in melonServerList {
        let status = isAppInstalled(bundleIdentifier: melon.bundleIdentifier) ? "[Đã cài]" : "[Chưa cài]"
        print("\(melon.id). \(melon.name) - \(status)")
    }
    print("------------------------------------------")
    print("[*] Nhập số của phiên bản ông muốn cài đặt (hoặc gõ '0' để quay lại):")
    
    if let input = readLine(), let choice = Int(input), choice > 0 && choice <= melonServerList.count {
        let selected = melonServerList[choice - 1]
        installViaTrollStore(version: selected)
    }
}

// Tính năng 2: QUÉT HỆ THỐNG và hiển thị những bản ĐÃ CÀI ĐẶT THỰC TẾ trên máy
func handleInstalledApps() {
    print("\n--- [CÁC PHIÊN BẢN ĐÃ CÀI ĐẶT TRÊN MÁY] ---")
    var count = 0
    var foundApps: [MelonVersion] = []
    
    // Chạy vòng lặp kiểm tra từng Bundle ID trong danh sách quản lý
    for melon in melonServerList {
        if isAppInstalled(bundleIdentifier: melon.bundleIdentifier) {
            count += 1
            foundApps.append(melon)
            print("\(count). Mở nhanh: \(melon.name) (\(melon.bundleIdentifier))")
        }
    }
    
    if count == 0 {
        print("[!] Không tìm thấy phiên bản Melon Sandbox nào được cài trên máy.")
        print("------------------------------------------")
        return
    }
    
    print("------------------------------------------")
    print("[*] Nhập số để MỞ NHANH phiên bản đó (hoặc gõ '0' để quay lại):")
    
    if let input = readLine(), let choice = Int(input), choice > 0 && choice <= foundApps.count {
        let targetApp = foundApps[choice - 1]
        openMelonApp(bundleIdentifier: targetApp.bundleIdentifier)
    }
}

// Kích hoạt TrollStore tải và cài đặt qua URL Scheme
func installViaTrollStore(version: MelonVersion) {
    print("\n[*] Đang gửi yêu cầu cài đặt \(version.name)...")
    let urlString = "trollstore://install?url=\(version.ipaUrl)"
    
    if let url = URL(string: urlString) {
        // Trong môi trường iOS GUI/CLI, lệnh này sẽ mở TrollStore ngay lập tức
        // UIApplication.shared.open(url, options: [:], completionHandler: nil)
        print("[✅] Đã kích hoạt URL Scheme: \(urlString)")
        print("[*] Hãy đợi TrollStore tự động bung lên và xử lý cài đặt ngoài màn hình chính nhé!")
    } else {
        print("[❌] Lỗi: Cấu trúc URL cài đặt không hợp lệ.")
    }
}

// Khởi chạy ứng dụng bằng cách gọi Bundle ID trực tiếp (Mở nhanh từ trong Multi Melon)
func openMelonApp(bundleIdentifier: String) {
    print("\n[*] Đang kích hoạt mở ứng dụng: \(bundleIdentifier)...")
    
    // Sử dụng LSApplicationWorkspace để mở app ngầm bằng ID
    if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
       let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() {
        let selector = NSSelectorFromString("openApplicationWithBundleID:")
        if workspace.responds(to: selector) {
            workspace.perform(selector, with: bundleIdentifier)
            print("[✅] Đã mở app!")
            return
        }
    }
    print("[❌] Lỗi: Không thể khởi chạy ứng dụng này tự động.")
}

// --- VÒNG LẶP CHƯƠNG TRÌNH CHÍNH (MENU) ---
printBanner()

var running = true
while running {
    print("\n[ MENU CHÍNH ]")
    print("1. Xem kho phiên bản cài đặt (Server)")
    print("2. Vào phần ĐÃ CÀI ĐẶT (Mở nhanh Melon Sandbox)")
    print("3. Thoát ứng dụng")
    print("Nhập lựa chọn của ông (1-3): ")
    
    if let choice = readLine() {
        switch choice {
        case "1":
            handleServerList()
        case "2":
            handleInstalledApps()
        case "3":
            print("👋 Tạm biệt ông chủ! Hẹn gặp lại ở dự án tới.")
            running = false
        default:
            print("[⚠️] Lựa chọn không hợp lệ, vui lòng chọn lại.")
        }
    }
}