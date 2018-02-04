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

class LoginViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButotn: UIButton!
    
    //UITextFieldの情報を格納するための変数
    var txtActiveField = UITextField()
    @IBOutlet weak var sc: UIScrollView!
    var scrollFormer:CGFloat! = nil
    let scrollViewsample = UIScrollView()
    
    @IBAction func kakei_login() {
        // textfieldの値を取得
        let user_email = email.text
        let user_password = password.text
        
        // 取得したJSONを格納する変数を定義
        var getJson: NSDictionary!
        var kakei_token = ""
        var kakei_budget = 0
        var kakei_rest = 0
        
        // API接続先
        let urlStr = "https://kakeigakuen.xyz/api/login/"
        //let urlStr = "http://localhost:3000/api/login"
        if let url = URL(string: urlStr) {
            if(user_email == "" || user_password == "") {
                self.label.text = "正しく入力してください"
            } else {
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
                    //print(resp!.url!)
                    //print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as Any)
                    
                    // JSONパース
                    do {
                        getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                        
                        kakei_token = (getJson["token"] as? String)!
                        kakei_budget = (getJson["budget"] as? Int)!
                        kakei_rest = (getJson["rest"] as? Int)!
                        DispatchQueue.main.async{
                            self.label.numberOfLines = 1
                            if (kakei_token == "error") {
                                self.label.text = "ログインに失敗"
                            } else {
                                segueToHome()
                            }
                        }
                        
                        // token, budgetを保存する
                        Keychain.kakeiToken.set(kakei_token)
                        Keychain.kakeiBudget.set("\(kakei_budget)")
                        Keychain.kakeiRest.set("\(kakei_rest)")
                        
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
    }
    
    public enum Keychain: String {
        // キー名
        case kakeiToken = "accessToken"
        case kakeiBudget = "userBudget"
        case kakeiRest = "userRest"
        
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
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        
        var txtLimit = txtActiveField.frame.origin.y + txtActiveField.frame.height + 50.0
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height
        
        
        print("テキストフィールドの下辺：(\(txtLimit))")
        print("キーボードの上辺：(\(kbdLimit))")
        
        
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
        self.email.delegate = self
        self.password.delegate = self
        
        //sc.frame = self.view.frame;
        sc.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0)
        sc.delegate = self
        
        //sc.contentSize = CGSize(width: 250,height: 1000)
        self.view.addSubview(sc);
        
        // Viewに追加する
        sc.addSubview(email)
        sc.addSubview(password)
        //sc.addSubview(self.view)
        self.view.bringSubview(toFront: loginButotn)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.register(defaults: ["latestDLImage": 0])
        let num = userDefaults.integer(forKey: "latestDLImage")
        
        let url = "https://kakeigakuen.xyz/api/image/download"
        var request = URLRequest(url: URL(string: url)! as URL)
        var dlimage:[String] = []
        
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        print(String(num))
        let params: [String: Any] = [
            "id" : num
        ]
        do{
            //json送信
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        }catch{
            print(error.localizedDescription)
        }
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print(error!.localizedDescription)
                DispatchQueue.main.sync(execute: {
                    print("error occered")
                })
                return
            }
            // JSONパースしてキーチェーンに新しいbudgetをセット
            do {
                let getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                DispatchQueue.main.async {
                    
                    print(String(describing: (type(of: getJson["path"]))))
                    dlimage = getJson["path"]! as! [String]
                }
            } catch {
                DispatchQueue.main.async(execute: {
                    print("failed to parse json")
                })
                return
            }
        }
        task.resume()

        
        
        
        let catPictureURL = URL(string: "http://i.imgur.com/w5rkSIj.jpg")!
        
        /*
         
         デフォルト設定でセッションオブジェクトを作成する。
         
         　　*/
        
        let session = URLSession(configuration: .default)
        /*
         
         ダウンロードタスクを定義します。ダウンロードタスクは、
         URLの内容をデータオブジェクトとしてダウンロードし、
         そのデータで望むことを実行できます。
         
         */
        let downloadPicTask = session.dataTask(with: catPictureURL) { (data, response, error) in
            /*
             ダウンロードが完了しました。
             */
            
            if let e = error {
                print("cat pictureのダウンロード中にエラーが発生しました: \(e)")
            } else {
                /*
                 エラーは見つかりませんでした。
                 レスポンスがないと変わってしまいますので、それもチェックしてください。
                 */
                if let res = response as? HTTPURLResponse {
                    print("レスポンスコード付きの猫の画像をダウンロード \(res.statusCode)")
                    if let imageData = data {
                        /*
                         最後に、そのデータをイメージに変換し、
                         それを使って望むことをします。
                         */
                        
                        let imageimage = UIImage(data: imageData)
                        print(imageimage!)
                        
                        /*
                         あなたのイメージで何かをしてください。
                         */
                        
                    } else {
                        print("画像を取得できませんでした：画像はありません")
                    }
                } else {
                    print("何らかの理由で応答コードを取得できませんでした")
                }
            }
        }
        
        downloadPicTask.resume()
        
        
        
        
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
}
