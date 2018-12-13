//
//  SongListTableViewCell.swift
//  kaxet
//
//  Created by LEONARD GURNING on 20/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit

class SongListTableViewCell: UITableViewCell {

    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var btnBuyOrDownload: UIButton!
    @IBOutlet weak var btnAddToPlaylist: UIButton!
    @IBOutlet weak var buyOrDownloadImage: UIImageView!
    @IBOutlet weak var addPlaylistImage: UIImageView!
    @IBOutlet weak var progressDownloadView: SpinningProgressView!
    @IBOutlet weak var numberView: UIView!
    @IBOutlet weak var numberSongLabel: UILabel!
    @IBOutlet weak var priceView: UIView!
    @IBOutlet weak var songPriceLabel: UILabel!
    
    var addToPlaylistTapAction : (()->())?
    var playOrBuyTapAction : (()->())?
    
    private var songData: NSDictionary = [:]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        self.progressDownloadView.isHidden = true
        
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
                buyOrDownloadImage.image = UIImage(named: "play")
            } else {
                buyOrDownloadImage.image = UIImage(named: "download")
            }
            
        } else {
            priceView.isHidden = true
            buyOrDownloadImage.image = UIImage(named: "question")
        }
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
                        self.buyOrDownloadImage.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImage.image = UIImage(named: "download")
                    }
                }
                /*
                self.progressDownloadView.initData(data: self.songData)
                self.progressDownloadView.isHidden = false
                //self.progressDownloadView.startAnimation()
                self.progressDownloadView.downloadSong(url: songUrl, songId: songFilename) { _ in
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        self.buyOrDownloadImage.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImage.image = UIImage(named: "download")
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
    
    func addTapGesture() {
        let buyOrDownloadTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(buyOrDownloadImageTapped(tapGestureRecognizer:)))
        /*
        buyOrDownloadImage.isUserInteractionEnabled = true
        buyOrDownloadImage.addGestureRecognizer(buyOrDownloadTapGestureRecognizer)
        */
        priceView.isUserInteractionEnabled = true
        priceView.addGestureRecognizer(buyOrDownloadTapGestureRecognizer)
        
        let addToPlaylistTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addToPlaylistImageTapped(tapGestureRecognizer:)))
        addPlaylistImage.isUserInteractionEnabled = true
        addPlaylistImage.addGestureRecognizer(addToPlaylistTapGestureRecognizer)
        
    }
    
    @objc func addToPlaylistImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        addToPlaylistTapAction?()
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
                        self.buyOrDownloadImage.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImage.image = UIImage(named: "download")
                    }
                }
                /*
                self.progressDownloadView.initData(data: self.songData)
                self.progressDownloadView.isHidden = false
                //self.progressDownloadView.startAnimation()
                self.progressDownloadView.downloadSong(url: songUrl, songId: songFilename) { _ in
                    let songDownloaded = isSongDownloaded(songcode: songcode)
                    if songDownloaded {
                        self.buyOrDownloadImage.image = UIImage(named: "play")
                    } else {
                        self.buyOrDownloadImage.image = UIImage(named: "download")
                    }
                }
                */
            }
            
        } else {
            priceView.isHidden = false
            playOrBuyTapAction?()
        }
    }
    
    private func hideInitialButtons() {
        self.btnBuyOrDownload.isHidden = true
        self.btnAddToPlaylist.isHidden = true
        self.buyOrDownloadImage.isHidden = true
        self.addPlaylistImage.isHidden = true
    }
}
