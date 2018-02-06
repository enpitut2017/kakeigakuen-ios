//
//  KakeiViewController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/04.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit
import TwitterKit


class KakeiViewController: UIViewController {
    
    @IBOutlet weak var MonthLabel :UILabel!
    
    @IBOutlet weak var ReloadButton :UIButton!
    
    var getJson: NSDictionary!
    
    var kakeiImages :[UIImageView]! = []
    
    var images :[UIImage]! = []
    
    var addImages :UIImage!
    
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
        
    @IBAction func Reload() {
        
        kakeiRemove()
        
        let url = "https://kakeigakuen.xyz/api/image/path"
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
                self.kakeiRemove()
                DispatchQueue.main.async {
                    let urls:[String] = self.getJson["path"]! as! [String]
                    for u in urls{
                        self.getImage(url: URL(string: u)! as URL)
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
    }
    
    func goLogin(){
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "LoginView")
        self.present(nextView, animated: true, completion: nil)
    }
    
    
    let nowDate = NSDate()
    let dateFormat = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormat.dateFormat = "yyyy年MM月"
        MonthLabel.text = dateFormat.string(from: nowDate as Date)
        
        // Do any additional setup after loading the view.
        Reload()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func BtnAnimation(){
            let rotationAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
            rotationAnimation.toValue = CGFloat(Double.pi / 180) * 360
            rotationAnimation.duration = 0.8
            ReloadButton.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    @IBAction func tweet() {
        if let session = TWTRTwitter.sharedInstance().sessionStore.session() {
            print(session.userID)
            let composer = TWTRComposer()
            syncImages()
            composer.setText("私のカケイちゃんです！ | おてがる、カンタン、家計簿アプリ #家計学園 kakeigakuen.xyz")
            composer.setImage(addImages)
            composer.show(from: self) { result in
                if (result == .done) {
                    print("OK")
                } else {
                    print("NG")
                }
            }
            
        
        } else {
            twtrLogin()
            print("アカウントはありません")
        }
    }
    
    func twtrLogin() {
        TWTRTwitter.sharedInstance().logIn { session, error in
            guard let session = session else {
                if let error = error {
                    print("エラーが起きました => \(error.localizedDescription)")
                }
                return
            }
            print("@\(session.userName)でログインしました")
        }
    }
    
    func syncImages() {
        var bottomImage :UIImage = images[0]
        let newSize = CGSize(width:bottomImage.size.width, height:bottomImage.size.height)
        for i in 1..<images.count {
            UIGraphicsBeginImageContextWithOptions(newSize, false, bottomImage.scale)
            bottomImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height))
            let topImage :UIImage = images[i]
            topImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height),blendMode:CGBlendMode.normal, alpha:1.0)
            addImages = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            bottomImage = addImages!
        }
    }
    
    
    
    func getImage(url :URL){
        let imageView:UIImageView = UIImageView()
        let size:CGFloat = 400
        imageView.frame = CGRect(x:((self.view.bounds.width-size)/2),y:(self.view.bounds.height-size-100)/2,width:size,height:size+100)
        
        var imageData:NSData!
        do {
            imageData = try NSData(contentsOf: url ,options: NSData.ReadingOptions.mappedIfSafe)
        } catch {
            print(error.localizedDescription)
        }
        let image: UIImage = UIImage(data: imageData! as Data)!  // NSDataからUIImageへの変換
        imageView.image = image
        kakeiImages!.append(imageView)
        images!.append(image)
        self.view.addSubview(imageView)
        
    }
    
    func kakeiRemove() {
        if (kakeiImages != nil) {
            for i in kakeiImages {
                DispatchQueue.main.async { // Correct
                    i.removeFromSuperview()
                }
            }
        }
        images = []
    }
}
