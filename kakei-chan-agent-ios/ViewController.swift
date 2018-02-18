//
//  ViewController.swift
//  kakei-chan-agent-ios
//
//  Created by masamune kobayashi on 2017/12/07.
//  Copyright © 2017年 masamune kobayashi. All rights reserved.
//

import Foundation
import Security
import UIKit
import Speech
import UICircularProgressRing
import BubbleTransition


extension String {
    //絵文字など(2文字分)も含めた文字数を返します
    var length: Int {
        let string_NS = self as NSString
        return string_NS.length
    }
    
    //正規表現の検索をします
    func pregMatche(pattern: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.length))
        return matches.count > 0
    }
    
    //正規表現の検索結果を利用できます
    func pregMatche(pattern: String, options: NSRegularExpression.Options = [], matches: inout [String]) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return false
        }
        let targetStringRange = NSRange(location: 0, length: self.length)
        let results = regex.matches(in: self, options: [], range: targetStringRange)
        for i in 0 ..< results.count {
            for j in 0 ..< results[i].numberOfRanges {
                let range = results[i].range(at: j)
                matches.append((self as NSString).substring(with: range))
            }
        }
        return results.count > 0
    }
    
    //正規表現の置換をします
    func pregReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, self.length), withTemplate: with)
    }
}





class ViewController: UIViewController,UITextFieldDelegate ,SFSpeechRecognizerDelegate, UIGestureRecognizerDelegate {
    //ロケールを指定してSFSpeechRecognizerを初期化(ユーザが指定していなかったらja_JPになる) -> 言語の指定
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
    
    var item: String = ""
    
    var cost: String = ""
    
    var getJson: NSDictionary!
    
    var now: Date? = nil
    
    var loggedin: Bool = false
    
    let transition = BubbleTransition()
    
    var params:[String:String] = [:]
        
    
    //音声入力ボタン
    //@IBOutlet weak var recordButton : UIButton!
    
    //今月の予算出力文字
    @IBOutlet weak var budgetLabel: UILabel!
    
    @IBOutlet weak var RemainingMoenyLabel: UILabel!
    
    //日程入力フィールド
    @IBOutlet weak var dateSelecter: UITextField!
    var toolBar:UIToolbar!
    
    //商品入力フィールド
    @IBOutlet weak var itemField: UITextField!
    
    //予算入力フィールド
    @IBOutlet weak var moneyField: UITextField!
    
    @IBOutlet weak var progressRing: UICircularProgressRingView!
    
    //ヘッダの月
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBOutlet weak var header: UIView!

    //入力フォーム隠れないためのscrollview
    @IBOutlet weak var sc: UIScrollView!
    //UITextFieldの情報を格納するための変数
    var txtActiveField = UITextField()
    var scrollFormer:CGFloat! = nil
    let scrollViewsample = UIScrollView()
    
    @IBAction func backToTop(segue: UIStoryboardSegue) {}
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! VoiceRecogViewController
        controller.transitioningDelegate = self as! UIViewControllerTransitioningDelegate
        controller.modalPresentationStyle = .custom
    }
    
/*
手入力時の決定ボタン
*/
    @IBAction func enterButtonTapped(){
        let s: String! = moneyField.text!.pregReplace(pattern: "円", with: "")
        if let i = Int(s) {
            if itemField.text != "" {
                self.item = itemField.text!
                self.cost = moneyField.text!
                self.send_Items_json()
                //showStrPost(str: self.item + " " + self.cost)
            } else {
                showStrAlert(str: "正しく入力してね")
            }
        } else {
            showStrAlert(str: "正しく入力してね")
        }
    }
    
