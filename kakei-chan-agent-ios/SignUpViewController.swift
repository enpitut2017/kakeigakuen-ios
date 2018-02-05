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
    
    var timer :Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.checkColor), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    @objc func checkColor() {
        var filled :Int = 0
        if (name.text != "") {
            filled += 1
        }
        if(email.text != "") {
            filled += 1
        }
        if (password.text != ""){
            filled += 1
        }
        if (password_conf.text != "") {
            filled += 1
        }
        if (budget.text != "") {
            filled += 1
        }
        if(filled == 5) {
            register.backgroundColor = #colorLiteral(red: 0.2047508657, green: 0.7041116357, blue: 0.6483085752, alpha: 1)
        } else {
            register.backgroundColor = #colorLiteral(red: 0.709620595, green: 0.7137866616, blue: 0.7136848569, alpha: 1)
        }
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
