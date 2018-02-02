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
    
    var item: String = ""
    
    var cost: String = ""
    
    var budget: Int = 10000
    
    var remainMoney: Int! = 10000
    
    var getJson: NSDictionary!
    
    var now: Date? = nil
    
    var loggedin: Bool = false
    
    //音声入力ボタン
    @IBOutlet weak var recordButton : UIButton!
    
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
    
    
    //ログアウト関数
    @IBAction func Logout(_ sender: Any) {
        print("logout func is called")

        Keychain.kakeiToken.del()
        Keychain.kakeiBudget.del()
        Keychain.kakeiRest.del()
        goLogin()
    }
    
    func goLogin(){
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView")
        self.present(nextView, animated: true, completion: nil)
        print("lllllllllllllllllllllllllllllllllll")

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
    
    
/*
手入力時の決定ボタン
*/
    @IBAction func enterButtonTapped(){
        
        let s: String! = moneyField.text!.pregReplace(pattern: "円", with: "")
        if let i = Int(s) {
            if itemField.text != "" {
                self.item = itemField.text!
                self.cost = moneyField.text!
                self.score = i
                showStrPost(str: self.item + " " + self.cost)
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
                //print(self.latestText)
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
        
        regulation(s: self.latestText)
        
        //うまく喋れてたら送信確認ポップアップ
        if (self.item != nil && self.cost != nil && Int(self.cost) != nil){
            self.score = Int(self.cost)!
            //確認のポップアップ表示
            showStrPost(str: self.item + " " + self.cost)
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
    //入力文字列を投げるとself.itemとself.costに代入される
    func regulation(s: String!) {
        var regulatedS: String! = s
    
        regulatedS = regulatedS.pregReplace(pattern: "円", with: "")
        regulatedS = regulatedS.pregReplace(pattern: "マイナス", with: "-")
        regulatedS = regulatedS.pregReplace(pattern: "ー", with: "-")
        regulatedS = regulatedS.pregReplace(pattern: "−", with: "-")
        regulatedS = regulatedS.pregReplace(pattern: " ", with: "")
        regulatedS = regulatedS.pregReplace(pattern: ",", with: "")
        
        let itemArray: [String]! = regulatedS.components(separatedBy: CharacterSet.decimalDigits)
        let costArray: [String]! = regulatedS.components(separatedBy: CharacterSet.decimalDigits.inverted)

        var items :String = ""
        var costs :String = ""
        for i in itemArray{
            items += i
        }
        for i in costArray {
            costs += i
        }
        self.item = items
        self.cost = costs
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
        print("load is called")
        if (Keychain.kakeiToken.value() == nil || Keychain.kakeiToken.value()! == "error") {
            loggedin = false
        } else {
            loggedin = true
            //statusCheck()
            //Keychain.kakeiRest.set("1000")
//            print ("userToken = " + Keychain.kakeiToken.value()!)
//            print ("userRest = " + Keychain.kakeiRest.value()!)
//            print ("userBudget = " + Keychain.kakeiBudget.value()!)
//
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
            
           // progressRing.delegate = self as? UICircularProgressRingDelegate
            //progressRing = UICircularProgressRingView(frame: CGRect(x: 87, y: 102, width: 200, height: 200))
            self.progressRing.maxValue = CGFloat(Int(Keychain.kakeiBudget.value()!)!)
            self.progressRing.minValue = 0
            self.progressRing.setProgress(value: CGFloat(Int(Keychain.kakeiRest.value()!)!), animationDuration: 1.0)
    //        progressRing.ringStyle = UICircularProgressRingStyle.ontop
    //        progressRing.startAngle = CGFloat(140)
    //        progressRing.endAngle = CGFloat(40)
    //        progressRing.outerRingWidth = 8
    //        progressRing.outerRingColor = #colorLiteral(red: 0.709620595, green: 0.7137866616, blue: 0.7136848569, alpha: 1)
    //        progressRing.outerCapStyle = CGLineCap.round
    //        progressRing.innerRingWidth = 9
    //        progressRing.innerRingColor = #colorLiteral(red: 0, green: 0.6134710312, blue: 0.5824463964, alpha: 1)
    //        progressRing.innerCapStyle = CGLineCap.round
            //loadImage()
        }
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
    
//
//    override func viewWillAppear(_ animated: Bool) {
//        statusCheck()
//        if(Keychain.kakeiToken.value() == nil) {
//
//        }
//    }
    
    //ViewDidLoadで最初だけapi/statusにアクセスしてuserStatusをチェック
    //それ以降はViewDidAppearで差分を計算してnativeで独立して計算させる
    //apiにはbooksで購入情報だけ投げる
    override func viewDidAppear(_ animated: Bool) {
        print("appear is called")
        if (Keychain.kakeiToken.value() != nil && Keychain.kakeiToken.value()! != "error") {
            loggedin = true
        } else {
            loggedin = false
        }
        
        if(loggedin) {
            print("appear")
            statusCheck()
            let userRest = "\(Keychain.kakeiRest.value() ?? "")"
            print(userRest)
            self.RemainingMoenyLabel.numberOfLines = 2
            self.RemainingMoenyLabel.text = "残り予算\n\(userRest)"
            self.budgetLabel.text = String(budget)
        
            //let userRest = "\(Keychain.kakeiRest.value() ?? "")"
            let userBudget = "\(Keychain.kakeiBudget.value() ?? "")"
            let userToken = "\(Keychain.kakeiToken.value() ?? "")"
            print ("userRest = " + userRest)
            print ("userBudget = " + userBudget)
            print ("userToken = " + userToken)
            self.remainMoney = Int(userRest)!
            progressRing.setProgress(value: CGFloat(remainMoney) , animationDuration: 2.0)
            
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
        } else {
            goLogin()
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
            self.progressRing.setProgress(value: CGFloat(self.remainMoney) , animationDuration: 1.0)
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
        let url = "https://kakeigakuen.xyz/api/books"
        var request = URLRequest(url: URL(string: url)! as URL)
        
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if (loggedin) {
           //送信するparams
            //商品, 値段, トークン
            let params: [String: Any] = [
                "item" : String(self.item),
                "costs" : String(self.score),
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
                        let userRest = "\(self.getJson["rest"] ?? "")"
                        Keychain.kakeiRest.set(userRest)
                        self.remainMoney = Int(userRest)!
                        self.RemainingMoenyLabel.numberOfLines = 2
                        self.RemainingMoenyLabel.text = "残り予算\n\(userRest)"
                        print("this is send_json_items")
                        print(userRest)
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
        
        let token = Keychain.kakeiToken.value()
//        if (Keychain.kakeiToken.value() != nil || Keychain.kakeiToken.value()! != "error") {
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
                        let userRest = "\(self.getJson["rest"] ?? "")"
                        let userbudget = "\(self.getJson["budget"] ?? "")"
                        let userToken = "\(self.getJson["token"] ?? "")"
                
                        self.remainMoney = Int(userRest)
                        //トークンセット
                        Keychain.kakeiRest.set(userRest)
                        Keychain.kakeiBudget.set(userbudget)
                        Keychain.kakeiToken.set(userToken)
                        
                        self.RemainingMoenyLabel.numberOfLines = 2
                        self.RemainingMoenyLabel.text = "残り予算\n\(userRest)"
                        self.budgetLabel.text = userbudget
                    }
                } catch {
                    DispatchQueue.main.async(execute: {
                        print("failed to parse json")
                    })
                    return
                }
            }
            task.resume()
//        } else {
//            print("cant get user token")
//            resetToken()
//            goLogin()
//        }
    }
    
    func resetToken() {
        Keychain.kakeiToken.set("initToken")
        Keychain.kakeiBudget.set("initBudget")
        Keychain.kakeiRest.set("initRest")
    }
}
