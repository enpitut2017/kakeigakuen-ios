//
//  SignUpViewController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/05.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var register :UIButton!
    
    @IBOutlet weak var name :UITextField!
    
    @IBOutlet weak var email :UITextField!
    
    @IBOutlet weak var password :UITextField!
    
    @IBOutlet weak var password_conf :UITextField!
    
    @IBOutlet weak var budget :UITextField!
    
    //UITextFieldの情報を格納するための変数
    var txtActiveField = UITextField()
    @IBOutlet weak var sc: UIScrollView!
    var scrollFormer:CGFloat! = nil
    let scrollViewsample = UIScrollView()
    
    var timer :Timer!
    
    var nameb :Bool = false
    var emailb :Bool = false
    var passb :Bool = false
    var passconb :Bool = false
    var budb :Bool = false
    
    public enum Keychain: String {
        // キー名
        case kakeiToken = "accessToken"
        case kakeiBudget = "userBudget"
        case kakeiRest = "userRest"
        
        // データの削除
        public func del() {
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.rawValue as AnyObject,
                ]
            let status_del : OSStatus = SecItemDelete(query as CFDictionary)
            if status_del != noErr {
                print("ERROR(del)=\(status_del)")
            }
        }
        
        //データの保存
        public func set(_ value: String) {
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.rawValue as AnyObject,
                kSecValueData as String: value.data(using: .utf8)! as AnyObject
            ]
            SecItemDelete(query as CFDictionary)
            let status : OSStatus = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                print("ERROR=\(status)")
            }
        }
        
        // データの取り出し
        public func value() -> String? {
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.rawValue as AnyObject,
                kSecReturnData as String: kCFBooleanTrue,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            guard status == noErr else {
                return nil
            }
            guard let data = result as? Data else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    }
    
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        
        var txtLimit = txtActiveField.frame.origin.y + txtActiveField.frame.height + 50.0
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height

        if txtLimit >= kbdLimit {
            sc.contentOffset.y = txtLimit - kbdLimit
        }
    }
    
    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        //スクロールしてある位置に戻す
        sc.contentOffset.y = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let nc = NotificationCenter.default
        nc.addObserver(
            self, selector:
            #selector(LoginViewController.handleKeyboardWillShowNotification(_:)),
            name: Notification.Name.UIKeyboardWillShow,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(LoginViewController.handleKeyboardWillHideNotification(_:)),
            name: Notification.Name.UIKeyboardWillHide,
            object: nil
        )
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sc.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0)
        sc.delegate = self as? UIScrollViewDelegate
        
        //sc.contentSize = CGSize(width: 250,height: 1000)
        //self.view.addSubview(sc);
        
        // Viewに追加する
        sc.addSubview(email)
        sc.addSubview(password)
        sc.addSubview(name)
        sc.addSubview(password_conf)
        sc.addSubview(budget)

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.checkColor), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    var filled :Int = 0
    @objc func checkColor() {
        if (name.text != "" && !nameb) {
            filled += 1
            nameb = true
        }
        
        if(email.text != "" && !emailb) {
            filled += 1
            emailb = true
        }
        
        if (password.text != "" && !passb){
            filled += 1
            passb = true
        }
        
        if (password_conf.text != "" && !passconb) {
            filled += 1
            passconb = true
        }
        
        if (budget.text != "" && !budb) {
            filled += 1
            budb = true
        }
        if(name.text == "" && nameb) {
            filled -= 1
            nameb = false
        }
        
        if (email.text == "" && emailb) {
            filled -= 1
            emailb = false
        }
        
        if (password.text == "" && passb) {
            filled -= 1
            passb = false
        }
        
        if (password_conf.text == "" && passconb) {
            filled -= 1
            passconb = false
        }
        
        if(budget.text == "" && budb) {
            filled -= 1
            budb = false
        }
        
        if(filled >= 5) {
            register.backgroundColor = #colorLiteral(red: 0.2047508657, green: 0.7041116357, blue: 0.6483085752, alpha: 1)
        } else {
            register.backgroundColor = #colorLiteral(red: 0.709620595, green: 0.7137866616, blue: 0.7136848569, alpha: 1)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //UITextFieldが編集された直後に呼ばれる.
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        txtActiveField = textField
        return true
    }
    
    //returnが押されたら呼ばれる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    //画面をタッチしたら呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
