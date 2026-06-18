import UIKit
import Foundation

class MainViewController: UIViewController, UITextViewDelegate {
    
    var bannerLabel: UILabel!
    var codeEditor: UITextView!
    var consoleView: UITextView!
    var runButton: UIButton!
    var clearButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupHeaderBanner()
        setupActionButtons()
        setupCodeEditor()
        setupConsoleView()
        
        // Đoạn code mồi mặc định khi mở app
        codeEditor.text = """
        // Empty Studio IDE v1.0.0
        // Sẵn sàng viết app và package cho BlueOS / EmptyOS
        
        print("Hello, Empty Studio!")
        """
    }
    
    // --- GIAO DIỆN RETRO PIXEL BANNER ---
    func setupHeaderBanner() {
        bannerLabel = UILabel()
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        bannerLabel.textColor = .green
        bannerLabel.numberOfLines = 0
        bannerLabel.textAlignment = .left
        bannerLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .bold)
        bannerLabel.text = """
         _____ __  __ ____ _____   __  ____ _____ _   _ ____ ___ ___  
        | ____|  \\/  |  _ \\_   _\\  \\ \\/ ___|_   _| | | |  _ \\_ _/ _ \\ 
        |  _| | |\\/| | |_) || |_____\\  \\___ \\ | | | | | | | | | | | | |
        | |___| |  | |  __/ | |_____/  /___) || | | |_| | |_| | | |_| |
        |_____|_|  |_|_|    |_|    /_/|____/ |_|  \\___/|____/___\\___/ 
        =================== DEVELOPMENT ENVIRONMENT ===================
        """
        view.addSubview(bannerLabel)
        
        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            bannerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            bannerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15)
        ])
    }
    
    // --- CÁC NÚT ĐIỀU KHIỂN LỆNH ---
    func setupActionButtons() {
        runButton = UIButton(type: .system)
        runButton.translatesAutoresizingMaskIntoConstraints = false
        runButton.setTitle("[ RUN > ]", for: .normal)
        runButton.setTitleColor(.cyan, for: .normal)
        runButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        runButton.layer.borderWidth = 1
        runButton.layer.borderColor = UIColor.cyan.cgColor
        runButton.layer.cornerRadius = 4
        runButton.addTarget(self, action: #selector(runCodeClicked), for: .touchUpInside)
        
        clearButton = UIButton(type: .system)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setTitle("[ CLEAR ]", for: .normal)
        clearButton.setTitleColor(.orange, for: .normal)
        clearButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        clearButton.layer.borderWidth = 1
        clearButton.layer.borderColor = UIColor.orange.cgColor
        clearButton.layer.cornerRadius = 4
        clearButton.addTarget(self, action: #selector(clearConsoleClicked), for: .touchUpInside)
        
        view.addSubview(runButton)
        view.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            runButton.topAnchor.constraint(equalTo: bannerLabel.bottomAnchor, constant: 12),
            runButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            runButton.widthAnchor.constraint(equalToConstant: 100),
            runButton.heightAnchor.constraint(equalToConstant: 35),
            
            clearButton.topAnchor.constraint(equalTo: bannerLabel.bottomAnchor, constant: 12),
            clearButton.leadingAnchor.constraint(equalTo: runButton.trailingAnchor, constant: 15),
            clearButton.widthAnchor.constraint(equalToConstant: 100),
            clearButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    // --- KHU VỰC VIẾT CODE ---
    func setupCodeEditor() {
        codeEditor = UITextView()
        codeEditor.translatesAutoresizingMaskIntoConstraints = false
        codeEditor.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        codeEditor.textColor = .white
        codeEditor.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        codeEditor.layer.borderWidth = 1
        codeEditor.layer.borderColor = UIColor.darkGray.cgColor
        codeEditor.autocapitalizationType = .none
        codeEditor.autocorrectionType = .no
        codeEditor.smartQuotesType = .no
        codeEditor.smartDashesType = .no
        codeEditor.keyboardType = .asciiCapable
        
        view.addSubview(codeEditor)
        
        NSLayoutConstraint.activate([
            codeEditor.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 12),
            codeEditor.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            codeEditor.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            codeEditor.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ])
    }
    
    // --- MÀN HÌNH CONSOLE HIỂN THỊ KẾT QUẢ ---
    func setupConsoleView() {
        consoleView = UITextView()
        consoleView.translatesAutoresizingMaskIntoConstraints = false
        consoleView.backgroundColor = .black
        consoleView.textColor = .lightGray
        consoleView.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        consoleView.layer.borderWidth = 1
        consoleView.layer.borderColor = UIColor.green.withAlphaComponent(0.3).cgColor
        consoleView.isEditable = false
        
        view.addSubview(consoleView)
        
        NSLayoutConstraint.activate([
            consoleView.topAnchor.constraint(equalTo: codeEditor.bottomAnchor, constant: 12),
            consoleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            consoleView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            consoleView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        consoleView.text = "SYSTEM: Terminal initialized. Awaiting commands...\n"
    }
    
    // --- LOGIC XỬ LÝ BIÊN DỊCH / THỰC THI CHẠY CODE ---
    @objc func runCodeClicked(_ sender: UIButton) {
        guard let sourceCode = codeEditor.text, !sourceCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            appendLog(text: "[⚠️] Không có mã nguồn để thực thi.")
            return
        }
        
        appendLog(text: "\n$ executing sandbox code...")
        
        // Tạm thời tạo bộ giả lập bắt log thực thi nội bộ (Sẽ kết nối trực tiếp với iSH / Lõi Thông dịch sau)
        let interpreterOutput = mockExecute(code: sourceCode)
        appendLog(text: interpreterOutput)
    }
    
    @objc func clearConsoleClicked(_ sender: UIButton) {
        consoleView.text = "SYSTEM: Console cleared.\n"
    }
    
    func appendLog(text: String) {
        consoleView.text += text + "\n"
        let bottom = NSMakeRange(consoleView.text.count - 1, 1)
        consoleView.scrollRangeToVisible(bottom)
    }
    
    // Lõi giả lập thực thi - Nơi tụi mình sẽ nạp bộ thông dịch blueScript hoặc gá lệnh hệ thống
    func mockExecute(code: String) -> String {
        if code.contains("print(") {
            // Tách chuỗi cơ bản để lấy text bên trong hàm print
            if let start = code.range(of: "print(\""), let end = code.range(of: "\")") {
                let content = code[start.upperBound..<end.lowerBound]
                return String(content)
            }
        }
        return "Core: Mã nguồn đã được nạp thành công nhưng chưa kết nối trình biên dịch chính thức."
    }
}

// --- VÒNG ĐỜI KHỞI CHẠY ỨNG DỤNG ---
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