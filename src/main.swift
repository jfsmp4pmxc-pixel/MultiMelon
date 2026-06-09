import UIKit
import Foundation

// Khai báo API ẩn kiểm tra ứng dụng hệ thống
@objc protocol LSApplicationWorkspaceProtocol: NSObjectProtocol {
    func defaultWorkspace() -> AnyObject?
    func applicationProxyForIdentifier(_ identifier: String) -> AnyObject?
}

// Cấu trúc dữ liệu Melon chuẩn cấu trúc của file JSON (phải kế thừa Decodable để tự động parse)
struct MelonVersion: Decodable {
    let id: Int
    let name: String
    let bundleIdentifier: String
    let ipaUrl: String
}

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

// --- GIAO DIỆN CHÍNH (GUI) ---
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    var loadingIndicator: UIActivityIndicatorView!
    
    var currentTab = 0 
    var serverList: [MelonVersion] = []       // Danh sách gốc tải từ JSON về
    var displayedApps: [MelonVersion] = []    // Danh sách đang hiển thị trên màn hình
    
    // ⚠️ ĐƯỜNG DẪN ĐẾN FILE JSON TRÊN GITHUB CỦA ÔNG
    // Lưu ý: Phải dùng link dạng RAW (raw.githubusercontent.com) thì app mới đọc được trực tiếp
    let jsonRawUrl = "https://raw.githubusercontent.com/jfsmp4pmxc-pixel/MultiMelon/main/versions.json"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupHeaderBanner()
        setupTabControl()
        setupTableView()
        setupLoadingIndicator()
        
        // Bắt đầu tải dữ liệu từ mạng
        fetchJsonData()
    }
    
    // Hàm gọi mạng tải file JSON về từ xa
    func fetchJsonData() {
        guard let url = URL(string: jsonRawUrl.replacingOccurrences(of: "ten_tai_khoan", with: "YOUR_REAL_GITHUB_USERNAME")) else { 
            print("URL cấu hình không hợp lệ")
            return 
        }
        
        loadingIndicator.startAnimating()
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data, error == nil {
                do {
                    // Tự động phân tích cú pháp JSON thành mảng dữ liệu Swift
                    let decodedData = try JSONDecoder().decode([MelonVersion].self, from: data)
                    
                    DispatchQueue.main.sync {
                        self.serverList = decodedData
                        self.refreshData()
                        self.loadingIndicator.stopAnimating()
                    }
                } catch {
                    print("Lỗi phân tích file JSON: \(error)")
                    DispatchQueue.main.sync { self.loadingIndicator.stopAnimating() }
                }
            } else {
                print("Lỗi kết nối mạng hoặc server tèo")
                DispatchQueue.main.sync { self.loadingIndicator.stopAnimating() }
            }
        }.resume()
    }
    
    func refreshData() {
        displayedApps.removeAll()
        if currentTab == 0 {
            displayedApps = serverList
        } else {
            for melon in serverList {
                if checkAppInstalled(bundleIdentifier: melon.bundleIdentifier) {
                    displayedApps.append(melon)
                }
            }
        }
        tableView.reloadData()
    }
    
    // --- CẤU HÌNH GIAO DIỆN (UI) ---
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
        ======= CLOUD MANAGEMENT SYSTEM =======
        """
        view.addSubview(bannerLabel)
        
        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            bannerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            bannerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    func setupTabControl() {
        let items = ["Kho Máy Chủ", "Đã Cài Đặt"]
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.backgroundColor = .darkGray
        segmentedControl.selectedSegmentTintColor = .green
        
        let normalAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)]
        let selectedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.monospacedSystemFont(ofSize: 13, weight: .bold)]
        segmentedControl.setTitleTextAttributes(normalAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedAttributes, for: .selected)
        
        segmentedControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
        view.addSubview(segmentedControl)
        
        if let banner = view.subviews.first(where: { $0 is UILabel }) {
            NSLayoutConstraint.activate([
                segmentedControl.topAnchor.constraint(equalTo: banner.bottomAnchor, constant: 15),
                segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                segmentedControl.heightAnchor.constraint(equalToConstant: 35)
            ])
        }
    }
    
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
    
    func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.color = .green
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func tabChanged(_ sender: UISegmentedControl) {
        currentTab = sender.selectedSegmentIndex
        refreshData()
    }
    
    // --- DELEGATE TABLEVIEW ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedApps.isEmpty ? 1 : displayedApps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MelonCell", for: indexPath)
        cell.backgroundColor = .black
        cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        if displayedApps.isEmpty {
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = currentTab == 0 ? "[ ] Đang đồng bộ kho dữ liệu..." : "[ ] Chưa phát hiện bản Clone nào."
            cell.accessoryView = nil
            return cell
        }
        
        let melon = displayedApps[indexPath.row]
        let isInstalled = checkAppInstalled(bundleIdentifier: melon.bundleIdentifier)
        
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = "> \(melon.name)"
        
        let actionButton = UIButton(type: .system)
        actionButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        actionButton.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        actionButton.layer.borderWidth = 1
        actionButton.layer.cornerRadius = 4
        
        if currentTab == 0 {
            if isInstalled {
                actionButton.setTitle("[CÀI ĐẶT]", for: .normal)
                actionButton.setTitleColor(.lightGray, for: .normal)
                actionButton.layer.borderColor = UIColor.lightGray.cgColor
                actionButton.isEnabled = false
            } else {
                actionButton.setTitle("GET", for: .normal)
                actionButton.setTitleColor(.green, for: .normal)
                actionButton.layer.borderColor = UIColor.green.cgColor
                actionButton.tag = indexPath.row
                actionButton.addTarget(self, action: #selector(installClicked(_:)), for: .touchUpInside)
            }
        } else {
            actionButton.setTitle("RUN >", for: .normal)
            actionButton.setTitleColor(.cyan, for: .normal)
            actionButton.layer.borderColor = UIColor.cyan.cgColor
            actionButton.tag = indexPath.row
            actionButton.addTarget(self, action: #selector(runClicked(_:)), for: .touchUpInside)
        }
        
        cell.accessoryView = actionButton
        return cell
    }
    
    @objc func installClicked(_ sender: UIButton) {
        let selectedApp = displayedApps[sender.tag]
        let trollStoreUrl = "trollstore://install?url=\(selectedApp.ipaUrl)"
        if let url = URL(string: trollStoreUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func runClicked(_ sender: UIButton) {
        let selectedApp = displayedApps[sender.tag]
        if let workspaceClass = NSClassFromString("LSApplicationWorkspace") as? NSObject.Type,
           let workspace = workspaceClass.perform(NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() {
            let selector = NSSelectorFromString("openApplicationWithBundleID:")
            if workspace.responds(to: selector) {
                workspace.perform(selector, with: selectedApp.bundleIdentifier)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 50 }
}

// --- KHỞI CHẠY APP ---
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
