//
//  GraphViewController.swift
//  
//
//  Created by 赤坂勝哉 on 2018/02/04.
//

import UIKit

class GraphViewController: UIViewController , UITableViewDataSource , UITableViewDelegate{

    @IBOutlet weak var MonthLabel :UILabel!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var ReloadButton :UIButton!
    
    var getJson :NSDictionary!
    
    var itemList :[String] = []
    
    var boughtList :[String] = []
    
    var  costList :[String] = []
    
    
    var dates :[String] = []
    
    var dateNum :[Int] = []
    
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
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 一つのsectionの中に入れるCellの数を決める
        return dateNum[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // sectionの数を決める
        return returnSec()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        //section番目ののヘッダを決める
        return dates[section]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Cellの高さを決める
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "booksList", for: indexPath)
        //cell.accessoryType = .disclosureIndicator
        var until :Int = 0
        for i in 0..<indexPath.section {
            until += dateNum[i]
        }
        let thisSecNum :Int = dateNum[indexPath.section]
        let num :Int = until + thisSecNum - indexPath.row-1
        cell.textLabel?.text = itemList[num]
        
        
        
        cell.detailTextLabel?.textColor = #colorLiteral(red: 0.8199555838, green: 0.8199555838, blue: 0.8199555838, alpha: 1)
        cell.detailTextLabel?.text = costList[num]
        
        
        return cell
        
    }
    
    func returnSec () -> Int{
       return dates.count
    }
    
    func datesMaker() {
        var latestd :String = ""
        dates = []
        dateNum = []
        let nowDate = NSDate()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "MM月"
        let nowMonth :String = dateFormat.string(from: nowDate as Date)
        var count :Int = 0
        
        if(boughtList.count != 0){
            latestd = boughtList[0]
            for d in boughtList {
                if (latestd != d) {
                    dateNum.append(count)
                    dates.append(nowMonth + latestd + "日")
                    latestd = d
                    count = 1
                } else {
                    count += 1
                }
            }
            dateNum.append(count)
            dates.append(nowMonth + latestd + "日")
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let nowDate = NSDate()
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = "yyyy年MM月"
        MonthLabel.text = dateFormat.string(from: nowDate as Date)
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func BtnAnimation(){
        let rotationAnimation = CABasicAnimation(keyPath:"transform.rotation.z")
        rotationAnimation.toValue = CGFloat(Double.pi / 180) * 360
        rotationAnimation.duration = 0.8
        ReloadButton.layer.add(rotationAnimation, forKey: "rotationAnimation")
        getList()
    }
    
    
    
    func getList() {
        let url = "https://kakeigakuen.xyz/api/book_list"
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
                    if(self.noerr()) {
                        self.boughtList = []
                        self.itemList = []
                        self.costList = []
                        let booklist = self.getJson["list"] as! NSArray
                        for l in booklist {
                            let block = l as! NSDictionary
                            self.itemList.append(block["item"] as! String)
                            var date = block["time"] as! String
                            date = [Character](date.characters)[8..<10].map{ String($0) }.joined(separator: "")
                            self.boughtList.append(date)
                            self.costList.append("\(block["cost"] ?? "")")
                        }
                        self.datesMaker()
                        self.tableView.reloadData()
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
    
    func noerr() -> Bool{
        if("\(self.getJson["error"] ?? "")" == "true") {
            return false
        } else {
            return true
        }
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
