//
//  HomeSongListCollectionViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 14/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class HomeSongListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var albumImage: KxCustomImageView!
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var btnBuyOrDownload: UIButton!
    @IBOutlet weak var btnAddToPlaylist: UIButton!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var addlibImage: UIImageView!
    
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var songPriceLabel: UILabel!
    
    //@IBOutlet weak var progressDownloadView: SpinningProgressView!
    var addToPlaylistTapAction : (()->())?
    var playOrBuyTapAction : (()->())?
    
    private var songData: NSDictionary = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        //self.progressDownloadView.isHidden = true
        self.priceView.layer.cornerRadius = 3
        self.priceView.clipsToBounds = true
        self.priceView.backgroundColor = UIColor(hex: 0x42407a, alpha: 1)
        songPriceLabel.text = ""
        priceView.isHidden = true
        addTapGesture()
    }
    
    func initData(data: NSDictionary) {
        self.songData = data
        setDataCell()
    }
    
    private func setDataCell() {
        let albumImagePath = songData["albumphoto"] as? String
        albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        let songName = songData["songname"] as? String
        songTitleLabel.text = songName!
        artistNameLabel.text = songData["artist"] as? String
        let songPrice = songData["songprice"] as? Double
        let songPriceText = convertToCurrency(amount: songPrice!)
        
        let pcsFlag = songData["pcsflag"] as? String
        if pcsFlag == "N" {
            //playImage.image = UIImage(named: "buy")
            priceView.isHidden = false
            songPriceLabel.text = songPriceText
            
        } else if pcsFlag == "Y" {
            priceView.isHidden = true
            let songcode = songData["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                playImage.image = UIImage(named: "play")
            } else {
                playImage.image = UIImage(named: "download")
            }
            
        } else {
            priceView.isHidden = true
            playImage.image = UIImage(named: "question")
        }
    }
    
    @IBAction func btnBuyOrDownloadPressed(_ sender: UIButton) {
        /*
        print("Buy OR Download Selected Top Song: ")
        print("SongID: \(songData["_id"]!)")
        print("Song Preview: \(songData["songprvwpath"]!)")
        print("Song File: \(songData["songfilepath"]!)")
        */
        //hideInitialButtons()
        
        guard let songUrl = URL(string: songData["songfilepath"] as! String) else {
            return
        }
        
        //let songUrl = URL(string: "https://scholar.princeton.edu/sites/default/files/oversize_pdf_test_0.pdf")!
        
        guard let songId = songData["_id"] else {
            return
        }
        guard let purchaseFlag = songData["pcsflag"] else {
            return
        }
        let songcode = songId as? String
        let songFilename = songcode! + ".kx"
        let pcsFlag = purchaseFlag as? String
        
        if pcsFlag == "Y" {
            priceView.isHidden = true
            if isSongFileExist(filename: songFilename) {
                playOrBuyTapAction?()
            } else {
                goShowDownload(song: self.songData, songUrl: songUrl, songId: songFilename) { (msg) in
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        self.playImage.image = UIImage(named: "play")
                    } else {
                        self.playImage.image = UIImage(named: "download")
                    }
                }
                /*
                self.progressDownloadView.initData(data: self.songData)
                self.progressDownloadView.isHidden = false
                self.progressDownloadView.btnCancelTopConstraint.constant = 20
                //self.progressDownloadView.startAnimation()
                self.progressDownloadView.downloadSong(url: songUrl, songId: songFilename) {_ in 
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        self.playImage.image = UIImage(named: "play")
                    } else {
                        self.playImage.image = UIImage(named: "download")
                    }
                }
               */
            }
            
        } else {
            priceView.isHidden = false
            playOrBuyTapAction?()
        }

    }
    @IBAction func btnAddToPlaylistPressed(_ sender: UIButton) {

        addToPlaylistTapAction?()
        
    }
    
    private func hideInitialButtons() {
        self.btnBuyOrDownload.isHidden = true
        self.btnAddToPlaylist.isHidden = true
        self.playImage.isHidden = true
        self.addlibImage.isHidden = true
    }
    
    private func addTapGesture() {
        
        priceView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPriceIconView(_:))))
    }
    
    @objc func tapPriceIconView(_ sender: UITapGestureRecognizer) {
        
        playOrBuyTapAction?()
        
    }
}
