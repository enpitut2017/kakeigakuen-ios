//
//  VoiceRecogViewController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/16.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit
import Speech
import BubbleTransition

class VoiceRecogViewController: UIViewController {

    //ロケールを指定してSFSpeechRecognizerを初期化(ユーザが指定していなかったらja_JPになる) -> 言語の指定
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))!
    //これをspeechRecognizerに投げることで結果を返してくれる
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    //音声を認識する
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    private var animCalledCounter:Int = 0
    
    var voicefinished: Bool = false
    
    var latestText: String! = ""
    
    var newtextlist: Array<String> = ["","","","","","","","","","","","",""]
    
    var recogtimer: Timer!
    
    var item: String = ""
    
    var cost: String = ""
    
    var params: [String:String] = [:]
    
    @IBOutlet var textView : UITextView!
    
    @IBOutlet weak var recordButton : UIButton!
    
    @IBAction func buttonpushed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if (!audioEngine.isRunning) {
//            try! startRecording()
//            self.latestText = ""
//            for i in 0..<newtextlist.count {
//                newtextlist[i] = ""
//            }
//            //タイマー設定
//            //recordButton.setTitle("認識中", for: [])
//            //titletimer = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(ViewController.buttonTitle), userInfo: nil, repeats: true)
//            recogtimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.recognitionlimit), userInfo: nil, repeats: true)
//
//            //もし動いていたら強制的にfinish
//        } else {
//            finishRecording()
//        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if (self.item != "" && self.cost != "" && Int(self.cost) != nil){
            //確認のポップアップ表示
            //showStrPost(str: self.item + " " + self.cost)
            showStrAlert(str: "正しく入力できてるよ")
            
            //喋れてなかったらErrorポップアップ
        } else {
            showStrAlert(str: "正しく入力してね")
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
        newtextlist.append(self.latestText)
        newtextlist.removeFirst()
        if (newtextlist.first == newtextlist.last && newtextlist.first != "") {
            finishRecording()
        }
    }
    
    /*
     音声入力の正規表現
     */
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
        print(itemArray)
        print(costArray)
        var items :String = ""
        var costs :String = ""
        for i in itemArray{
            if i != ""{
                items += i
            } else {
                break
            }
        }
        for i in costArray {
            costs += i
            
        }
        self.item = items
        self.cost = costs
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
    
    func segueToMainViewController(){
        //指定したIDのSegueを初期化する。同時にパラメータを渡すことができる
        self.performSegue(withIdentifier: "backToMain", sender:params)
    }
    
    //Segueの初期化を通知するメソッドをオーバーライドする。senderにはperformSegue()で渡した値が入る。
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "backToMain" {
            let mainViewController = segue.destination as! ViewController
            mainViewController.params = sender as! [String:String]
        }
    }
}


