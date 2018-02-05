//
//  GraphViewController.swift
//  
//
//  Created by 赤坂勝哉 on 2018/02/04.
//

import UIKit

class GraphViewController: UIViewController {

    @IBOutlet weak var MonthLabel :UILabel!

    
    //トークン設定
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
    
    //ログアウト関数
    @IBAction func Logout(_ sender: Any) {
        Keychain.kakeiToken.del()
        Keychain.kakeiBudget.del()
        Keychain.kakeiRest.del()
        goLogin()
    }
    
    func goLogin(){
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView")
        self.present(nextView, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nowDate = NSDate()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy年MM月"
        MonthLabel.text = dateFormat.string(from: nowDate as Date)
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
