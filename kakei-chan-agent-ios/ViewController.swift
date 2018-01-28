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





class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    //ロケールを指定してSFSpeechRecognizerを初期化(ユーザが指定していなかったらja_JPになる) -> 言語の指定
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
    
    //これをspeechRecognizerに投げることで結果を返してくれる
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    //音声を認識する
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private var animCalledCounter:Int = 0
    
    var titletimer: Timer!
    
    var recogtimer: Timer!
    
    @IBOutlet var textView : UITextView!
    
    var latestText: String! = ""
    
    var voicefinished: Bool = false
    
    var newtextlist: Array<String> = ["","","","","","","","","","","","",""]
    
    var score: Int = 0
    
    var getJson: NSDictionary!
    
    var now: Date? = nil
    
    //音声入力ボタン
    @IBOutlet weak var recordButton : UIButton!
    
    //予算出力文字
    @IBOutlet weak var budget: UILabel!
    
    //日程入力フィールド
    @IBOutlet weak var dateSelecter: UITextField!
    var toolBar:UIToolbar!
    
    //商品入力フィールド
    @IBOutlet weak var itemField: UITextField!
    
    //予算入力フィールド
    @IBOutlet weak var moneyField: UITextField!
    
    
    //ログアウト関数
    @IBAction func Logout(_ sender: Any) {
        Keychain.kakeiToken.del()
        Keychain.kakeiBudget.del()

        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView") as! LoginViewController
        self.present(nextView, animated: true, completion: nil)
    }
    

    //トークン設定
    public enum Keychain: String {
        // キー名
        case kakeiToken = "accessToken"
        case kakeiBudget = "userBudget"

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
    
    
/*
手入力時の決定ボタン
*/
    @IBAction func enterButtonTapped(){
        
        let s: String! = regulation(s: moneyField.text)
//        var i: Int! = 0
        if let i = Int(s) {
            if itemField.text != "" {
                self.score = i
                showStrPost(str: String(self.score))
                send_Items_json()
            } else {
                showStrAlert(str: "正しく入力してね")
            }
        } else {
            showStrAlert(str: "正しく入力してね")
        }
    }
    
    
/*
音声入力部分
*/
    //ボタンがタップされた時
    @IBAction func recordButtonTapped() {
        //もし認識機能が動いていなかったら
        if (!audioEngine.isRunning) {
            try! startRecording()
            self.latestText = ""
            for i in 0..<newtextlist.count {
                newtextlist[i] = ""
            }
            //タイマー設定
            //recordButton.setTitle("認識中", for: [])
            //titletimer = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(ViewController.buttonTitle), userInfo: nil, repeats: true)
            recogtimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(ViewController.recognitionlimit), userInfo: nil, repeats: true)

            //もし動いていたら強制的にfinish
        } else {
            finishRecording()
        }
    }
    
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode;// else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true
        
        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.textView.text = result.bestTranscription.formattedString
                self.latestText = self.textView.text
                print(self.latestText)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("入力開始", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        textView.text = "音声を入力してください..."
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("スタート", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("マイクを許可してください", for: .disabled)
        }
    }
    
    
    
    
    
    //レコーディングをこちら側で強制的に終わらせた時
    func finishRecording(){
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recordButton.isEnabled = false
        recordButton.setTitle("Stopping", for: .disabled)
        if recogtimer.isValid == true {
            //recogtimerを破棄して入力終了
            recogtimer.invalidate()
        }
        
//        if titletimer.isValid == true {
//            //titletimerを破棄してタイトルのアニメーション終了
//            titletimer.invalidate()
//        }
        
        //正規表現を使って文字列を半角数字列に置換
        //(円 -> "")
        //("マイナス" -> -)
        
        self.latestText = regulation(s: self.latestText)
        
        //うまく喋れてたら送信確認ポップアップ
        if (self.latestText != nil && Int(latestText) != nil){
            do{
                self.score = Int(latestText)!
            } catch {
                print("change type error")
            }
            //確認のポップアップ表示
            showStrPost(str: self.latestText)
        //喋れてなかったらErrorポップアップ
        } else {
            showStrAlert(str: "値段を喋ってね")
        }
    }
    
    //ボタンのタイトルのアニメーション制御
    //    @objc func buttonTitle(){
    //        var title:String = "認識中"
    //        animCalledCounter = animCalledCounter + 1
    //        for num in 0...animCalledCounter % 3 {
    //            title = title + "."
    //        }
    //        recordButton.setTitle(title, for: [])
    //    }
    
    //ユーザが喋り終わったのを認識して強制的に終わらせる
    @objc func recognitionlimit(){
        for num in 0...animCalledCounter % 3 {
            newtextlist.append(self.latestText)
            newtextlist.removeFirst()
        }
        if (newtextlist.first == newtextlist.last && newtextlist.first != "") {
            finishRecording()
        }
    }
    
    
    //音声入力の正規表現
    func regulation(s: String!) -> String {
        var regulatedS: String! = s
        regulatedS = s.pregReplace(pattern: "円", with: "")
        regulatedS = s.pregReplace(pattern: "マイナス", with: "-")
        regulatedS = s.pregReplace(pattern: "ー", with: "-")
        regulatedS = s.pregReplace(pattern: "−", with: "-")
        regulatedS = s.pregReplace(pattern: " ", with: "")
        regulatedS = s.pregReplace(pattern: ",", with: "")
        return regulatedS
    }
    
