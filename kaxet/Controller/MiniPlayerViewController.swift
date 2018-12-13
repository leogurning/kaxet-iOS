//
//  MiniPlayerViewController.swift
//  kaxet
//
//  Created by LEONARD GURNING on 23/10/18.
//  Copyright © 2018 LEONARD GURNING. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftKeychainWrapper
import SVProgressHUD

class MiniPlayerViewController: UIViewController {
    
    let apiServices = RestAPIServices()
    
    let apiUrl = APPURL.BaseURL
    let hostUrl = APPURL.Domain
    
    var accessToken: String = ""
    var userid: String = ""
    
    private var loadUserPlaylistDone: Bool = false
    private var loadUserPlaylistErr: Bool = false
    
    private var songData: NSDictionary = [:]
    private var songfileUrl: URL?
    private var playlistName: String?
    var player1: AVAudioPlayer?
    private var timer = Timer()
    //private var songs:[NSDictionary] = []
    private var songs:NSArray = []
    //private var initIdxSong: Int = 0
    
    private var curIdx: Int = 0
    private var isRepeated: Bool = false
    private var isShuffled: Bool = false
    
    var addButtonTapActionClose : (()->())?
    var showToastError: ((String) -> Void)?
    
    private var userPlaylist: NSArray = []
    private var playlistNPages: Int = 0
    private var fullPlayerConstraintList: [NSLayoutConstraint]?
    
    private let progressActivityIndicator = UIActivityIndicatorView(style: .white)
    /*
     var player:AVPlayer?
     var playerItem:AVPlayerItem?
     var playerLayer:AVPlayerLayer?
     */
    //Outlet of fullplayer
    @IBOutlet weak var fullPlayerView: UIView!
    @IBOutlet weak var albumImageFullPlayer: KxCustomImageView!
    @IBOutlet weak var songTitleLabelFullPlayer: UILabel!
    @IBOutlet weak var artistNameLabelFullPlayer: UILabel!
    @IBOutlet weak var lyricImageView: UIImageView!
    @IBOutlet weak var playbackSliderFullPlayer: UISlider!
    @IBOutlet weak var startDurationLabel: UILabel!
    @IBOutlet weak var endDurationLabel: UILabel!
    @IBOutlet weak var repeatView: UIView!
    @IBOutlet weak var repeatImageView: UIImageView!
    @IBOutlet weak var shuffleView: UIView!
    @IBOutlet weak var shuffleImageView: UIImageView!
    @IBOutlet weak var backwardImageView: UIImageView!
    @IBOutlet weak var playPauseImage: UIImageView!
    @IBOutlet weak var playPauseView: UIView!
    @IBOutlet weak var forwardImageView: UIImageView!
    
