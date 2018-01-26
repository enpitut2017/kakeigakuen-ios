//
//  LoginViewController.swift
//  kakei-chan-agent-ios
//
//  Created by masamune kobayashi on 2017/12/07.
//  Copyright © 2017年 masamune kobayashi. All rights reserved.
//

import Foundation
import Security
import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBAction func kakei_login() {
        // textfieldの値を取得
        let user_email = email.text
        let user_password = password.text
        
        // 取得したJSONを格納する変数を定義
        var getJson: NSDictionary!
        var kakei_token = ""
        var kakei_budget = 0
        
        // API接続先
        //let urlStr = "https://kakeigakuen.xyz/api/login/"
        let urlStr = "http://localhost:3000/api/login"
        if let url = URL(string: urlStr) {
            let req = NSMutableURLRequest(url: url)
            // select http method
            req.httpMethod = "POST"
            // set the header(s)
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // set the request-body(JSON)
            let params = [
                "email"     : user_email,
                "password"  : user_password,
                ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
            
            let task = URLSession.shared.dataTask(with: req as URLRequest, completionHandler: { (data, resp, err) in
                print(resp!.url!)
                print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as Any)
                
                // JSONパース
                do {
                    getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    
                    kakei_token = (getJson["token"] as? String)!
                    kakei_budget = (getJson["budget"] as? Int)!
                    DispatchQueue.main.async{
                        self.label.numberOfLines = 2
                        if (kakei_token == "error") {
                            self.label.text = "ログインに失敗"
                        } else {
                            segueToHome()
                        }
                    }
                    
                    // token, budgetを保存する
                    Keychain.kakeiToken.set(kakei_token)
                    Keychain.kakeiBudget.set("\(kakei_budget)")
                    
                    // ホーム画面に遷移(仮)
                    func segueToHome() {
                        self.performSegue(withIdentifier: "toHomeSegue", sender: nil)
                    }

                } catch {
                    DispatchQueue.main.async(execute: {
                        self.label.text = "ログインに失敗"
                    })
                    return
                }
            })
            task.resume()
        }
    }
    
    public enum Keychain: String {
        // キー名
        case kakeiToken = "accessToken"
        case kakeiBudget = "userBudget"
        
        // データの保存
        public func set(_ value: String) {
            let query: [String: AnyObject] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.rawValue as AnyObject,
                kSecValueData as String: value.data(using: .utf8)! as AnyObject
            ]
            let status_del : OSStatus = SecItemDelete(query as CFDictionary)
            let status_save : OSStatus = SecItemAdd(query as CFDictionary, nil)
            if status_del != noErr {
                print("ERROR(del)=\(status_del)")
            }
            if status_save != noErr {
                print("ERROR(save)=\(status_save)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
