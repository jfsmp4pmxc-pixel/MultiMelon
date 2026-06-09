import UIKit
import Foundation

// Khai báo API ẩn của iOS để quét ứng dụng trên thiết bị (Yêu cầu TrollStore/Jailbreak)
@objc protocol LSApplicationWorkspaceProtocol: NSObjectProtocol {
    func defaultWorkspace() -> AnyObject?
    func applicationProxyForIdentifier(_ identifier: String) -> AnyObject?
}

// Cấu trúc dữ liệu phiên bản Melon Sandbox
struct MelonVersion {
    let id: Int
    let name: String
    let bundleIdentifier: String
    let ipaUrl: String
}

// Danh sách các bản Clone dọn sẵn trên Server của ông
let melonServerList: [MelonVersion] = [
    MelonVersion(id: 1, name: "Melon Sandbox - Bản Gốc", bundleIdentifier: "com.twentyseven.melonsandbox", ipaUrl: "https://yourserver.com/melon_original.ipa"),
    MelonVersion(id: 2, name: "Melon Sandbox - Bản Clone 1", bundleIdentifier: "com.twentyseven.melonsandbox.clone1", ipaUrl: "https://yourserver.com/melon_clone1.ipa"),
    MelonVersion(id: 3, name: "Melon Sandbox - Bản Clone 2", bundleIdentifier: "com.twentyseven.melonsandbox.clone2", ipaUrl: "https://yourserver.com/melon_clone2.ipa"),
    MelonVersion(id: 4, name: "Melon Sandbox - Bản Clone 3", bundleIdentifier: "com.twentyseven.melonsandbox.clone3", ipaUrl: "https://yourserver.com/melon_clone3.ipa")
]

// Hàm kiểm tra xem app đã được cài đặt trên máy chưa
func checkAppInstalled(bundleIdentifier: String) -> Bool {
    guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
          let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
        return false
    }
    let selector = NSSelectorFromString("applicationProxyForIdentifier:")
    if workspace.responds(to: selector) {
        let result = workspace.perform(selector, with: bundleIdentifier)?.takeUnretainedValue()
        return result != nil
    }
    return false
}

