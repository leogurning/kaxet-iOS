//
//  UserLogin.swift
//  kaxet
//
//  Created by LEONARD GURNING on 08/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class UserLogin: Codable {
    
    let userid: String
    let username: String
    let name: String
    let usertype: String
    let balance: Double
    let lastlogin: Date
    
    init(userid: String, username: String, name: String, usertype: String, balance: Double, lastlogin: Date) {
        self.userid = userid
        self.username = username
        self.name = name
        self.usertype = usertype
        self.balance = balance
        self.lastlogin = lastlogin
    }
}
