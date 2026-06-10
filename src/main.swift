import UIKit
import Foundation

@objc protocol LSApplicationWorkspaceProtocol: NSObjectProtocol {
    func defaultWorkspace() -> AnyObject?
    func applicationProxyForIdentifier(_ identifier: String) -> AnyObject?
}

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

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tableView: UITableView!
    var segmentedControl: UISegmentedControl!
    var loadingIndicator: UIActivityIndicatorView!
    
    var currentTab = 0 
    var serverList: [MelonVersion] = []       
    var displayedApps: [MelonVersion] = []    
    
    // ✅ ĐÃ ĐỔI CHUẨN ĐƯỜNG DẪN RAW THEO TÊN ACC CỦA ÔNG
    let jsonRawUrl = "https://raw.githubusercontent.com/jfsmp4pmxc-pixel/MultiMelon/main/versions.json"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // nạp dữ liệu dự phòng thiết lập sẵn (để nút GET luôn hoạt động kể cả khi mất mạng)
        setupOfflineBackupData()
        
        setupHeaderBanner()
        setupTabControl()
        setupTableView()
        setupLoadingIndicator()
        
        fetchJsonData()
    }
    
    // Dữ liệu dự phòng chuẩn link release của ông phòng khi file JSON bị lỗi cú pháp
    func setupOfflineBackupData() {
        let backup = [
            MelonVersion(id: 1, name: "Melon Sandbox - Bản Gốc", bundleIdentifier: "com.twentyseven.melonsandbox", ipaUrl: "https://github.com/jfsmp4pmxc-pixel/MultiMelon/releases/download/v1.0-clones/melon_original.ipa"),
            MelonVersion(id: 2, name: "Melon Sandbox - Bản Clone 1", bundleIdentifier: "com.twentyseven.melonsandbox.clone1", ipaUrl: "https://github.com/jfsmp4pmxc-pixel/MultiMelon/releases/download/v1.0-clones/melon_clone1.ipa"),
            MelonVersion(id: 3, name: "Melon Sandbox - Bản Clone 2", bundleIdentifier: "com.twentyseven.melonsandbox.clone2", ipaUrl: "https://github.com/jfsmp4pmxc-pixel/MultiMelon/releases/download/v1.0-clones/melon_clone2.ipa")
        ]
        self.serverList = backup
        self.displayedApps = backup
    }
    
    func fetchJsonData() {
        guard let url = URL(string: jsonRawUrl) else { return }
        
        loadingIndicator.startAnimating()
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async { self.loadingIndicator.stopAnimating() }
            
            if let data = data, error == nil {
                do {
                    let decodedData = try JSONDecoder().decode([MelonVersion].self, from: data)
                    print("[✅] Kết nối đám mây thành công!")
                    DispatchQueue.main.async {
                        self.serverList = decodedData
                        self.refreshData()
                    }
                } catch {
                    print("[❌] Lỗi dịch JSON, ứng dụng tự động dùng data dự phòng")
                }
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
    
    // --- GIAO DIỆN RETRO PIXEL ---
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
    
    // --- TABLEVIEW LOGIC ---
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedApps.isEmpty ? 1 : displayedApps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MelonCell", for: indexPath)
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        if displayedApps.isEmpty {
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = currentTab == 0 ? "[ ] Không có dữ liệu." : "[ ] Không tìm thấy bản clone nào đã cài."
            cell.accessoryView = nil
            return cell
        }
        
        let melon = displayedApps[indexPath.row]
        let isInstalled = checkAppInstalled(bundleIdentifier: melon.bundleIdentifier)
        
        cell.textLabel?.textColor = .white
        cell.textLabel?.text = "> \(melon.name)"
        
        let actionButton = UIButton(type: .system)
        actionButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
        actionButton.frame = CGRect(x: 0, y: 0, width: 85, height: 30)
        actionButton.layer.borderWidth = 1
        actionButton.layer.cornerRadius = 4
        
        if currentTab == 0 {
            if isInstalled {
                actionButton.setTitle("[ĐÃ CÀI]", for: .normal)
                actionButton.setTitleColor(.gray, for: .normal)
                actionButton.layer.borderColor = UIColor.gray.cgColor
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
            actionButton.setTitle("RUN >", for: .normal)
            actionButton.setTitleColor(.cyan, for: .normal)
            actionButton.layer.borderColor = UIColor.cyan.cgColor
            actionButton.tag = indexPath.row
            actionButton.addTarget(self, action: #selector(runClicked(_:)), for: .touchUpInside)
            actionButton.isEnabled = true
        }
        
        cell.accessoryView = actionButton
        return cell
    }
    
    @objc func installClicked(_ sender: UIButton) {
        guard sender.tag < displayedApps.count else { return }
        let selectedApp = displayedApps[sender.tag]
        let trollStoreUrl = "trollstore://install?url=\(selectedApp.ipaUrl)"
        
        if let url = URL(string: trollStoreUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func runClicked(_ sender: UIButton) {
        guard sender.tag < displayedApps.count else { return }
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