/*
日付の入力フォーム
ViewDidLoad : あらゆるコンポーネントの配置決定
*/
    
    //今日の日付を代入
    let nowDate = NSDate()
    let dateFormat = DateFormatter()
    let inputDatePicker = UIDatePicker()
    var sendDate = Date()
    
    override func viewDidLoad() {
        if (Keychain.kakeiToken.value() == nil || Keychain.kakeiToken.value()! == "error") {
            loggedin = false
        } else {
            loggedin = true
            
            dateFormat.dateFormat = "yyyy年MM月"
            monthLabel.text = dateFormat.string(from: nowDate as Date)
            
            //日付フィールドの設定
            dateFormat.dateFormat = "yyyy/MM/dd"
            dateSelecter.text = dateFormat.string(from: nowDate as Date)
            self.dateSelecter.delegate = self as? UITextFieldDelegate
            
            
            // DatePickerの設定(日付用)
            inputDatePicker.datePickerMode = UIDatePickerMode.date
            dateSelecter.inputView = inputDatePicker
            
            // キーボードに表示するツールバーの表示
            let pickerToolBar = UIToolbar(frame: CGRect(x:0, y:self.view.frame.size.height/6, width:self.view.frame.size.width, height:40.0))
            pickerToolBar.layer.position = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height-20.0)
            pickerToolBar.barStyle = .blackTranslucent
            pickerToolBar.tintColor = UIColor.white
            pickerToolBar.backgroundColor = UIColor.black
            
            //ボタンの設定
            //右寄せのためのスペース設定
            let spaceBarBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,target: self,action: Selector(""))
            
            //完了ボタンを設定
            let toolBarBtn = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(ViewController.toolBarBtnPush(sender:)))
            
            //ツールバーにボタンを表示
            pickerToolBar.items = [spaceBarBtn,toolBarBtn]
            dateSelecter.inputAccessoryView = pickerToolBar
            
            self.itemField.delegate = self
            
            self.moneyField.delegate = self
            
            itemField.placeholder = "商品"
            moneyField.placeholder = "お金"
            
            self.progressRing.maxValue = CGFloat(Int(Keychain.kakeiBudget.value()!)!)
            self.progressRing.minValue = 0
            
            //キーボード出現でスクロール
            sc.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0)
            sc.delegate = self as? UIScrollViewDelegate
            
            self.view.addSubview(sc)
            sc.addSubview(itemField)
            sc.addSubview(moneyField)
            sc.addSubview(dateSelecter)
            sc.addSubview(progressRing)
            sc.addSubview(header)
            self.view.sendSubview(toBack: sc)
            
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
    
    func inputFieldShouldReturn (_ inputField: UITextField) -> Bool {
        inputField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    //完了を押すとピッカーの値を、テキストフィールドに挿入して、ピッカーを閉じる
    @objc func toolBarBtnPush(sender: UIBarButtonItem){
        sendDate = inputDatePicker.date
        dateSelecter.text = dateFormat.string(from: sendDate)
        self.view.endEditing(true)
    }
    
    //ViewDidLoadで最初だけapi/statusにアクセスしてuserStatusをチェック
    //それ以降はViewDidAppearで差分を計算してnativeで独立して計算させる
    //apiにはbooksで購入情報だけ投げる
    override func viewDidAppear(_ animated: Bool) {
        
        if (Keychain.kakeiToken.value() != nil && Keychain.kakeiToken.value()! != "error") {
            loggedin = true
        } else {
            loggedin = false
        }
        if(loggedin) {
            reload()
            if(params != [:]){
                self.itemField.text = params["item"]!
                self.moneyField.text = params["cost"]!
            }
            speechRecognizer.delegate = self
            
//            SFSpeechRecognizer.requestAuthorization { authStatus in
//                //マイクのアクセス許可を求める
//                OperationQueue.main.addOperation {
//                    switch authStatus {
//                    case .authorized:
//                        self.recordButton.isEnabled = true
//
//                    case .denied:
//                        self.recordButton.isEnabled = false
//                        self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
//
//                    case .restricted:
//                        self.recordButton.isEnabled = false
//                        self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
//
//                    case .notDetermined:
//                        self.recordButton.isEnabled = false
//                        self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
//                    }
//                }
//            }
        } else {
            goLogin()
        }
    }
    
    
    @objc func handleKeyboardWillShowNotification(_ notification: Notification) {
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let myBoundSize: CGSize = UIScreen.main.bounds.size
        
        let txtLimit = txtActiveField.frame.origin.y + txtActiveField.frame.height + 50.0
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height
        
        if txtLimit >= kbdLimit {
            sc.contentOffset.y = txtLimit - kbdLimit
        }
    }
    
    
/*
スクロールして入力できるようにするためのもの
*/
    @objc func handleKeyboardWillHideNotification(_ notification: Notification) {
        //スクロールしてある位置に戻す
        sc.contentOffset.y = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        let nc = NotificationCenter.default
        nc.addObserver(
            self, selector:
            #selector(ViewController.handleKeyboardWillShowNotification(_:)),
            name: Notification.Name.UIKeyboardWillShow,
            object: nil
        )
        nc.addObserver(
            self,
            selector: #selector(ViewController.handleKeyboardWillHideNotification(_:)),
            name: Notification.Name.UIKeyboardWillHide,
            object: nil
        )
        
    }
    
    
    //渡された文字列をサーバにpost送信する
    func showStrPost(str: String){
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: "確認", message: str, preferredStyle: .alert)
        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "送信", style: .default) { action in
            self.item = self.params["item"]!
            self.cost = self.params["cost"]!
            self.params = [:]
            self.send_Items_json()
            print("Successfully send json to web server")
        }
        let myNGAction = UIAlertAction(title: "取り消す", style: .default) { action in
        }
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)
        myAlert.addAction(myNGAction)
        // UIAlertを発動する.
        present(myAlert, animated: true, completion: nil)
    }
    
    //認識できないAlertを表示するだけ
    func showStrAlert(str: String){
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: "Error", message: str, preferredStyle: .alert)
        
        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "戻る", style: .default) { action in
            //self.go_to_rails()
        }
        
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)
        // UIAlertを発動する.
        present(myAlert, animated: true, completion: nil)
    }
    
