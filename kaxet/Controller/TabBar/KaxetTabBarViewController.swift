//
//  KaxetTabBarViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 23/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class KaxetTabBarViewController: UITabBarController {
    
    private var miniPlayerVc: MiniPlayerViewController? {
        didSet{
            if let viewControllers = viewControllers {
                for vc in viewControllers {
                    configureTargetViewController(vc)
                }
            }
        }
    }
    
    private var miniPlayerView: UIView? {
        didSet{
            if let viewControllers = viewControllers {
                for vc in viewControllers {
                    configureTargetViewController2(vc)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func setMiniPlayerVc(playerVc: MiniPlayerViewController?) {
        self.miniPlayerVc = playerVc
    }
    
    func setMiniPlayerView(playerView: UIView?) {
        self.miniPlayerView = playerView
    }
    
    private
    func configureTargetViewController(_ viewController: UIViewController?){
        if let playerHolder = viewController as? BaseNavigationController {
            playerHolder.miniPlayerVc = miniPlayerVc
        }
    }
    
    private
    func configureTargetViewController2(_ viewController: UIViewController?){
        if let playerHolder = viewController as? BaseNavigationController {
            playerHolder.miniPlayerView = miniPlayerView
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
