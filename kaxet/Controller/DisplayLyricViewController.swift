//
//  DisplayLyricViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 14/11/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class DisplayLyricViewController: UIViewController {

    @IBOutlet weak var songLyricLabel: UILabel!
    var songLyric: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        songLyricLabel.text = songLyric
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func btnBackToPlayer(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
