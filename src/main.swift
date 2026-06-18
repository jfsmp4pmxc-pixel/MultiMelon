import UIKit
import Foundation

class MainViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate {
    
    // UI Elements
    var codeEditor: UITextView?
    var lineCounterView: UITextView? // Cột đếm số dòng
    var consoleView: UITextView?
    var topBar: UIView?
    var consoleContainer: UIView?
    
    var runButton: UIButton?
    var clearButton: UIButton?
    var fullScreenButton: UIButton?
    var toggleConsoleButton: UIButton?
    var settingsButton: UIButton?
    
    var editorBottomConstraint: NSLayoutConstraint?
    var consoleHeightConstraint: NSLayoutConstraint?
    
    var isFullScreen = false
    var isConsoleHidden = false
    
    // ==========================================
    // 🎨 1. BẢNG MÀU CÚ PHÁP (ĐỔI MÀU TÙY THÍCH TẠI ĐÂY)
    // ==========================================
    var editorFontSize: CGFloat = 14.0
    
    // Bạn có thể dùng các màu mặc định của iOS hoặc tạo màu UIColor(red:green:blue:alpha:) tùy ý
    var keywordColor: UIColor = .systemPink      // def, class, return, if, for...
    var builtinColor: UIColor = .systemCyan      // print, len, range, str, int...
    var stringColor: UIColor = .systemOrange     // "chuỗi ký tự" hoặc 'chuỗi'
    var commentColor: UIColor = .systemGreen     // # các dòng ghi chú
    var numberColor: UIColor = .systemPurple     // Số nguyên, số thực (0-9)
    var decoratorColor: UIColor = .systemYellow   // @classmethod, @staticmethod...
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        
        setupTopBar()
        setupConsoleContainer()
        setupCodeEditor()
        
        let defaultCode = """
        # Empty Studio IDE - Python 3 Mode
        import os
        
        @print_decor
        def hello_world():
            msg = "Hello from Empty Studio!"
            count = 100
            print(msg)
            
            for i in range(3):
                print(f"Loop count: {i}")
        
        if __name__ == "__main__":
            hello_world()
        """
        
