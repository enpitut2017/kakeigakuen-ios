//
//  TestViewController.swift
//  kakei-chan-agent-ios
//
//  Created by 赤坂勝哉 on 2018/02/18.
//  Copyright © 2018年 masamune kobayashi. All rights reserved.
//

import UIKit
import BubbleTransition

class TestViewController: UIViewController, UITabBarDelegate {
    @IBOutlet weak var tabBar: UITabBar!
    
    @IBOutlet weak var main: UIView!
    @IBOutlet weak var kakei: UIView!
    @IBOutlet weak var record: UIView!

    @IBOutlet weak var graph: UIView!
    
    @IBOutlet weak var setting: UIView!
    @IBOutlet weak var recordButton :UIButton!
    
    let transition = BubbleTransition()
    override func viewDidLoad() {
        super.viewDidLoad()
        main.isHidden = false
        kakei.isHidden = true
        record.isHidden = true
        graph.isHidden = true
        setting.isHidden = true
        tabBar.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //ボタン押下時の呼び出しメソッド
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem){
        main.isHidden = true
        kakei.isHidden = true
        record.isHidden = true
        graph.isHidden = true
        setting.isHidden = true
        switch item.tag {
        case 1:
            main.isHidden = false
        case 2:
            kakei.isHidden = false
        case 3:
            record.isHidden = false
        case 4:
            graph.isHidden = false
        case 5:
            setting.isHidden = false
        default:
            record.isHidden = false
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if (segue.identifier == "toVoiceRecog"){
            print("yes")
            let controller = segue.destination
            controller.transitioningDelegate = self as UIViewControllerTransitioningDelegate
            controller.modalPresentationStyle = .custom
        //}
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



extension TestViewController : UIViewControllerTransitioningDelegate{
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        print("dl;kfjasdl;nva;elinvaO+we,,,,,,,,,,,,,,,,,,,")
        transition.transitionMode = .present
        transition.startingPoint = recordButton.center  //outletしたボタンの名前を使用
        transition.bubbleColor = #colorLiteral(red: 0.2340592742, green: 0.7313898206, blue: 0.688031435, alpha: 1)         //円マークの色
        return transition
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .dismiss
        transition.startingPoint = recordButton.center //outletしたボタンの名前を使用
        return transition
    }
}


