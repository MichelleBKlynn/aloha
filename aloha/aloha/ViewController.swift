//
//  ViewController.swift
//  aloha
//
//  Created by Michelle Staton on 2/11/17.
//  Copyright © 2017 Michelle Staton. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        AlohaAPIClient.getAPIData { (response) in
            print("called api")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


/*assume can get back a list of messages in that area
 1. call on aloha backend to retrieve coordinates
 2. use coordinates to retrieve messages in that location

 */