// --- GIAO DIỆN CHÍNH CỦA ỨNG DỤNG (GUI) ---
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    var currentTab = 0 // 0: Server, 1: Đã cài đặt
    var displayedApps: [MelonVersion] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Thiết lập nền đen chuẩn Retro
        view.backgroundColor = .black
        
        setupHeaderBanner()
        setupTabControl()
        setupTableView()
        
        // Tải dữ liệu mặc định cho Tab Server
        refreshData()
    }
    
    // 1. Tạo Banner chữ nghệ thuật phía trên cùng app
    func setupHeaderBanner() {
        let bannerLabel = UILabel()
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        bannerLabel.textColor = .green
        bannerLabel.numberOfLines = 0
        bannerLabel.textAlignment = .center
        bannerLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        bannerLabel.text = """
         __  __       _ _   _   __  __      _ 
        |  \\/  |_   _| | |_(_) |  \\/  | ___| |
        | |\\/| | | | | | __| | | |\\/| |/ _ \\ |
        | |  | | |_| | | |_| | | |  | |  __/ |
        |_|  |_|\\__,_|_|\\__|_| |_|  |_|\\___|_|
        ======= RETRO MANAGEMENT SYSTEM =======
        """
        view.addSubview(bannerLabel)
        
        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            bannerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            bannerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    // 2. Tạo Thanh chuyển Tab (Server / Đã Cài Đặt)
    func setupTabControl() {
        let items = ["Kho Phiên Bản", "Đã Cài Đặt"]
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        
        // Custom màu sắc phong cách Retro màu xanh lá cây
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.selectedSegmentTintColor = .green
        
        let normalAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)]
        let selectedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)]
        
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        // Tìm nhãn chữ banner phía trên để neo thanh chuyển tab xuống dưới nó
        if let banner = view.subviews.first(where: { $0 is UILabel }) {
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: 15),
                segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                segmentedControl.heightAnchor.constraint(equalToConstant: 35)
            ])
        }
    }
    
    // 3. Tạo Bảng danh sách các bản Melon
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MelonCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 15),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Xử lý sự kiện khi người dùng chuyển Tab
    @objc func tabChanged(_ sender: UISegmentedControl) {
        currentTab = sender.selectedSegmentIndex
        refreshData()
    }
    
    // Làm mới danh sách hiển thị tương ứng với từng Tab
    func refreshData() {
        displayedApps.removeAll()
        if currentTab == 0 {
            // Tab 0: Lấy toàn bộ danh sách trên server
            displayedApps = melonServerList
        } else {
            // Tab 1: Quét hệ thống xem bản nào cài rồi thì mới đưa vào danh sách
            for melon in melonServerList {
                if checkAppInstalled(bundleIdentifier: melon.bundleIdentifier) {
                    displayedApps.append(melon)
                }
            }
        }
        tableView.reloadData()
    }
    
    // --- ĐỊNH CẤU HÌNH TABLEVIEW DATASOURCE / DELEGATE ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if displayedApps.count == 0 {
            return 1 // Hiển thị 1 dòng thông báo trống nếu không có dữ liệu
        }
        return displayedApps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MelonCell", for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        // Nếu danh sách trống rỗng
        if displayedApps.count == 0 {
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = currentTab == 0 ? "[ ] Không có dữ liệu server." : "[ ] Chưa cài đặt phiên bản clone nào."
            cell.accessoryView = nil
            return cell
        }
        
        let melon = displayedApps[indexPath.row]
        let isInstalled = checkAppInstalled(bundleIdentifier: melon.bundleIdentifier)
        
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = "> \(melon.name)"
        
        // Tạo nút bấm hành động (Tải / Mở) ở góc bên phải mỗi dòng
        let actionButton = UIButton(type: .system)
        actionButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        actionButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        actionButton.layer.borderWidth = 1
        actionButton.layer.cornerRadius = 4
        
        if currentTab == 0 {
            // Ở bên Tab Kho Server
            if isInstalled {
                actionButton.setTitle("[ĐÃ CÀI]", for: .normal)
                actionButton.setTitleColor(.lightGray, for: .normal)
                actionButton.layer.borderColor = UIColor.lightGray.cgColor
                actionButton.isEnabled = false
            } else {
                actionButton.setTitle("GET", for: .normal)
                actionButton.setTitleColor(.green, for: .normal)
                actionButton.layer.borderColor = UIColor.green.cgColor
                actionButton.tag = indexPath.row
                actionButton.addTarget(self, action: #selector(installClicked(_:)), for: .touchUpInside)
                actionButton.isEnabled = true
            }
        } else {
            // Ở bên Tab Đã Cài Đặt
            actionButton.setTitle("RUN >", for: .normal)
            actionButton.setTitleColor(.cyan, for: .normal)
            actionButton.layer.borderColor = UIColor.cyan.cgColor
            actionButton.tag = indexPath.row
            actionButton.addTarget(self, action: #selector(runClicked(_:)), for: .touchUpInside)
        }
        
        cell.accessoryView = actionButton
        return cell
    }
    
    // Thực hiện hành động gọi TrollStore khi nhấn nút GET
    @objc func installClicked(_ sender: UIButton) {
        let index = sender.tag
        let selectedApp = displayedApps[index]
        let trollStoreUrlString = "trollstore://install?url=\(selectedApp.ipaUrl)"
        
        if let url = URL(string: trollStoreUrlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    // Thực hiện mở nhanh ứng dụng Melon khi nhấn nút RUN
    @objc func runClicked(_ sender: UIButton) {
        let index = sender.tag
        let selectedApp = displayedApps[index]
        
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
           let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() {
            let selector = NSSelectorFromString("openApplicationWithBundleID:")
            if workspace.responds(to: selector) {
                workspace.perform(selector, with: selectedApp.bundleIdentifier)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// --- KHỞI CHẠY HỆ THỐNG ỨNG DỤNG GUI ---
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainVC = MainViewController()
        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()
        return true
    }
}

UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