/*
日付の入力フォーム
*/
    
    //今日の日付を代入
    let nowDate = NSDate()
    let dateFormat = DateFormatter()
    let inputDatePicker = UIDatePicker()
    var sendDate = Date()
    
    override func viewDidLoad() {
        recordButton.isEnabled = false
        recordButton.layer.cornerRadius = 50.0
        recordButton.layer.masksToBounds = true
        recordButton.frame = CGRect(x:((self.view.bounds.width-100)/2),y:(self.view.bounds.height-100-20),width:100,height:100)
        
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
        
        self.itemField.delegate = self as? UITextFieldDelegate
        
        self.moneyField.delegate = self as? UITextFieldDelegate
        
        itemField.placeholder = "商品"
        moneyField.placeholder = "お金"
        
        //loadImage()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func inputFieldShouldReturn (_ inputField: UITextField) -> Bool {
        inputField.resignFirstResponder()
        return true
    }

    //完了を押すとピッカーの値を、テキストフィールドに挿入して、ピッカーを閉じる
    @objc func toolBarBtnPush(sender: UIBarButtonItem){
        sendDate = inputDatePicker.date
        dateSelecter.text = dateFormat.string(from: sendDate)
        self.view.endEditing(true)
    }
    
    
    
    

    //    func loadImage(){
    //        if (Keychain.kakeiToken.value() != nil){
    //            let requestURL = URL(string: "https://kakeigakuen.xyz/api/image/" + Keychain.kakeiToken.value()! )!
    //            //let requestURL = URL(string: "http://localhost:3000/api/image/" + Keychain.kakeiToken.value()!)!
    //            let req = URLRequest(url: requestURL)
    //            print(req)
    //            image.loadRequest(req)
    //        } else {
    //            let storyboard: UIStoryboard = self.storyboard!
    //            let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView") as! LoginViewController
    //            self.present(nextView, animated: true, completion: nil)
    //        }
    //    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if (Keychain.kakeiToken.value() != nil) {
            let userBudget = "\(Keychain.kakeiBudget.value() ?? "")"
            self.budget.text = "残高: \(userBudget)"
        } else {
            let storyboard: UIStoryboard = self.storyboard!
            let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView") as! LoginViewController
            self.present(nextView, animated: true, completion: nil)
        }
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            //マイクのアクセス許可を求める
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
        }
    }
    
    
    //渡された文字列をサーバにpost送信する
    func showStrPost(str: String){
        // UIAlertControllerを作成する.
        let myAlert: UIAlertController = UIAlertController(title: "確認", message: str, preferredStyle: .alert)
        
        // OKのアクションを作成する.
        let myOkAction = UIAlertAction(title: "送信", style: .default) { action in
            self.send_Items_json()
            print("Successfully send json to web server")
            
            //残高更新
        
        }
        // OKのActionを追加する.
        myAlert.addAction(myOkAction)
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
代金送信json投げる
*/

    func send_Items_json() {
        //let url = "http://localhost:3000/api/books"
        let url = "https://kakeigakuen.xyz/api/books"
        let request = NSMutableURLRequest(url: NSURL(string: url)! as URL)
        
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = Keychain.kakeiToken.value() as! String
        print(token)
        print(String(describing: type(of: self.score)))
        if (token != nil) {
            let params: [String: Any] = [
                "costs" : String(self.score),
                "token" : Keychain.kakeiToken.value() as! String
            ]
            
            do{
                //json送信
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            }catch{
                print(error.localizedDescription)
            }
            
            let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data, resp, err) in
               // print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as Any)
                
                // JSONパースしてキーチェーンに新しいbudgetをセット
                do {
                    print(try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary)
                    self.getJson = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    if (self.getJson["token"] as! String != "error"){
                        DispatchQueue.main.async {
                            //Keychain.kakeiBudget.set("\(self.getJson["budget"])")
                            let userBudget = "\(self.getJson["budget"] ?? "")"
                            self.budget.text = "残高: \(userBudget)"
                        }
                    } else {
                        self.showStrAlert(str: "ごめんなさい...もう一度ログインし直してみてっ！")
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        print("failed to parse json")
                    })
                    return
                }
            })
            task.resume()
        } else {
            print("cant get user token")
        }
    }


}