        if let editor = codeEditor {
            editor.text = defaultCode
            highlightSyntax()
            updateLineNumbers()
        }
    }
    
    func setupTopBar() {
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.addSubview(bar)
        self.topBar = bar
        
        runButton = createBarButton(title: "▶ RUN", color: .systemCyan, action: #selector(runCodeClicked))
        clearButton = createBarButton(title: "CLR", color: .systemOrange, action: #selector(clearConsoleClicked))
        fullScreenButton = createBarButton(title: "⛶ FULL", color: .white, action: #selector(toggleFullScreen))
        toggleConsoleButton = createBarButton(title: "± TERM", color: .systemGreen, action: #selector(toggleConsole))
        settingsButton = createBarButton(title: "⚙ SET", color: .lightGray, action: #selector(openSettings))
        
        let buttons = [runButton, clearButton, fullScreenButton, toggleConsoleButton, settingsButton].compactMap { $0 }
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 6
        bar.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 45),
            
            stackView.topAnchor.constraint(equalTo: bar.topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -5)
        ])
    }
    
    func setupConsoleContainer() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        self.consoleContainer = container
        
        let cView = UITextView()
        cView.translatesAutoresizingMaskIntoConstraints = false
        cView.backgroundColor = .black
        cView.textColor = .lightGray
        cView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        cView.layer.borderWidth = 1
        cView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        cView.isEditable = false
        container.addSubview(cView)
        self.consoleView = cView
        
        let hConstraint = container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        hConstraint.isActive = true
        self.consoleHeightConstraint = hConstraint
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            
            cView.topAnchor.constraint(equalTo: container.topAnchor),
            cView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        cView.text = "SYSTEM: Terminal Ready.\n"
    }
    
    func setupCodeEditor() {
        guard let bar = topBar, let container = consoleContainer else { return }
        
        // Khung nền chứa cả cột đếm dòng và khung viết code
        let editorContainer = UIView()
        editorContainer.translatesAutoresizingMaskIntoConstraints = false
        editorContainer.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        editorContainer.layer.borderWidth = 1
        editorContainer.layer.borderColor = UIColor.darkGray.cgColor
        view.addSubview(editorContainer)
        
        // 2. KHỞI TẠO CỘT ĐẾM DÒNG (Line Counter)
        let counter = UITextView()
        counter.translatesAutoresizingMaskIntoConstraints = false
        counter.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        counter.textColor = .darkGray
        counter.font = UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        counter.textAlignment = .right
        counter.isEditable = false
        counter.isSelectable = false
        counter.isScrollEnabled = false // Sẽ bị cuộn động theo Editor chính
        counter.textContainerInset = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 5)
        editorContainer.addSubview(counter)
        self.lineCounterView = counter
        
        // KHỞI TẠO KHUNG CODE EDITOR CHÍNH
        let editor = UITextView()
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.backgroundColor = .clear
        editor.textColor = .white
        editor.font = UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        editor.delegate = self
        editor.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        
        editor.autocapitalizationType = .none
        editor.autocorrectionType = .no
        editor.smartQuotesType = .no
        editor.smartDashesType = .no
        
        editorContainer.addSubview(editor)
        self.codeEditor = editor
        
        // Ràng buộc vị trí động của Editor Container với Terminal
        let bConstraint = editorContainer.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -10)
        bConstraint.isActive = true
        self.editorBottomConstraint = bConstraint
        
        NSLayoutConstraint.activate([
            editorContainer.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 10),
            editorContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            editorContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            // Cột đếm dòng rộng 35pt bám bên trái
            counter.topAnchor.constraint(equalTo: editorContainer.topAnchor),
            counter.leadingAnchor.constraint(equalTo: editorContainer.leadingAnchor),
            counter.bottomAnchor.constraint(equalTo: editorContainer.bottomAnchor),
            counter.widthAnchor.constraint(equalToConstant: 35),
            
            // Khung Editor chiếm phần diện tích còn lại bám bên phải
            editor.topAnchor.constraint(equalTo: editorContainer.topAnchor),
            editor.leadingAnchor.constraint(equalTo: counter.trailingAnchor),
            editor.trailingAnchor.constraint(equalTo: editorContainer.trailingAnchor),
            editor.bottomAnchor.constraint(equalTo: editorContainer.bottomAnchor)
        ])
    }
    
    // ==========================================
    // 🎨 HÀM TÔ MÀU CÚ PHÁP PYTHON 3 CHI TIẾT
    // ==========================================
    func highlightSyntax() {
        guard let editor = codeEditor, let text = editor.text else { return }
        
        let selectedRange = editor.selectedRange
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Định dạng text gốc ban đầu
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular), range: fullRange)
        
        // Các mẫu quét Regex chi tiết (Thêm số và bộ Decorator @)
        let patterns: [(String, UIColor)] = [
            // Keywords
            (#"\b(def|class|return|import|from|if|elif|else|for|while|in|is|and|or|not|as|pass|break|continue|try|except|lambda|global|with|None|True|False)\b"#, keywordColor),
            // Builtins
            (#"\b(print|len|range|str|int|float|list|dict|set|tuple|open|append|type|abs|enumerate)\\b"#, builtinColor),
            // Số (Numbers)
            (#"\b(\d+)\b"#, numberColor),
            // Bộ trang trí (Decorators) như @classmethod
            (#"@[a-zA-Z_][a-zA-Z0-9_]*"#, decoratorColor),
            // Chuỗi ký tự (Strings)
            (#"("[^"]*"|'[^']*')"#, stringColor),
            // Chú thích (Comments)
            (#"#.*"#, commentColor)
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }
        }
        
        editor.delegate = nil
        editor.attributedText = attributedString
        editor.delegate = self
        editor.selectedRange = selectedRange
    }
    
    // ==========================================
    // 🔢 HÀM XỬ LÝ ĐẾM DÒNG (LINE NUMBERS)
    // ==========================================
    func updateLineNumbers() {
        guard let editor = codeEditor, let counter = lineCounterView else { return }
        
        // Đếm số ký tự xuống dòng '\n' trong code editor
        let components = editor.text.components(separatedBy: "\n")
        let count = components.count
        
        var numberString = ""
        for i in 1...count {
            numberString += "\(i)\n"
        }
        
        counter.text = numberString
        
        // Đồng bộ font chữ của thước đo khớp hoàn toàn với Editor chính
        counter.font = UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        
        // Đồng bộ lại vị trí cuộn
        alignLineNumbersScroll()
    }
    
    // Bắt sự kiện cuộn màn hình để dịch chuyển cột số dòng tương xứng
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == codeEditor {
            alignLineNumbersScroll()
        }
    }
    
    func alignLineNumbersScroll() {
        guard let editor = codeEditor, let counter = lineCounterView else { return }
        counter.contentOffset.y = editor.contentOffset.y
    }
    
    func textViewDidChange(_ textView: UITextView) {
        highlightSyntax()
        updateLineNumbers() // Kích hoạt đếm lại dòng khi có thay đổi ký tự văn bản
    }
    
    // --- LAYOUT VÀ SWITCH CHỨC NĂNG ---
    @objc func toggleFullScreen() {
        guard let container = consoleContainer, let editorView = codeEditor?.superview else { return }
        isFullScreen.toggle()
        
        UIView.animate(withDuration: 0.2) {
            self.editorBottomConstraint?.isActive = false
            if self.isFullScreen {
                container.alpha = 0.0
                self.editorBottomConstraint = editorView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
                self.fullScreenButton?.setTitle("⛶ REST", for: .normal)
            } else {
                container.alpha = self.isConsoleHidden ? 0.0 : 1.0
                self.editorBottomConstraint = editorView.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -10)
                self.fullScreenButton?.setTitle("⛶ FULL", for: .normal)
            }
            self.editorBottomConstraint?.isActive = true
            self.view.layoutIfNeeded()
            self.alignLineNumbersScroll()
        }
    }
    
    @objc func toggleConsole() {
        if isFullScreen { return }
        guard let container = consoleContainer else { return }
        isConsoleHidden.toggle()
        
        UIView.animate(withDuration: 0.2) {
            self.consoleHeightConstraint?.isActive = false
            if self.isConsoleHidden {
                container.alpha = 0.0
                self.consoleHeightConstraint = container.heightAnchor.constraint(equalToConstant: 0)
                self.toggleConsoleButton?.setTitle("➕ TERM", for: .normal)
            } else {
                container.alpha = 1.0
                self.consoleHeightConstraint = container.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.3)
                self.toggleConsoleButton?.setTitle("➖ TERM", for: .normal)
            }
            self.consoleHeightConstraint?.isActive = true
            self.view.layoutIfNeeded()
            self.alignLineNumbersScroll()
        }
    }
    
    @objc func openSettings() {
        let alert = UIAlertController(title: "⚙ Settings", message: "Cấu hình Editor", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cỡ chữ lớn (+2)", style: .default, handler: { _ in
            self.editorFontSize += 2
            self.highlightSyntax()
            self.updateLineNumbers()
        }))
        alert.addAction(UIAlertAction(title: "Cỡ chữ nhỏ (-2)", style: .default, handler: { _ in
            if self.editorFontSize > 10 {
                self.editorFontSize -= 2
                self.highlightSyntax()
                self.updateLineNumbers()
            }
        }))
        alert.addAction(UIAlertAction(title: "Theme Gốc (Cyberpunk Pink)", style: .default, handler: { _ in
            self.keywordColor = .systemPink
            self.builtinColor = .systemCyan
            self.stringColor = .systemOrange
            self.highlightSyntax()
        }))
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel, handler: nil))
        
        if let popover = alert.popoverPresentationController, let btn = settingsButton {
            popover.sourceView = btn
            popover.sourceRect = btn.bounds
        }
        present(alert, animated: true, completion: nil)
    }
    
    @objc func runCodeClicked() {
        consoleView?.text += "$ python3 executing...\n[Success] Sandbox environment stable.\n"
    }
    
    @objc func clearConsoleClicked() {
        consoleView?.text = "SYSTEM: Console cleared.\n"
    }
    
    func createBarButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.4).cgColor
        button.layer.cornerRadius = 4
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

// --- APP LIFECYCLE ---
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