    //Outlet of miniplayer
    @IBOutlet weak var miniPlayerView: UIView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var btnPlayPauseTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var playerContentView: UIView!
    @IBOutlet weak var albumContentView: UIView!
    @IBOutlet weak var albumImage: KxCustomImageView!
    @IBOutlet weak var btnClosePlayer: UIButton!
    @IBOutlet weak var btnUpPlayer: UIButton!
    @IBOutlet weak var btnPlayPausePlayer: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        accessToken = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Token)!
        userid = KeychainWrapper.standard.string(forKey: APPCONSTANT.Keychains.Userid)!
        
        //activateMiniPlayer()
        view.translatesAutoresizingMaskIntoConstraints = false
        fullPlayerView.translatesAutoresizingMaskIntoConstraints = false
        miniPlayerView.translatesAutoresizingMaskIntoConstraints = false
        fullPlayerConstraintList = fullPlayerView.constraints
        disableFullPlayerConstraints()
        
        //btnUpPlayer.isHidden = true
        playerContentView.layer.cornerRadius = 5
        albumContentView.layer.cornerRadius = 5
        repeatView.layer.cornerRadius = 17.5
        shuffleView.layer.cornerRadius = 17.5
        playPauseView.layer.cornerRadius = 35
        
        btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
        btnPlayPauseTrailingConstraint.constant = 5
        
        playbackSlider!.minimumValue = 0
        playbackSlider.setThumbImage(UIImage(named: "roundyellow18"), for: .normal)
        
        playPauseImage.image = UIImage(named: "pause")
        playbackSliderFullPlayer.minimumValue = 0
        playbackSliderFullPlayer.setThumbImage(UIImage(named: "roundyellow18"), for: .normal)
        
        resetSlider()
        addTapGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        dismissPlayerProgressIndicator()
        showProgressHud()
        DispatchQueue.global(qos: .userInteractive).async {
            self.getUserPlaylistData(page: 1)
        }
    }
    
    func initData(data: NSDictionary, songUrl: URL?, plistName: String?) {
        
        self.songData = data
        songTitleLabel.text = songData["songname"] as? String
        artistNameLabel.text = songData["artist"] as? String
        
        let albumImagePath = songData["albumphoto"] as? String
        self.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        
        self.albumImageFullPlayer.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImageFullPlayer.layer.cornerRadius = 10
        self.albumImageFullPlayer.clipsToBounds = true
        /*
        if let albumImageURL = URL(string: albumImagePath!) {
            DispatchQueue.global().async {
                let dataImage = try? Data(contentsOf: albumImageURL)
                if let data = dataImage {
                    let albumImage = UIImage(data: data)
                    DispatchQueue.main.async {
                        self.albumImage.image = albumImage
                        self.albumImage.layer.cornerRadius = 5
                        self.albumImage.clipsToBounds = true
                        
                        self.albumImageFullPlayer.image = albumImage
                        self.albumImageFullPlayer.layer.cornerRadius = 10
                        self.albumImageFullPlayer.clipsToBounds = true
                        
                    }
                }
            }
        }
        */
        songTitleLabelFullPlayer.text = songData["songname"] as? String
        artistNameLabelFullPlayer.text = songData["artist"] as? String
        
        if let songUrlPath = songUrl {
            self.songfileUrl = songUrlPath
            if plistName == nil {
                //songs = [["pcsflag":"Y", "URL":songUrlPath]]
                songs = [data]
            }
        }
        if let pylistName = plistName {
            self.playlistName = pylistName
        } else {
            self.playlistName = nil
        }
        isRepeated = false
        repeatView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        isShuffled = false
        shuffleView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        setPlayer(pSongUrl: songUrl)
    }
    
    func initDataWithPlaylist(data: NSDictionary, songUrl: URL?, plistName: String?, playlistData: NSArray?, indexSong: Int?) {
        
        self.songData = data
        songTitleLabel.text = songData["songname"] as? String
        artistNameLabel.text = songData["artist"] as? String
        
        let albumImagePath = songData["albumphoto"] as? String
        self.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        
        self.albumImageFullPlayer.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImageFullPlayer.layer.cornerRadius = 10
        self.albumImageFullPlayer.clipsToBounds = true
        
        songTitleLabelFullPlayer.text = songData["songname"] as? String
        artistNameLabelFullPlayer.text = songData["artist"] as? String
        
        if let songUrlPath = songUrl {
            self.songfileUrl = songUrlPath
            
        }
        
        if plistName == nil {
            songs = [data]
        } else {
            songs = playlistData!
        }
        
        if let pylistName = plistName {
            self.playlistName = pylistName
        } else {
            self.playlistName = nil
        }
        
        if let idxSong = indexSong {
            self.curIdx = idxSong
        }
        
        isRepeated = false
        repeatView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        isShuffled = false
        shuffleView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        setPlayer(pSongUrl: songUrl)
    }
    
    private func setSongData(data: NSDictionary, songUrl: URL?) {
        
        self.songData = data
        songTitleLabel.text = songData["songname"] as? String
        artistNameLabel.text = songData["artist"] as? String
        
        let albumImagePath = songData["albumphoto"] as? String
        self.albumImage.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImage.layer.cornerRadius = 5
        self.albumImage.clipsToBounds = true
        
        self.albumImageFullPlayer.loadImageUsingUrlString(urlString: albumImagePath)
        self.albumImageFullPlayer.layer.cornerRadius = 10
        self.albumImageFullPlayer.clipsToBounds = true
        
        songTitleLabelFullPlayer.text = songData["songname"] as? String
        artistNameLabelFullPlayer.text = songData["artist"] as? String
        
        if let songUrlPath = songUrl {
            self.songfileUrl = songUrlPath
        }
        
        setPlayer(pSongUrl: songUrl)
        
    }
    private func setPlayer(pSongUrl: URL?) {
        var currentSongUrl: URL?
        
        var seconds = 0.0, mySecs = 0, myMins = 0
        showPlayerProgressIndicator()
        if let activeSongUrl = pSongUrl {
            currentSongUrl = activeSongUrl
            self.btnUpPlayer.isHidden = false
            btnPlayPauseTrailingConstraint.constant = 40
        } else {
            let albumPreviewPath = songData["songprvwpath"] as? String
            if let albumPreviewURL = URL(string: albumPreviewPath!) {
                currentSongUrl = albumPreviewURL
                self.btnUpPlayer.isHidden = true
                btnPlayPauseTrailingConstraint.constant = 5
            } else {
                return
            }
        }
        
        DispatchQueue.global().async {
            let dataPreview = try? Data(contentsOf: currentSongUrl!)
            if let data = dataPreview {
                do {
                    try self.player1 = AVAudioPlayer(data: data)
                    self.player1!.play()
                    let duration = self.player1!.duration
                    seconds = duration
                    
                    mySecs = Int(seconds) % 60
                    myMins = Int(seconds / 60)
                    
                    //let myTimes = String(myMins) + ":" + String(mySecs);
                    let myTimes = String(format: "%02d:%02d", myMins, mySecs)
                    DispatchQueue.main.async {
                        self.durationLabel.text = myTimes
                        self.btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
                        self.playbackSlider!.maximumValue = Float(seconds)
                        self.playbackSlider!.isContinuous = false
                        self.playbackSlider!.tintColor = UIColor.green
                        
                        self.endDurationLabel.text = myTimes
                        self.playPauseImage.image = UIImage(named: "pause")
                        self.playbackSliderFullPlayer!.maximumValue = Float(seconds)
                        self.playbackSliderFullPlayer!.isContinuous = false
                        self.playbackSliderFullPlayer!.tintColor = UIColor.green
                        
                        self.startTimer()
                    }
                } catch {
                    print("ERROR")
                    DispatchQueue.main.async {
                        self.dismissPlayerProgressIndicator()
                    }
                    self.showToastError?("App Player Error. Try again later...")
                }
                
            } else {
                DispatchQueue.main.async {
                    self.dismissPlayerProgressIndicator()
                }
            }
        }

    }
    
    func playSong(songIdx: Int) {
        //var playSongUrl: URL?
        resetSlider()
        timer.invalidate()
        let activeSong = songs[songIdx] as? NSDictionary
        //let pcsIndicator = activeSong!["pcsflag"] as? String
        let songcode = activeSong!["_id"] as? String
        let songDownloaded = isSongDownloaded(songcode: songcode)
        if songDownloaded {
            let songPathURL = getSongDownloadedUrl(songcode: songcode)
            setSongData(data: activeSong!, songUrl: songPathURL)

        } else {
            setSongData(data: activeSong!, songUrl: nil)
        }
        /*
        if pcsIndicator == "Y" {
            playSongUrl = activeSong!["URL"] as? URL
            
        } else {
            //If the song not yet downloaded, Url must be songprvwpath
        }
 
        resetSlider()
        setPlayer(pSongUrl: playSongUrl)
        */
    }
    
    func nextSong() {
        var activeIdx: Int?
        if isShuffled {
            activeIdx = Int(arc4random_uniform(UInt32(songs.count)))
        } else {
            activeIdx = self.curIdx + 1
        }
        if activeIdx! <= songs.count - 1 {
            self.curIdx = activeIdx!
            playSong(songIdx: activeIdx!)
        }
        else {
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "This is already the last song !")
            }
            
        }
    }
    
    func prevSong() {
        var activeIdx: Int?
        if isShuffled {
            activeIdx = Int(arc4random_uniform(UInt32(songs.count)))
        } else {
            activeIdx = self.curIdx - 1
        }
        if activeIdx! >= 0 {
            self.curIdx = activeIdx!
            playSong(songIdx: activeIdx!)
        }
        else {
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "This is the first song !")
            }
            
        }
    }
    
    func setRepeat() {
        if isRepeated {
            isRepeated = false
            repeatView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        } else {
            isRepeated = true
            repeatView.backgroundColor = UIColor(hex: 0xFCE86C, alpha:1)
        }
        
    }
    
    func setShuffle() {
        if isShuffled {
            isShuffled = false
            shuffleView.backgroundColor = UIColor(hex: 0xEFEFF4, alpha:1)
        } else {
            isShuffled = true
            shuffleView.backgroundColor = UIColor(hex: 0xFCE86C, alpha:1)
        }
        
    }
    
    func resetSlider() {
        durationLabel.text = "0"
        playbackSlider.value = 0
        
        startDurationLabel.text = "0"
        playbackSliderFullPlayer.value = 0
    }
    
    func startTimer() {
        
        DispatchQueue.main.async {
            self.dismissPlayerProgressIndicator()
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateViewsWithTimer(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func updateViewsWithTimer(_: Timer){
        updateViews()
    }
    
    func updateViews(){
        if self.player1 != nil {
            //let time : Float64 = CMTimeGetSeconds(self.player!.currentTime());
            let time = self.player1!.currentTime
            self.playbackSlider!.value = Float ( time )
            self.playbackSliderFullPlayer!.value = Float( time )
            
            let updateDuration = self.player1!.duration - time
            let mySecs = Int(updateDuration) % 60
            let myMins = Int(updateDuration / 60)
            let myTimes2 = String(format: "%02d:%02d", myMins, mySecs)
            self.durationLabel.text = myTimes2
            
            let mySecs2 = Int(time) % 60
            let myMins2 = Int(time / 60)
            let myTimes = String(format: "%02d:%02d", myMins2, mySecs2)
            self.startDurationLabel.text = myTimes
            
            if self.player1?.isPlaying == false {
                self.btnPlayPausePlayer.setImage(UIImage(named: "play-miniplayer"), for: .normal)
                self.playPauseImage.image = UIImage(named: "play")
                if time == 0 {
                    self.startDurationLabel.text = "00:00"
                    if self.playlistName == nil {
                        if curIdx == songs.count - 1 {
                            if isRepeated {
                                curIdx = 0
                                playSong(songIdx: curIdx)
                            }
                        }
                        return
                    //If there is playlist song
                    } else {
                        
                        //If already in the last song
                        if curIdx == songs.count - 1 {
                            //If isRepeated is Yes, start playing first song
                            if isRepeated {
                                curIdx = 0
                                timer.invalidate()
                                playSong(songIdx: curIdx)
                                return
                            }
                            return
                        //Not the last song. play next song
                        } else {
                            timer.invalidate()
                            nextSong()
                            return
                        }
                        
                    }
                }
            }
        }
    }

    func stopSong() {
        
        if self.player1 != nil {
            if self.player1!.isPlaying {
                self.player1!.stop()
                self.player1 = nil
                self.songfileUrl = nil
                self.playlistName = nil
                resetSlider()
                timer.invalidate()
            }
        }
    }
    
    private func showPlayerProgressIndicator() {
        
         //Position in the center
         progressActivityIndicator.center = view.center
         
         //If needed you can prevent activity Indicator from hiding when stopAnimating is calling
         progressActivityIndicator.hidesWhenStopped = false
         
         //Start myActivityIndicator
         progressActivityIndicator.startAnimating()
        if miniPlayerView.isHidden == false {
            miniPlayerView.addSubview(progressActivityIndicator)
            //This is for disable all input and button while spinning indicator
            miniPlayerView.isUserInteractionEnabled = false
        }
        if fullPlayerView.isHidden == false {
            fullPlayerView.addSubview(progressActivityIndicator)
            fullPlayerView.isUserInteractionEnabled = false
        }
         //UIApplication.shared.beginIgnoringInteractionEvents()
        
    }
    
    private func dismissPlayerProgressIndicator() {
        
        removeActivityIndicator(activityIndicator: progressActivityIndicator)
        
        DispatchQueue.main.async {
            //UIApplication.shared.endIgnoringInteractionEvents()
            self.miniPlayerView.isUserInteractionEnabled = true
            self.fullPlayerView.isUserInteractionEnabled = true
        }
        
    }
    
    @IBAction func btnClosePlayerPressed(_ sender: UIButton) {
        
        stopSong()
        timer.invalidate()
        addButtonTapActionClose?()
    }
    
    @IBAction func btnUpPlayerPressed(_ sender: UIButton) {
        activateFullPlayer()
        
        
    }
    
    @IBAction func btnPlayPausePlayerPressed(_ sender: UIButton) {
        
        if self.player1!.isPlaying
        {
            self.player1!.pause()
            self.btnPlayPausePlayer.setImage(UIImage(named: "play-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "play")
            //playButton!.setTitle("Play", for: UIControlState.normal)
            
        } else {
            self.player1!.play()
            self.btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "pause")
            //playButton!.setTitle("Pause", for: UIControlState.normal)
        }
        
    }
    
    @IBAction func playbackSliderChange(_ sender: UISlider) {
        DispatchQueue.main.async {
            self.player1?.stop()
            self.player1?.currentTime = TimeInterval(self.playbackSliderFullPlayer.value)
            self.playbackSlider.value = self.playbackSliderFullPlayer.value
            self.player1?.prepareToPlay()
            self.player1?.play()
            self.updateViews()
            self.btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "pause")
        }
        
    }
    
    
    @IBAction func playbackMiniSliderChange(_ sender: UISlider) {
        DispatchQueue.main.async {
            self.player1?.stop()
            self.player1?.currentTime = TimeInterval(self.playbackSlider.value)
            self.playbackSliderFullPlayer.value = self.playbackSlider.value
            self.player1?.prepareToPlay()
            self.player1?.play()
            self.updateViews()
            self.btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "pause")
        }
    }
    
    @IBAction func btnAddToPlaylistPressed(_ sender: UIBarButtonItem) {
        let parentView = self.parent as! StartViewController
        if parentView.toolbarView.isHidden {
            DispatchQueue.main.async {
                ToastMessageView.shared.long(self.view, txt_msg: "You are not allowed to do this action due to there is pending action in the previous screen.")
            }
            
        } else {
            self.addToPlaylist()
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        switch segue.identifier {
        case "goToLyric":
            let destinationVC = segue.destination as! DisplayLyricViewController
            let lyric = songData["songlyric"] as? String
            if let songLyric = lyric {
                destinationVC.songLyric = songLyric
            }
        case "goToAddToPlaylist":
            // Create a new variable to store the instance of PlayerTableViewController
            let destinationVC = segue.destination as! AddToPlaylistViewController
            destinationVC.initData(song: songData, playlist: userPlaylist, npages: playlistNPages)
            
        case "goToAddToPlaylistInit":
            // Create a new variable to store the instance of PlayerTableViewController
            let destinationVC = segue.destination as! AddToPlaylistInitViewController
            destinationVC.initData(data: songData)
        default:
            break
        }
        // Pass the selected object to the new view controller.
    }
 
    
    @IBAction func btnDismissFullPlayer(_ sender: UIBarButtonItem) {
        activateMiniPlayer()
    }
    
    
    func activateMiniPlayer() {
        
        miniPlayerView.isHidden = false
        
        disableFullPlayerConstraints()
        fullPlayerView.isHidden = true
        let parentView = self.parent as! StartViewController
        parentView.playerViewBottomConstraint.constant = 60
        parentView.playerViewHeightConstraint.constant = 70
        
    }
    
    func activateFullPlayer() {
        let parentView = self.parent as! StartViewController
        parentView.playerViewBottomConstraint.constant = 6
        parentView.playerViewHeightConstraint.constant = parentView.mainContainerView.frame.height + 74 + parentView.toolbarView.frame.height
        self.albumImageFullPlayer.layer.cornerRadius = 10
        self.albumImageFullPlayer.clipsToBounds = true
        fullPlayerView.isHidden = false
        miniPlayerView.isHidden = true
        enableFullPlayerConstraints()
    }
    
    func enableFullPlayerConstraints() {
        fullPlayerView.addConstraints(fullPlayerConstraintList!)
    }
    
    func disableFullPlayerConstraints() {
        let fullPlayerConstraints = fullPlayerView.constraints
        for constraintItem in fullPlayerConstraints {
            constraintItem.isActive = false
        }
    }
    
    func addTapGesture() {
        let playPauseTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(playPauseImageTapped(tapGestureRecognizer:)))
        playPauseImage.isUserInteractionEnabled = true
        playPauseImage.addGestureRecognizer(playPauseTapGestureRecognizer)
        
        let nextSongTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(nextSongImageTapped(tapGestureRecognizer:)))
        
        forwardImageView.isUserInteractionEnabled = true
        forwardImageView.addGestureRecognizer(nextSongTapGestureRecognizer)
        
        let prevSongTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(prevSongImageTapped(tapGestureRecognizer:)))
        
        backwardImageView.isUserInteractionEnabled = true
        backwardImageView.addGestureRecognizer(prevSongTapGestureRecognizer)
        
        let repeatSongTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(repeatSongImageTapped(tapGestureRecognizer:)))
        
        repeatView.isUserInteractionEnabled = true
        repeatView.addGestureRecognizer(repeatSongTapGestureRecognizer)
        
        let shuffledSongTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shuffledSongImageTapped(tapGestureRecognizer:)))
        
        shuffleView.isUserInteractionEnabled = true
        shuffleView.addGestureRecognizer(shuffledSongTapGestureRecognizer)
        
        let displayLyricTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(displayLyricImageTapped(tapGestureRecognizer:)))
        
        lyricImageView.isUserInteractionEnabled = true
        lyricImageView.addGestureRecognizer(displayLyricTapGestureRecognizer)
        
    }
    
    @objc func playPauseImageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if self.player1!.isPlaying
        {
            self.player1!.pause()
            self.btnPlayPausePlayer.setImage(UIImage(named: "play-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "play")
            //playButton!.setTitle("Play", for: UIControlState.normal)
            
        } else {
            self.player1!.play()
            self.btnPlayPausePlayer.setImage(UIImage(named: "pause-miniplayer"), for: .normal)
            self.playPauseImage.image = UIImage(named: "pause")
            //playButton!.setTitle("Pause", for: UIControlState.normal)
        }
    }
    
    @objc func nextSongImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        nextSong()
    }
    
    @objc func prevSongImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        prevSong()
    }
    
    @objc func repeatSongImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        setRepeat()
    }
    
    @objc func shuffledSongImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        setShuffle()
    }
    
    @objc func displayLyricImageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: "goToLyric", sender: self)
    }
    
    private func addToPlaylist() {
        
        if self.userPlaylist.count <= 0 {
            self.performSegue(withIdentifier: "goToAddToPlaylistInit", sender: self)
        } else {
            self.performSegue(withIdentifier: "goToAddToPlaylist", sender: self)
        }
    }
    
    func getUserPlaylistData(page: Int) {
        
        self.loadUserPlaylistDone = false
        
        //Send HTTP request to get playlist
        let strUrl = apiUrl + "/userpl/\(userid)?page=\(page)"
        
        apiServices.executePostRequestWithToken(urlToExecute: strUrl, bodyDict: nil) { (jsonResponse, error) in
            
            if error != nil {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.closeProgressHud()
                DispatchQueue.main.async {
                    ToastMessageView.shared.long(self.view, txt_msg: "Server Error or Disconnected. Please try again later.")
                }
                
                return
            }
            
            guard let responseDict = jsonResponse else {
                print("error= \(String(describing: error))")
                self.loadUserPlaylistDone = true
                self.closeProgressHud()
                DispatchQueue.main.async {
                    ToastMessageView.shared.long(self.view, txt_msg: "App Error. Please try again later.")
                }
                
                return
            }
            
            let success = responseDict["success"] as? Bool
            if success! {
                
                self.playlistNPages = responseDict["npage"] as! Int
                if let dataResult = responseDict["data"] as? NSArray {
                    self.userPlaylist = dataResult
                }
                
            } else {
                let message = responseDict["message"] as? String
                print(message!)
                if let expToken = responseDict["errcode"] as? String {
                    if expToken == "exp-token" {
                        self.loadUserPlaylistErr = true
                    }
                }
            }
            
            self.loadUserPlaylistDone = true
            self.closeProgressHud()
            
        }
        
    }
    
    func closeProgressHud() {
        
        if ( loadUserPlaylistDone ) {
            
            DispatchQueue.main.async {
                dismissProgressHud()
            }

        }
        
    }
}
