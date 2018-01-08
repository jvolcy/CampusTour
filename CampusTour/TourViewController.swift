//
//  TourViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class TourViewController: UIViewController {

    @IBOutlet weak var txtTourInfo: UITextView!
    @IBOutlet weak var btnMap: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnRePlay: UIButton!
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet var viewTourImage: UIImageView!
    
    var AVStreamer:CAVStreamer!

    //enumera possible media states
    enum EMediaState {case stopped, playing, finished, paused, unknown}
    //set the default media state
    var mediaState:EMediaState = .stopped
    
    //enumerate the tour modes
    enum ETourMode {case map, walk}
    //set the default tour mode
    var tourMode:ETourMode = .walk
    
    /* =========================================================================
     ======================================================================== */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("TourViewController viewDidLoad")
        campusTour!.subscribeForNewCoordNotification(f:self.callback)
        
        //instantiate the A/V Streamer
        AVStreamer = CAVStreamer()

        //fix aspect ratio problem with images in the buttons (not settable throug IB)
        btnPlayPause.imageView?.contentMode = .scaleAspectFit
        btnRePlay.imageView?.contentMode = .scaleAspectFit
        btnRewind.imageView?.contentMode = .scaleAspectFit
        btnMap.imageView?.contentMode = .scaleAspectFit
    }

    /* =========================================================================
     ======================================================================== */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /* =========================================================================
     ======================================================================== */
    func callback(coord:gps_coord)->(){
        print("TourView callback: \(coord.toString())")
    }

    
    /* =========================================================================
     ======================================================================== */
    func playMedia(url:String)
    {
        let avView = AVStreamer.playMedia(url:url, outputUIViewWidth:viewTourImage.bounds.size.width, outputUIViewHeight: viewTourImage.bounds.size.height, showPlaybackControls:false)
        
        if let view = avView {
            viewTourImage.addSubview(view)
            //viewMain.sendSubview(toBack: view)
        }
    }
    
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnPlayPauseTouchUpInside(_ sender: Any) {
        var image:UIImage?
        
        switch mediaState {
        case .playing:
            image = UIImage(named: "play")
            mediaState = .paused
            AVStreamer.pause()
        case .paused:
            AVStreamer.unpause()
            image = UIImage(named: "pause")
            mediaState = .playing
        default:
            image = UIImage(named: "pause")
            mediaState = .playing
            playMedia(url: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.mp4")
            displayAttributedTextFromURL(rtfFileUrl: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.rtf", targetView: txtTourInfo)
        }

/*
        if mediaState == .playing {
            image = UIImage(named: "play")
            mediaState = .paused
            AVStreamer.pause()
        }
        else if mediaState == .paused {
            AVStreamer.unpause()
            image = UIImage(named: "pause")
            mediaState = .playing
        }
        else {
            image = UIImage(named: "pause")
            mediaState = .playing
            playMedia(url: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.mp4")
            displayAttributedTextFromURL(rtfFileUrl: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.rtf", targetView: txtTourInfo)
        }
*/
        btnPlayPause.setImage(image, for: .normal)
    }

    
    
    /* =========================================================================
     This function reads the contents of an RTF file through the supplied URL.
     The function then sends the attributed text to the supplied UITextView.
     ======================================================================== */
    func displayAttributedTextFromURL(rtfFileUrl:String, targetView:UITextView) {
        
        //extract the data from the POI file and create an array of POIs.
        if let url = URL(string: rtfFileUrl) {
            do {
                //read the data from the rtf file
                let data = try Data(contentsOf: url)
                
                //convert the data into an atrributed string
                let richText = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
                
                //display in the textfiled (which must be configured for attributed text, not plain text)
                targetView.attributedText = richText
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of \(rtfFileUrl)")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL for \(rtfFileUrl)")
        }
    }

    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnRewindTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnRePlayTouchUpInside(_ sender: Any) {
        AVStreamer.replay()
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnMapTouchUpInside(_ sender: Any) {
        var image:UIImage?
        
        switch tourMode {
        case .map:
            image = UIImage(named: "film")
            tourMode = .walk
        case .walk:
            image = UIImage(named: "map")
            tourMode = .map
        }   //switch
        
        btnMap.setImage(image, for: .normal)

    }   //func
    
}


