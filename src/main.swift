import UIKit
import Foundation

class MainViewController: UIViewController, UITextViewDelegate {
    
    // UI Elements
    var codeEditor: UITextView!
    var consoleView: UITextView!
    
    // Panels & Containers
    var topBar: UIView!
    var consoleContainer: UIView!
    
    // Buttons
    var runButton: UIButton!
    var clearButton: UIButton!
    var fullScreenButton: UIButton!
    var toggleConsoleButton: UIButton!
    var settingsButton: UIButton!
    
    // Constraints để Thay đổi Layout động
    var editorBottomConstraint: NSLayoutConstraint!
    var consoleHeightConstraint: NSLayoutConstraint!
    
    // State Variables
    var isFullScreen = false
    var isConsoleHidden = false
    
    // Settings (Cấu hình kích thước và màu sắc tô cú pháp)
    var editorFontSize: CGFloat = 14.0
    var keywordColor: UIColor = .systemPink      // def, class, return, import, if...
    var stringColor: UIColor = .systemOrange     // "string" hoặc 'string'
    var commentColor: UIColor = .systemGreen     // # comment
    var builtinColor: UIColor = .systemCyan      // print, len, range, int...
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        
        setupTopBar()
        setupConsoleContainer()
        setupCodeEditor()
        
        // Code mồi Python 3 chuẩn để test tô màu cú pháp
        codeEditor.text = """
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
        
        // Khởi chạy tô màu cú pháp lần đầu
        highlightSyntax()
    }
    
    // --- 1. THANH ĐIỀU HƯỚNG TOP BAR (THAY THẾ BANNER) ---
    func setupTopBar() {
        topBar = UIView()
        topBar.translatesAutoresizingMaskIntoConstraints = false
        topBar.backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        view.addSubview(topBar)
        
        // Khởi tạo các nút chức năng gọn gàng trên một hàng
        runButton = createBarButton(title: "▶ RUN", color: .systemCyan, action: #selector(runCodeClicked))
        clearButton = createBarButton(title: "CLR", color: .systemOrange, action: #selector(clearConsoleClicked))
        fullScreenButton = createBarButton(title: "⛶ FULL", color: .white, action: #selector(toggleFullScreen))
        toggleConsoleButton = createBarButton(title: "± TERM", color: .systemGreen, action: #selector(toggleConsole))
        settingsButton = createBarButton(title: "⚙ SET", color: .lightGray, action: #selector(openSettings))
        
        let stackView = UIStackView(arrangedSubviews: [runButton, clearButton, fullScreenButton, toggleConsoleButton, settingsButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        topBar.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 45),
            
            stackView.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 5),
            stackView.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -5)
        ])
    }
    
    // --- 5. KHUNG CHỨA CONSOLE (ĐỂ ẨN/HIỆN ĐỒNG BỘ) ---
    func setupConsoleContainer() {
        consoleContainer = UIView()
        consoleContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(consoleContainer)
        
        consoleView = UITextView()
        consoleView.translatesAutoresizingMaskIntoConstraints = false
        consoleView.backgroundColor = .black
        consoleView.textColor = .lightGray
        consoleView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        consoleView.layer.borderWidth = 1
        consoleView.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.2).cgColor
        consoleView.isEditable = false
        consoleContainer.addSubview(consoleView)
        
        consoleHeightConstraint = consoleContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3)
        
        NSLayoutConstraint.activate([
            consoleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            consoleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            consoleContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            consoleHeightConstraint,
            
            consoleView.topAnchor.constraint(equalTo: consoleContainer.topAnchor),
            consoleView.leadingAnchor.constraint(equalTo: consoleContainer.leadingAnchor),
            consoleView.trailingAnchor.constraint(equalTo: consoleContainer.trailingAnchor),
            consoleView.bottomAnchor.constraint(equalTo: consoleContainer.bottomAnchor)
        ])
        
        consoleView.text = "SYSTEM: Terminal Ready.\n"
    }
    
    // --- KHU VỰC KHUNG CODE EDITOR ---
    func setupCodeEditor() {
        codeEditor = UITextView()
        codeEditor.translatesAutoresizingMaskIntoConstraints = false
        codeEditor.backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        codeEditor.font = UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
        codeEditor.layer.borderWidth = 1
        codeEditor.layer.borderColor = UIColor.darkGray.cgColor
        codeEditor.delegate = self
        
        // Tắt sửa từ để dev mượt mà
        codeEditor.autocapitalizationType = .none
        codeEditor.autocorrectionType = .no
        codeEditor.smartQuotesType = .no
        codeEditor.smartDashesType = .no
        
        view.addSubview(codeEditor)
        
        // Tạo liên kết ràng buộc động giữa Editor và Console
        editorBottomConstraint = codeEditor.bottomAnchor.constraint(equalTo: consoleContainer.topAnchor, constant: -10)
        
        NSLayoutConstraint.activate([
            codeEditor.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            codeEditor.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            codeEditor.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            editorBottomConstraint
        ])
    }
    
    // --- 3. BỘ TÔ MÀU CÚ PHÁP PYTHON 3 (SYNTAX HIGHLIGHTING) ---
    func highlightSyntax() {
        guard let text = codeEditor.text else { return }
        
        // Lưu lại vị trí con trỏ hiện tại để tránh bị nhảy sau khi áp dụng thuộc tính chữ mới
        let selectedRange = codeEditor.selectedRange
        
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Reset định dạng mặc định (Chữ trắng, font Monospace)
        attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: editorFontSize, weight: .regular), range: fullRange)
        
        // Định nghĩa các mẫu Regex cho Python 3
        let patterns: [(String, UIColor)] = [
            // Từ khóa hệ thống (Keywords)
            ("\\b(def|class|return|import|from|if|elif|else|for|while|in|is|and|or|not|as|pass|break|continue|try|except|lambda|global|with|None|True|False)\\b", keywordColor),
            // Các hàm tích hợp sẵn cơ bản (Builtins)
            ("\\b(print|len|range|str|int|float|list|dict|set|tuple|open|append|type|abs|enumerate)\\b", builtinColor),
            // Chuỗi ký tự (Strings) - Bao gồm nháy kép và nháy đơn
            ("(\"[^\"]*\"|'[^']*')", stringColor),
            // Các dòng chú thích (Comments) bắt đầu bằng dấu #
            ("#.*", commentColor)
        ]
        
        // Quét từng mẫu Regex để nhuộm màu text
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }
        }
        
        codeEditor.attributedText = attributedString
        codeEditor.selectedRange = selectedRange // Khôi phục lại con trỏ chuột
    }
    
    // Bắt sự kiện thay đổi text khi người dùng đang gõ phím để tô màu thời gian thực
    func textViewDidChange(_ textView: UITextView) {
        highlightSyntax()
    }
    
    // --- 2. LOGIC NÚT FULL MÀN HÌNH KHUNG CODE ---
    @objc func toggleFullScreen() {
        isFullScreen.toggle()
        
        UIView.animate(withDuration: 0.2) {
            if self.isFullScreen {
                // Khi Full màn hình: Ẩn terminal và ép editor tràn sát đáy app
                self.consoleContainer.alpha = 0.0
                self.editorBottomConstraint.isActive = false
                self.editorBottomConstraint = self.codeEditor.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
                self.editorBottomConstraint.isActive = true
                self.fullScreenButton.setTitle("⛶ REST", for: .normal)
            } else {
                // Trở lại trạng thái bình thường dựa theo việc terminal có đang bị ẩn hay không
                self.consoleContainer.alpha = self.isConsoleHidden ? 0.0 : 1.0
                self.editorBottomConstraint.isActive = false
                self.editorBottomConstraint = self.codeEditor.bottomAnchor.constraint(equalTo: self.consoleContainer.topAnchor, constant: -10)
                self.editorBottomConstraint.isActive = true
                self.fullScreenButton.setTitle("⛶ FULL", for: .normal)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    // --- 5. LOGIC ẨN / HIỆN CONSOLE ---
    @objc func toggleConsole() {
        if isFullScreen { return } // Đang full màn hình thì không cần ẩn hiện nút phụ này
        
        isConsoleHidden.toggle()
        
        UIView.animate(withDuration: 0.2) {
            if self.isConsoleHidden {
                self.consoleContainer.alpha = 0.0
                self.consoleHeightConstraint.isActive = false
                self.consoleHeightConstraint = self.consoleContainer.heightAnchor.constraint(equalToConstant: 0)
                self.consoleHeightConstraint.isActive = true
                self.toggleConsoleButton.setTitle("➕ TERM", for: .normal)
            } else {
                self.consoleContainer.alpha = 1.0
                self.consoleHeightConstraint.isActive = false
                self.consoleHeightConstraint = self.consoleContainer.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 0.3)
                self.consoleHeightConstraint.isActive = true
                self.toggleConsoleButton.setTitle("➖ TERM", for: .normal)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    // --- 4. CÀI ĐẶT (SETTINGS) THAY ĐỔI CỠ CHỮ & MÀU TÔ CÚ PHÁP ---
    @objc func openSettings() {
        let alert = UIAlertController(title: "⚙ Settings", message: "Tùy chỉnh cấu hình Empty Studio Engine", preferredStyle: .actionSheet)
        
        // Tăng/Giảm cỡ chữ
        alert.addAction(UIAlertAction(title: "Cỡ chữ lớn hơn (+2)", style: .default, handler: { _ in
            self.editorFontSize += 2
            self.highlightSyntax()
        }))
        alert.addAction(UIAlertAction(title: "Cỡ chữ nhỏ hơn (-2)", style: .default, handler: { _ in
            if self.editorFontSize > 10 { self.editorFontSize -= 2 }
            self.highlightSyntax()
        }))
        
        // Đổi bộ Palette màu sắc (Theme) nhanh
        alert.addAction(UIAlertAction(title: "Theme Retro Hacker (Green/Cyan)", style: .default, handler: { _ in
            self.keywordColor = .systemGreen
            self.builtinColor = .cyan
            self.stringColor = .white
            self.highlightSyntax()
        }))
        
        alert.addAction(UIAlertAction(title: "Theme Cyberpunk (Pink/Orange)", style: .default, handler: { _ in
            self.keywordColor = .systemPink
            self.builtinColor = .systemCyan
            self.stringColor = .systemOrange
            self.highlightSyntax()
        }))
        
        alert.addAction(UIAlertAction(title: "Đóng", style: .cancel, handler: nil))
        
        // Hỗ trợ hiển thị trên cả iPad nếu cần
        if let popover = alert.popoverPresentationController {
            popover.sourceView = settingsButton
            popover.sourceRect = settingsButton.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    // --- LOGIC PHỤ TRỢ ---
    @objc func runCodeClicked() {
        consoleView.text += "$ python3 execution simulated...\n[Success] Output matches workspace state.\n"
    }
    
    @objc func clearConsoleClicked() {
        consoleView.text = "SYSTEM: Console cleared.\n"
    }
    
    func createBarButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.5).cgColor
        button.layer.cornerRadius = 4
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}