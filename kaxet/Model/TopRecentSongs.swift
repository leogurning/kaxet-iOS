//
//  TopRecentSongs.swift
//  kaxet
//
//  Created by LEONARD GURNING on 10/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import Foundation

class ResultTopRecentSong: Codable {
    let success: Bool
    let data: [TopRecentSong]
    let npage: Int
    let totalcount: Int
}

class TopRecentSong: Codable {
    
    let _id: String?
    let labelid: String?
    let artistid: String?
    let albumid: String?
    let songname: String?
    let songlyric: String?
    let songgenre: String?
    let songprice: Float?
    let songprvwpath: String?
    let songprvwname: String?
    let songfilepath: String?
    let songfilename: String?
    let songpublish: String?
    let songbuy: Int?
    let status: String?
    let objartistid: String?
    let objalbumid: String?
    let genrevalue: String?
    let artist: String?
    let album: String?
    let albumphoto: String?
    let albumyear: String?
    
}
