//
//  BigcenterTabBarController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/18.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit
import BubbleTransition

class BigcenterTabBarController: UITabBarController{

    
    let transition = BubbleTransition()
    let recordButton = UIButton(type: .custom)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // タブ真ん中のボタン作成
    private func setupBigCenterButton(){
        recordButton.setBackgroundImage(UIImage(named: "record") , for: .normal)   // TODO:画像の用意
        recordButton.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        recordButton.imageView?.contentMode = .scaleAspectFit
        
        recordButton.center = CGPoint(x: tabBar.bounds.size.width / 2, y: tabBar.bounds.size.height - (recordButton.bounds.size.height/2))
        //recordButton.addTarget(self, action: #selector(BigcenterTabBarController.tapBigCenter), for: .touchUpInside)
        tabBar.addSubview(recordButton)
    }
    
    // タブ真ん中を選択する
//    @objc func tapBigCenter(sender:AnyObject){
//        //selectedIndex = 1
//
//        let next = storyboard!.instantiateViewController(withIdentifier: "VoiceRecogViewController")
//        self.present(next,animated: true, completion: nil)
//    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // タブ真ん中にボタンを置く
        setupBigCenterButton()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! VoiceRecogViewController
        controller.transitioningDelegate = self as! UIViewControllerTransitioningDelegate
        controller.modalPresentationStyle = .custom
    }
}

//
extension BigcenterTabBarController : UIViewControllerTransitioningDelegate{
//
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        print("dl;kfjasdl;nva;elinvaO+we,,,,,,,,,,,,,,,,,,,")
        transition.transitionMode = .present
        transition.startingPoint = recordButton.center    //outletしたボタンの名前を使用
        transition.bubbleColor = #colorLiteral(red: 0.2340592742, green: 0.7313898206, blue: 0.688031435, alpha: 1)         //円マークの色
        return transition
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = recordButton.center //outletしたボタンの名前を使用
        return transition
    }
}