/*
 データ更新
*/
    func reload() {
        statusCheck()
        itemField.text = ""
        moneyField.text = ""

        RemainingMoenyLabel.text = "\(Keychain.kakeiRest.value()!)"
        
        budgetLabel.text = "\(Keychain.kakeiBudget.value()!)"
        
        progressRing.setProgress(value: CGFloat(Int(Keychain.kakeiRest.value()!)!), animationDuration: 1.0)
    }
    
    //画面タップでデータ更新
    @IBAction func Reload(_ sender: Any) {
        reload()
    }
    
    
/*
代金送信json投げる
*/

    func send_Items_json() {
        let url = "https://kakeigakuen.xyz/api/books"
        var request = URLRequest(url: URL(string: url)! as URL)
        
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if (loggedin) {
           //送信するparams
            //商品, 値段, トークン
            let params: [String: Any] = [
                "items" : String(self.item),
                "costs" : String(self.cost),
                "token" : Keychain.kakeiToken.value()!
            ]
            
            do{
                //json送信
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            }catch{
                print(error.localizedDescription)
            }

            let task = URLSession.shared.dataTask(with: request) {
                data, response, error in
                // JSONパースしてキーチェーンに新しいbudgetをセット
                do {
                    if error != nil {
                        print(error!.localizedDescription)
                        DispatchQueue.main.sync(execute: {
                            print("error occered")
                        })
                        return
                    }
                    self.getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    DispatchQueue.main.async {
                        if(!self.err()) {
                            let userRest = "\(self.getJson["rest"] ?? "")"
                            Keychain.kakeiRest.set(userRest)
                            self.params = [:]
                            self.item = ""
                            self.cost = ""
                            //残高更新
                            self.reload()
                        } else {
                             print("failed to parse json")
                        }
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        print("failed to parse json")
                    })
                    return
                }
            }
            task.resume()
        } else {
            print("cant get user token")
        }
    }
    
    
    
    func statusCheck() {
        let url = "https://kakeigakuen.xyz/api/status"
        var request = URLRequest(url: URL(string: url)! as URL)
        
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = Keychain.kakeiToken.value()!
        let params: [String: Any] = [
            "token" : token
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
                self.getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                DispatchQueue.main.async {
                    if(!self.err()) {
                        let userRest = "\(self.getJson["rest"] ?? "")"
                        let userbudget = "\(self.getJson["budget"] ?? "")"
                        let userToken = "\(self.getJson["token"] ?? "")"
                        //トークンセット
                        Keychain.kakeiRest.set(userRest)
                        Keychain.kakeiBudget.set(userbudget)
                        Keychain.kakeiToken.set(userToken)
                    } else {
                        print("failed to parse json")
                    }
                    //self.reload()
                }
            } catch {
                DispatchQueue.main.async(execute: {
                    print("failed to parse json")
                })
                return
            }
        }
        task.resume()
    }
    
    func err() -> Bool{
        if("\(self.getJson["error"] ?? "")" == "true") {
            return true
        } else {
            return false
        }
    }
}

//extension ViewController : UIViewControllerTransitioningDelegate{
//
//    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        print("dl;kfjasdl;nva;elinvaO+we,,,,,,,,,,,,,,,,,,,")
//        transition.transitionMode = .present
//        transition.startingPoint = recordButton.center    //outletしたボタンの名前を使用
//        transition.bubbleColor = #colorLiteral(red: 0.2340592742, green: 0.7313898206, blue: 0.688031435, alpha: 1)         //円マークの色
//        return transition
//    }
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        transition.transitionMode = .dismiss
//        transition.startingPoint = recordButton.center //outletしたボタンの名前を使用
//        return transition
//    }
//}
//

