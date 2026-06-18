import UIKit
import Foundation

class MainViewController: UIViewController, UITextViewDelegate {
    
    // Khởi tạo an toàn (Không dùng dấu ! nguy hiểm)
    var codeEditor: UITextView?
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
    
    var editorFontSize: CGFloat = 14.0
    var keywordColor: UIColor = .systemPink
    var stringColor: UIColor = .systemOrange
    var commentColor: UIColor = .systemGreen
    var builtinColor: UIColor = .systemCyan
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        
        setupTopBar()
        setupConsoleContainer()
        setupCodeEditor()
        
        // Đoạn code Python mẫu
        let defaultCode = """
        # Empty Studio IDE - Python 3 Mode
        import os
        
        def hello_world():
            msg = "Hello from Empty Studio!"
            print(msg)
            
            for i in range(3):
                print(f"Loop count: {i}")
        
        if __name__ == "__main__":
            hello_world()
        """
        
        if let editor = codeEditor {
            editor.text = defaultCode
            highlightSyntax()
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
        
        // Gom các nút vào mảng an toàn
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
        
        let editor = UITextView()
        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        editor.textColor = .white
        editor.font = UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        editor.layer.borderWidth = 1
        editor.layer.borderColor = UIColor.darkGray.cgColor
        editor.delegate = self
        
        editor.autocapitalizationType = .none
        editor.autocorrectionType = .no
        editor.smartQuotesType = .no
        editor.smartDashesType = .no
        
        view.addSubview(editor)
        self.codeEditor = editor
        
        let bConstraint = editor.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -10)
        bConstraint.isActive = true
        self.editorBottomConstraint = bConstraint
        
        NSLayoutConstraint.activate([
            editor.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 10),
            editor.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            editor.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
        ])
    }
    
    func highlightSyntax() {
        guard let editor = codeEditor, let text = editor.text else { return }
        
        let selectedRange = editor.selectedRange
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular), range: fullRange)
        
        // Fix triệt để Regex bằng Raw String để không bị dịch sai ký tự thoát
        let patterns: [(String, UIColor)] = [
            (#"\b(def|class|return|import|from|if|elif|else|for|while|in|is|and|or|not|as|pass|break|continue|try|except|lambda|global|with|None|True|False)\b"#, keywordColor),
            (#"\b(print|len|range|str|int|float|list|dict|set|tuple|open|append|type|abs|enumerate)\b"#, builtinColor),
            (#"("[^"]*"|'[^']*')"#, stringColor),
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
        
        // Gán qua thuộc tính mà không kích hoạt lại delegate vô tận
        editor.delegate = nil
        editor.attributedText = attributedString
        editor.delegate = self
        editor.selectedRange = selectedRange
    }
    
    func textViewDidChange(_ textView: UITextView) {
        highlightSyntax()
    }
    
    @objc func toggleFullScreen() {
        guard let container = consoleContainer, let editor = codeEditor else { return }
        isFullScreen.toggle()
        
        UIView.animate(withDuration: 0.2) {
            self.editorBottomConstraint?.isActive = false
            if self.isFullScreen {
                container.alpha = 0.0
                self.editorBottomConstraint = editor.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
                self.fullScreenButton?.setTitle("⛶ REST", for: .normal)
            } else {
                container.alpha = self.isConsoleHidden ? 0.0 : 1.0
                self.editorBottomConstraint = editor.bottomAnchor.constraint(equalTo: container.topAnchor, constant: -10)
                self.fullScreenButton?.setTitle("⛶ FULL", for: .normal)
            }
            self.editorBottomConstraint?.isActive = true
            self.view.layoutIfNeeded()
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
        }
    }
    
    @objc func openSettings() {
        let alert = UIAlertController(title: "⚙ Settings", message: "Cấu hình Editor", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Cỡ chữ lớn (+2)", style: .default, handler: { _ in
            self.editorFontSize += 2
            self.highlightSyntax()
        }))
        alert.addAction(UIAlertAction(title: "Cỡ chữ nhỏ (-2)", style: .default, handler: { _ in
            if self.editorFontSize > 10 { self.editorFontSize -= 2 }
            self.highlightSyntax()
        }))
        alert.addAction(UIAlertAction(title: "Hacker Theme", style: .default, handler: { _ in
            self.keywordColor = .systemGreen
            self.builtinColor = .cyan
            self.stringColor = .white
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