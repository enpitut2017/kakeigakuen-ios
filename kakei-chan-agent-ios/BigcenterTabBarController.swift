//
//  BigcenterTabBarController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/18.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit
import BubbleTransition

class BigcenterTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination
        controller.transitioningDelegate = self as UIViewControllerTransitioningDelegate
        controller.modalPresentationStyle = .custom
    }
    
    // タブ真ん中のボタン作成
    private func setupBigCenterButton(){
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage(named: "record") , for: .normal)   // TODO:画像の用意
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        button.imageView?.contentMode = .scaleAspectFit
        
        button.center = CGPoint(x: tabBar.bounds.size.width / 2, y: tabBar.bounds.size.height - (button.bounds.size.height/2))
        button.addTarget(self, action: #selector(BigcenterTabBarController.tapBigCenter), for: .touchUpInside)
        tabBar.addSubview(button)
    }
    
    // タブ真ん中を選択する
    @objc func tapBigCenter(sender:AnyObject){
        //selectedIndex = 1
        let next = storyboard!.instantiateViewController(withIdentifier: "VoiceRecogViewController")
        self.present(next,animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // タブ真ん中にボタンを置く
        setupBigCenterButton()
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

