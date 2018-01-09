//
//  TourViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class TourViewController: UIViewController {

    @IBOutlet weak var txtTourInfo: UITextView! //main tour information attributed text display
    @IBOutlet weak var btnMap: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnRePlay: UIButton!
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet var imgTourImage: UIImageView!    //central display of the tour view
    /*HStackTitleAndCheck is a horizontal stack view that contais the title and
     check image at the top of the tour view.  Taken together, these 2 objects
     occupy the same space as imgTopLogoBar.  Therefore, by controlling the
     visibility of HStackTitleAndCheck and imgTopLogoBar, we can control wich
     will be visible to the user. */
    @IBOutlet weak var hStackTitleAndCheck: UIStackView!
    @IBOutlet weak var lblTitle: UILabel!   //child of hStackTitleAndCheck
    @IBOutlet weak var imgCheck: UIImageView!   //child of hStackTitleAndCheck
    @IBOutlet weak var imgTopLogoBar: UIImageView!  //occupies same physical location as hStackTitleAndCheck
    
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
        //campusTour!.subscribeForNewCoordNotification(f:self.callback)
        
        //instantiate the A/V Streamer
        AVStreamer = CAVStreamer()

        //fix aspect ratio problem with images in the buttons (not settable throug IB)
        btnPlayPause.imageView?.contentMode = .scaleAspectFit
        btnRePlay.imageView?.contentMode = .scaleAspectFit
        btnRewind.imageView?.contentMode = .scaleAspectFit
        btnMap.imageView?.contentMode = .scaleAspectFit
        
        //default to logo display
        displayTopLogo(coverTitleAndCheck: true)
    }

    /* =========================================================================
     This function is used to toggle the contents of the blue bar at the top
     of the tour view.  An argument of true will cover the title and check
     mark and display the logo.  false covers the logo and displays the title
     and check mark.
     
     The blue bar at the top of the screen may display either the college
     logo (when there is no POI in range) or, in order of priority:
     1) the title of the nearest unexplored POI in range (there may be more
     than 1 in range)
     2) the title of the nearest POI
     Along with the title, there is also a check mark graphic that indicates
     whether or not a POI has been explored (green check), partially
     explored (empty check) or unexplored (no check).  A partially explored
     POI is one where the corresponding media has not played to completion.
     ======================================================================== */
    func displayTopLogo(coverTitleAndCheck:Bool)
    {
        imgTopLogoBar.isHidden = !coverTitleAndCheck
        hStackTitleAndCheck.isHidden = coverTitleAndCheck
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
     This function attempts to play the media (audio or video) at the
     supplied URL to the supplied UIView.  For audio, pass a nil value
     for the UIView
     ======================================================================== */
    func playMedia(url:String, outputView:UIView?)
    {
        if let outView = outputView {
            // a UIView window has been supplied.  Use it for video output
            let avView = AVStreamer.playMedia(url:url, outputUIViewWidth:outView.bounds.size.width, outputUIViewHeight: outView.bounds.size.height, showPlaybackControls:false)
            
            if let view = avView {
                outView.addSubview(view)
                //viewMain.sendSubview(toBack: view)
                }
        }
        else {
            // no UIView was supplied; assume this is audio.  We do not need the returned UIView value
            AVStreamer.playMedia(url:url, showPlaybackControls:false)
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
            playMedia(url: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.mp4", outputView: imgTourImage)
            //playMedia(url: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.mp3", outputView: nil)
            displayAttributedTextFromURL(rtfFileUrl: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.rtf", targetView: txtTourInfo)
        }

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


