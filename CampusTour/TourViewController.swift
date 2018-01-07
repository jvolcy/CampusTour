//
//  SecondViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class TourViewController: UIViewController {

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

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
    
    
    @IBAction func btnPlayPauseTouchUpInside(_ sender: Any) {
        var image:UIImage?
        
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
        }
        
        btnPlayPause.setImage(image, for: .normal)
    }
    
    @IBAction func btnRewindTouchUpInside(_ sender: Any) {
    }
    
    @IBAction func btnRePlayTouchUpInside(_ sender: Any) {
    }
    
    @IBAction func btnMapTouchUpInside(_ sender: Any) {
    }
    
}


