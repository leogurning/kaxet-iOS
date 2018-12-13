//
//  PlaylistSongListTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 03/12/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class PlaylistSongListTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var buyOrDownloadView: UIView!
    @IBOutlet weak var buyOrDownloadImageView: UIImageView!
    @IBOutlet weak var deleteSongPlaylistView: UIView!
    @IBOutlet weak var deleteSongPlaylistImageView: UIImageView!
    
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var songPriceLabel: UILabel!
    
    var removeFrPlaylistTapAction : (()->())?
    var playOrBuyTapAction : (()->())?
    
    private var songData: NSDictionary = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        albumImage.image = UIImage(named: "kxlogo")
        albumImage.layer.cornerRadius = 5
        albumImage.clipsToBounds = true
        self.priceView.layer.cornerRadius = 3
        self.priceView.clipsToBounds = true
        self.priceView.backgroundColor = UIColor(hex: 0x42407a, alpha: 1)
        songPriceLabel.text = ""
        priceView.isHidden = true
        addTapGesture()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func btnBuyOrDownloadPressed(_ sender: UIButton) {
        guard let songUrl = URL(string: songData["songfilepath"] as! String) else {
            return
        }
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
                        self.buyOrDownloadImageView.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImageView.image = UIImage(named: "download")
                    }
                }
                
            }
            
        } else {
            priceView.isHidden = false
            playOrBuyTapAction?()
        }
    }
    
    func initData(data: NSDictionary) {
        self.songData = data
        self.setDataCell()
    }
    
    private func setDataCell() {
        let songTitle = songData["songname"] as? String
        let artistName = songData["artist"] as? String
        let albumImagePath = songData["albumphoto"] as? String
        let songPrice = songData["songprice"] as? Double
        let songPriceText = convertToCurrency(amount: songPrice!)
        
        albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        songTitleLabel.text = songTitle!
        artistNameLabel.text = artistName!
        
        let pcsFlag = songData["pcsflag"] as? String
        if pcsFlag == "N" {
            priceView.isHidden = false
            songPriceLabel.text = songPriceText
        } else if pcsFlag == "Y" {
            priceView.isHidden = true
            let songcode = songData["_id"] as? String
            let songDownloaded = isSongDownloaded(songcode: songcode)
            if songDownloaded {
                buyOrDownloadImageView.image = UIImage(named: "play")
            } else {
                buyOrDownloadImageView.image = UIImage(named: "download")
            }
            
        } else {
            priceView.isHidden = true
            buyOrDownloadImageView.image = UIImage(named: "question")
        }
    }
    
    private func addTapGesture() {
        
        let buyOrDownloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(buyOrDownloadImageTapped(tapGestureRecognizer:)))
        /*
        buyOrDownloadView.isUserInteractionEnabled = true
        buyOrDownloadView.addGestureRecognizer(buyOrDownloadTapGestureRecognizer)
        buyOrDownloadImageView.isUserInteractionEnabled = true
        buyOrDownloadImageView.addGestureRecognizer(buyOrDownloadTapGestureRecognizer)
        */
        priceView.isUserInteractionEnabled = true
        priceView.addGestureRecognizer(buyOrDownloadTapGestureRecognizer)
        
        let removeFrPlaylistTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeFrPlaylistImageTapped(tapGestureRecognizer:)))
        deleteSongPlaylistView.isUserInteractionEnabled = true
        deleteSongPlaylistView.addGestureRecognizer(removeFrPlaylistTapGestureRecognizer)
        deleteSongPlaylistImageView.isUserInteractionEnabled = true
        deleteSongPlaylistImageView.addGestureRecognizer(removeFrPlaylistTapGestureRecognizer)
        
    }
    
    @objc func removeFrPlaylistImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        removeFrPlaylistTapAction?()
    }
    
    @objc func buyOrDownloadImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        guard let songUrl = URL(string: songData["songfilepath"] as! String) else {
            return
        }
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
                        self.buyOrDownloadImageView.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImageView.image = UIImage(named: "download")
                    }
                }

            }
            
        } else {
            priceView.isHidden = false
            playOrBuyTapAction?()
        }
    }
}
