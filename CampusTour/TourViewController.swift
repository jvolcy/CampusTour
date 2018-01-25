//
//  TourViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit
import AVKit
import CoreLocation

class TourViewController: UIViewController {
    

    @IBOutlet weak var txtTourInfo: UITextView! //main tour information attributed text display
    @IBOutlet weak var btnMapMediaStop: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnGpsOnOff: UIButton!
    @IBOutlet weak var btnRePlay: UIButton!
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet var imgTourImage: UIImageView!    //central display of the tour view
    @IBOutlet weak var lblGpsCoord: UILabel!
    @IBOutlet weak var vStackJoyStick: UIStackView!
    @IBOutlet weak var viewTour: UIView!
    @IBOutlet weak var imgMarker: UIImageView!
    @IBOutlet weak var imgBuildings: UIImageView!
    
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
    var avView:UIView? = nil        //a currently playing view unless it is nil
    
    //info on the currently playing POI media
    private var startOfPauseTime = 0.0
    private var currentPoi:CPoi!
    
    //enumerate possible media states
    enum EMediaState {case stopped, playing, finished, paused, unknown}
    //set the default media state
    var mediaState:EMediaState = .stopped
    var defaultRichText:NSAttributedString!
    
    //enumerate the tour modes
    enum ETourMode {case map, walk, notSet}
    //set the default tour mode
    var tourMode:ETourMode = .notSet
    
    //GPS status
    var gpsOn:Bool!
    private var gpsLastUpdateTime = 0.0

 
    // ---------------------- START CAMPUS MAP DATA ----------------------------
    /*  Get image calibration information from the config file.
     The data in this section is specific to the image file campus_map.png.
     This file is 4538 × 3956 and 3,564,877 bytes.  Using a different campus
     image file will require updating the config file ct_config.json. */
    var CAMPUS_IMG_SIZE_X:Double!     //4538
    var CAMPUS_IMG_SIZE_Y:Double!   //3956
    
    var CAL_POINT1_X:Double!      //540
    var CAL_POINT1_Y:Double!    //454
    var CAL_POINT1_LAT:Double!    //33.746832
    var CAL_POINT1_LON:Double!    //-84.413719

    var CAL_POINT2_X:Double!    //3551
    var CAL_POINT2_Y:Double!    //2631
    var CAL_POINT2_LAT:Double!    //33.744402
    var CAL_POINT2_LON:Double!    //-84.409692
    
    var CAMPUS_LEFT_LONGITUDE:Double!
    var CAMPUS_RIGHT_LONGITUDE:Double!
    var CAMPUS_TOP_LATITUDE:Double!
    var CAMPUS_BOTTOM_LATITUDE:Double!

    var CAMPUS_LATITUDE:Double!
    var CAMPUS_LONGITUDE:Double!
    
    //load the default location from the config file (currently the Cosby parking lot)
    var DEFAULT_LOCATION:CLLocation!
    
    // ---------------------- END CAMPUS MAP DATA ------------------------------
    
    
    //---------- joystick controls constants ----------
    var JOYSTICK_X_INC:Double!
    var JOYSTICK_Y_INC:Double!

    var bToggleMarkerImage = true
    
    /* =========================================================================
     ======================================================================== */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //load configuration data
        loadConfig()
        
        //set the default GPS mode
        turnGpsOn(on: true)

        //set the default tour mode
        setTourMode(.walk)
        
        vStackJoyStick.isHidden = true
        lblGpsCoord.isHighlighted = true
        
        if SCCT_DebugMode == true {
            /* set the default location to the center of the map if we are in debug mode. */
            latestGpsLocation = DEFAULT_LOCATION
            setMarker(coord: latestGpsLocation)
            lblGpsCoord.isHidden = false
        }
        
        if GPS_DebugMode == true {
            vStackJoyStick.isHidden = false
        }
        else {
            vStackJoyStick.isHidden = true
        }
        
        //pre-load the default RTF
        defaultRichText = getDefaultRichText(defaultRtfUrl: appConfig["baseUrl"]! + appConfig["defaultTourRtf"]!)
        txtTourInfo.attributedText = defaultRichText
        txtTourInfo.scrollRangeToVisible(NSMakeRange(0, 0)) //force scroll to the top
        
        //instantiate the A/V Streamer
        AVStreamer = CAVStreamer()

        //fix aspect ratio problem with images in the buttons (not settable throug IB)
        btnPlayPause.imageView?.contentMode = .scaleAspectFit
        btnRePlay.imageView?.contentMode = .scaleAspectFit
        btnRewind.imageView?.contentMode = .scaleAspectFit
        btnMapMediaStop.imageView?.contentMode = .scaleAspectFit
        btnGpsOnOff.imageView?.contentMode = .scaleAspectFit
        
        //default to logo display
        displayTopLogo(coverTitleAndCheck: true)
        
        //add a tap gesture recognizer to the building image
        let imgBuildingGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleImgBuildingsTap(recognizer:)))
        
        imgBuildings.addGestureRecognizer(imgBuildingGestureRecognizer)
        imgBuildingGestureRecognizer.numberOfTapsRequired = 1
        imgBuildingGestureRecognizer.numberOfTouchesRequired = 1
        imgBuildings.isUserInteractionEnabled = true

        
        /* register for notification when an AVPalerItem has finished playing.  Note that
         notification will not be sent if the player is stopped.  We will use the
         default application notification center*/
        NotificationCenter.default.addObserver(self,
                            selector: #selector(mediaPlayBackFinished(_:)),
                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                            object: nil);
        
        /* sign up for notification from location services.  This notification
         is a custom notification that tell us that a newly update GPS
         location is available */
        NotificationCenter.default.addObserver(self,
                            selector: #selector(gotNewLocationFromLocationServices(_:)),
                            name: locationServicesUpdatedLocations,
                            object: nil);
        
        
        
    }
    
    /* =========================================================================
     Add a deinit to this class to remove it from the default notification
     center
     ======================================================================== */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /* =========================================================================
     this function loads configuration data from the configuration file
     ======================================================================== */
    func loadConfig() {
        
        // ---------------------- START CAMPUS MAP DATA ----------------------------
        /*  Get image calibration information from the config file.
         The data in this section is specific to the image file campus_map.png.
         This file is 4538 × 3956 and 3,564,877 bytes.  Using a different campus
         image file will require updating the config file ct_config.json. */
        CAMPUS_IMG_SIZE_X = Double(appConfig["campusImageSizeX"]!)!  //4538
        CAMPUS_IMG_SIZE_Y = Double(appConfig["campusImageSizeY"]!)!  //3956
        
        CAL_POINT1_X = Double(appConfig["campusImageCalPoint1X"]!)!     //540
        CAL_POINT1_Y = Double(appConfig["campusImageCalPoint1Y"]!)!   //454
        CAL_POINT1_LAT = Double(appConfig["campusImageCalPoint1Latitude"]!)!   //33.746832
        CAL_POINT1_LON = Double(appConfig["campusImageCalPoint1Longitude"]!)!   //-84.413719

        CAL_POINT2_X = Double(appConfig["campusImageCalPoint2X"]!)!   //3551
        CAL_POINT2_Y = Double(appConfig["campusImageCalPoint2Y"]!)!   //2631
        CAL_POINT2_LAT = Double(appConfig["campusImageCalPoint2Latitude"]!)!   //33.744402
        CAL_POINT2_LON = Double(appConfig["campusImageCalPoint2Longitude"]!)!   //-84.409692

        let SLOPEX = (CAL_POINT2_LON - CAL_POINT1_LON)/Double(CAL_POINT2_X - CAL_POINT1_X)
        CAMPUS_LEFT_LONGITUDE = CAL_POINT1_LON + Double(0 - CAL_POINT1_X) * SLOPEX
        CAMPUS_RIGHT_LONGITUDE = CAL_POINT1_LON +  Double(CAMPUS_IMG_SIZE_X - CAL_POINT1_X) * SLOPEX

        let SLOPEY = (CAL_POINT2_LAT - CAL_POINT1_LAT)/Double(CAL_POINT2_Y - CAL_POINT1_Y)
        CAMPUS_TOP_LATITUDE = CAL_POINT1_LAT + Double(0 - CAL_POINT1_Y) * SLOPEY
        CAMPUS_BOTTOM_LATITUDE = CAL_POINT1_LAT + Double(CAMPUS_IMG_SIZE_Y - CAL_POINT1_Y) * SLOPEY
    
        CAMPUS_LATITUDE = (CAMPUS_TOP_LATITUDE+CAMPUS_BOTTOM_LATITUDE)/2
        CAMPUS_LONGITUDE = (CAMPUS_LEFT_LONGITUDE+CAMPUS_RIGHT_LONGITUDE)/2
        
        //load the default location from the config file (currently the Cosby parking lot)
        DEFAULT_LOCATION = CLLocation(latitude:Double(appConfig["defaultLatitude"]!)!, longitude:Double(appConfig["defaultLongitude"]!)!)
        
        // ---------------------- END CAMPUS MAP DATA ------------------------------

        
        //---------- joystick controls constants ----------
        JOYSTICK_X_INC = (CAMPUS_RIGHT_LONGITUDE - CAMPUS_LEFT_LONGITUDE)/100
        JOYSTICK_Y_INC = (CAMPUS_BOTTOM_LATITUDE - CAMPUS_TOP_LATITUDE)/100
    }
    
    
    
    
    

    
    /* =========================================================================
     This is the gesture recognizer for the buildings image
     ======================================================================== */
    @objc func handleImgBuildingsTap(recognizer: UITapGestureRecognizer) {
        
        //ignore taps if GPS is on
        if gpsOn == true {return}
        
        //react only when the tap ends
        if recognizer.state == .ended {
            //the location in the image target frame is returned by handleImgBuildingsTap
            let locationInTargetImgFrame = recognizer.location(in: imgBuildings /*recognizer.view*/)
            
            //now we need the offset of the image in the frame
            let targetImgOrigin = getImageOffsetInImageView(imageView: imgBuildings /*recognizer.view as! UIImageView*/)
            
            let locationInTargetImg = CGPoint(x: locationInTargetImgFrame.x - targetImgOrigin.x, y:locationInTargetImgFrame.y - targetImgOrigin.y)
            
            let coord = pointsToGpsCoord(imgPointCoord: locationInTargetImg)
            latestGpsLocation =  coord
            setMarker(coord: coord)
            
            processNewLocation(coord: coord)
            //print("## (\(coord.coordinate.latitude), \(coord.coordinate.longitude))")
        }
    }
    

    /* =========================================================================
     newly updated GPS coordinate notifications callback function.  The
     notificaiton argument is a gps_coord object.
     ======================================================================== */
    @objc func gotNewLocationFromLocationServices(_ notification: Notification){
        
        //ignore newly reported locations if GPS mode is off
        if gpsOn == false {return}

        //let coord = notification.object as! CLLocation

        //****** this minimum update time should be a parameter or eventually eliminated
        if Date.timeIntervalSinceReferenceDate - gpsLastUpdateTime < 0.25 {
            //it's been less than 0.25 seconds.  Do nothing
            return
        }
        
        //mark the time of this update
        gpsLastUpdateTime = Date.timeIntervalSinceReferenceDate
        
        //print("*got new location! (\(coord.coordinate.latitude), \(coord.coordinate.longitude))")
        print("$", terminator:"")
        
        
        //if we are in debug mode, toggle the marker image everytime the GPS updates
        /*
        if SCCT_DebugMode == true
        {
            if bToggleMarkerImage == true {
                imgMarker.image = UIImage(named: "Marker2_50px")
            }
            else {
                imgMarker.image = UIImage(named: "Marker1_50px")
            }
            bToggleMarkerImage = !bToggleMarkerImage
        }
        */
        
        
        /* ***** We need to check if this is the same POI *****  TO DO
        
         How do we handle the case where media is still playing when a new location
         is here for a different POI?  This could happen if the user
         has traveled a long distance, not realizing his/her app is paused or
         it could simply be that 2 POIs are close together.  To address the former
         case, we should keep track of how long the media has been paused.
         If it has been paused for >60 seconds, simply usurp the current media with
         the new.
         In the latter case, do nothing: let the media finish playing before playing
         the new POI's media.  This amounts to ignoright the new POI for the time
         being. */
        
        processNewLocation(coord: latestGpsLocation)
        
        //begin autoplay
        if let poi = campusTour?.poiManager.getNearestPoiInRange(coord: latestGpsLocation) {
            if poi.status == .NotVisited {
                poi.status = .Visited
                playMedia(url: poi.video_url, outputView: viewTour)
                currentPoi = poi
            }
        }

        setMediaButtons()
    }
    
    /* =========================================================================
     ======================================================================== */
    func processNewLocation(coord:CLLocation) {
        setMarker(coord: coord)
        
        //let poisInRange = campusTour?.poiManager.getPoisInRange(coord: coord)
        //print("#poisInRange = \(poisInRange?.count)")
        /*
        for poi in poisInRange! {
            print("\(poi.poiID!) distance=\(poi.coord.distance(from: coord)) meters.")
        }
        */

        //do not update the map if media is paused or playing
        //this prevents the building layer being overlayed on
        //the viewTour view
        if mediaState == .paused || mediaState == .playing {return}
        
        let poi = campusTour?.poiManager.getNearestPoiInRange(coord: coord)
        if poi != nil {
            //display the rich text
            txtTourInfo.attributedText = poi!.richText
            txtTourInfo.scrollRangeToVisible(NSMakeRange(0, 0)) //force scroll to the top

            //displayAttributedTextFromURL(rtfFileUrl: poi!.rtf_url, targetView: txtTourInfo)
            
            //select the building layer with the name that mathes the poiID
            //don't only update the buildings layer if we are in map mode
            if tourMode == .map{
                imgBuildings.image = UIImage(named:poi!.poiID)
                
                /* for non-building POIs, there will not be a
                 corresponding building image.  In such cases, the
                 assignment above will result in a nil building image.
                 Reset it here to the blank image "NONE". */
                if imgBuildings.image == nil {
                    imgBuildings.image = UIImage(named:"NONE")
                }
            }
            lblTitle.text = poi!.title
            switch poi!.status {
            case .NotVisited:
                imgCheck.image = UIImage(named:"status_not_visited")
            case .Visited:
                imgCheck.image = UIImage(named:"status_visited")
            case .Completed:
                imgCheck.image = UIImage(named:"status_completed")
            default:    //this should never happen
                imgCheck.image = nil
                print("ERROR: poi has invalid status.")
            }
            
            displayTopLogo(coverTitleAndCheck: false)
        }   //if poi != nil
        else {
            //if we are not near a POI, turn off the building layer
            imgBuildings.image = UIImage(named:"NONE")
            displayTopLogo(coverTitleAndCheck: true)
            txtTourInfo.attributedText = defaultRichText
            txtTourInfo.scrollRangeToVisible(NSMakeRange(0, 0)) //force scroll to the top

        }
        
        setMediaButtons()

    }
    
    /* =========================================================================
     callback frunction for the media finished playing notification.  We
     will use this callback to remove the a/v view
     ======================================================================== */
    @objc func mediaPlayBackFinished(_ notification: Notification){
        let avPlayerItem = notification.object as! AVPlayerItem
        let avUrlAsset = avPlayerItem.asset as! AVURLAsset
        let url=avUrlAsset.url.absoluteString
        print("playback for \(url) finished.")
        
        /* we need to be able to lookup a POI by its media URL.  If we
        are no longer in proximity of the POI, its window should be
        removed.  Also, if the user clicks on map view, the window
        should be removed.  Finally, the poi needs to be narked as
        "Completed". */
        avView?.removeFromSuperview()       //***TEMP
        mediaState = .stopped
        currentPoi.status = .Completed
        setMediaButtons()
        
        //update the building and check images
        processNewLocation(coord: latestGpsLocation)
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
        if coverTitleAndCheck == true {
            imgTopLogoBar.isHidden = false
            hStackTitleAndCheck.isHidden = true
        }
        else{
            imgTopLogoBar.isHidden = true
            hStackTitleAndCheck.isHidden = false
        }
        
    }


    /* =========================================================================
     ======================================================================== */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /* =========================================================================
     ======================================================================== */
    func callback(coord:CLLocation)->(){
        print("TourView callback: \(coord)")
    }

    /* =========================================================================
     while media is playing or paused:
        turn the map/film button to a stop button and enable all media controls
     
     when gpsOn is true: (GPS mode on)
        if we are not in range of a POI, gray all buttons (play/pause, rewind
         and replay)
         if we are in range of a "NotVisited" POI, auto-play and set the buttons as:
            play/pause -> pause
            rewind -> enabled
            replay -> enabled
         if we are in range of a "Visited" POI, do not auto-play and set the buttons as:
            play/pause -> play
            rewind -> enabled
            replay -> enabled
         if we are not in range of a POI, gray all media control buttons
     
     when gpsOn is false: (GPS mode off)
        gray media buttons when we are not in range of a POI.  Otherwise
        enable all media buttons
     
     ======================================================================== */
    func setMediaButtons() {
        
        //Note: btnMapMediaStop and btnGpsOnOff are always enabled
        
        //btnGpsOnOff is always enabled
        if gpsOn == true {
            btnGpsOnOff.setImage(UIImage(named: "gps_on"), for: .normal)
        }
        else {
            btnGpsOnOff.setImage(UIImage(named: "gps_off"), for: .normal)
        }
        
        if mediaState == .playing {
            btnMapMediaStop.setImage(UIImage(named: "stop"), for: .normal)
            btnPlayPause.setImage(UIImage(named: "pause"), for: .normal)
            btnPlayPause.isEnabled = true
            btnRewind.isEnabled = true
            btnRePlay.isEnabled = true
            return
        }
        
        if mediaState == .paused {
            btnMapMediaStop.setImage(UIImage(named: "stop"), for: .normal)
            btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
            btnPlayPause.isEnabled = true
            btnRewind.isEnabled = true
            btnRePlay.isEnabled = true
            return
        }
        
        /* beyond this point, media is not playing or paused... set the btnMapMediaStop
         image accordingly.  Also, set the play/pause button to play
         (it doesn't make sense to pause media that isn't playing) and
         disable the replay button (it doesn't make sense to replay
         somthing that is not playing. */
        if tourMode == .map {
            btnMapMediaStop.setImage(UIImage(named: "film"), for: .normal)
        }
        if tourMode == .walk {
            btnMapMediaStop.setImage(UIImage(named: "map"), for: .normal)
        }
        
        //set play/pause button to "play"
        btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
        
        //disable the replay button
        btnRePlay.isEnabled = false
  
  
        /* Deal with 4 cases:
            * GPS on with POI in range
            * GPS on with no POI in range
            * GPS off with POI in range
            * GPS off with no POI in range
         For the first case, there are 2 subcases: when the POI in range has
         been visited and when it has not be visited.  Autoplay will engage
         only when the POI has not been visited,
         See the comments on top for details of each case. */
        if gpsOn == true {  //GPS is on
            //check to see if there are POIs in range
            if let nearestPoi = campusTour?.poiManager.getNearestPoiInRange(coord: latestGpsLocation) {
                //---------- GPS is on and there is a POI in range ----------
                if nearestPoi.status == .NotVisited {
                    //---------- GPS is on and there is a NotVisted POI in range ----------
                    /*  In this case, we should start autoplaying.  The
                     will be set when the media state changes.  This should be
                     a temporary state.  Gray out all buttons in case it takes
                     a while for the media to load and start playing. */
                    btnPlayPause.setImage(UIImage(named: "pause"), for: .normal)
                    btnPlayPause.isEnabled = false
                    btnRewind.isEnabled = false
                    //btnRePlay.isEnabled = false

                    /* XXXXXXXXXXXX TO DELETE
                     , so set the play/pause button
                     to pause.  Enable the rewind and replay button.  The stop button will be
                     set once the media state actually switches to playing.
                     XXXXXXXXXX */
                }
                else {
                    //---------- GPS is on and there is a Visted, Completed or other state POI in range ----------
                    /* In this case, we want to offer the user the ability to
                     replay the media. */
                    btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
                    btnPlayPause.isEnabled = true
                    btnRewind.isEnabled = true
                    //btnRePlay.isEnabled = true
                }
            }
            else {
                //---------- GPS is on and there are no POIs in range ----------
                /* In this case, simply disable all media buttons. */
                btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
                btnPlayPause.isEnabled = false
                btnRewind.isEnabled = false
                //btnRePlay.isEnabled = false
            }   //else for if let nearestPoi
        }   //if gpsOn == true
        else {  //GPS is off
            /* gray media buttons when we are not in range of a POI.  Otherwise
            enable all media buttons. */
            //check to see if there are POIs in range
            if let nearestPoi = campusTour?.poiManager.getNearestPoiInRange(coord: latestGpsLocation) {
                //---------- GPS is off and there is a POI in range ----------
                btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
                btnPlayPause.isEnabled = true
                btnRewind.isEnabled = true
                //btnRePlay.isEnabled = true
            }
            else {
                //---------- GPS is off and there are no POIs in range ----------
                btnPlayPause.setImage(UIImage(named: "play"), for: .normal)
                btnPlayPause.isEnabled = false
                btnRewind.isEnabled = false
                //btnRePlay.isEnabled = false
            }   //else for if let nearestPoi
        }   //else for if gpsOn == true

    }   //func setMediaButtons()
    
    
    /* =========================================================================
     This function attempts to play the media (audio or video) at the
     supplied URL to the supplied UIView.  For audio, pass a nil value
     for the UIView
     ======================================================================== */
    func playMedia(url:String, outputView:UIView?)
    {
        if let outView = outputView {
            // a UIView window has been supplied.  Use it for video output
            avView = AVStreamer.playMedia(url:url, outputUIViewWidth:outView.bounds.size.width, outputUIViewHeight: outView.bounds.size.height, showPlaybackControls:false)
            mediaState = .playing
            
            if let view = avView {
                outView.addSubview(view)
                //viewMain.sendSubview(toBack: view)
                }
        }
        else {
            // no UIView was supplied; assume this is audio.  We do not need the returned UIView value
            AVStreamer.playMedia(url:url, showPlaybackControls:false)
            mediaState = .playing
        }
    }
    

    /* =========================================================================
     Mark the start of the pause.
     Use this function to mark the start of pausing the media player.
     Use the getPauseTime() function return the amount of time in seconds
     that has elapsed since pause was pressed.  For this to work properly
     be sure to call markPause() whenever AVStream.pause() is called.
     ======================================================================== */
    func markPause() {
        startOfPauseTime = Date.timeIntervalSinceReferenceDate
    }
    
    /* =========================================================================
     Use this function to get the number of seconds that have elapsed since
     the user paused the playing media.  If the media is not currently
     paused, the function returns 0.0
     ======================================================================== */
    func getPauseTime() -> Double {
        if mediaState == .paused {
            //here, we want to return the number of elapsed seconds
            return Date.timeIntervalSinceReferenceDate - startOfPauseTime
        }
        return 0.0      //return 0, since we are not paused.
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnPlayPauseTouchUpInside(_ sender: Any) {
        //var image:UIImage?
        
        switch mediaState {
        case .playing:
           // image = UIImage(named: "play")
            AVStreamer.pause()
            mediaState = .paused
            markPause()     //mark the start of the pause
        case .paused:
            AVStreamer.unpause()
           // image = UIImage(named: "pause")
            mediaState = .playing
        default:
            //image = UIImage(named: "pause")
            
            if let poi = campusTour?.poiManager.getNearestPoiInRange(coord: latestGpsLocation) {
                mediaState = .playing
                playMedia(url: poi.video_url, outputView: viewTour /*imgTourImage*/)
                currentPoi = poi
                
                //if this is the first time we are visiting this POI, change its status to .Visited
                if poi.status == .NotVisited {
                    poi.status = .Visited
                }
                
                /*
                txtTourInfo.attributedText = poi.richText
                
                displayAttributedTextFromURL(rtfFileUrl: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/default.rtf", targetView: txtTourInfo) */
            }
            else {
                print("**** ERROR: the play button was pushed, but there is no POI in range.  The play button should not have been enabled.")
            }
        }

        //btnPlayPause.setImage(image, for: .normal)
        setMediaButtons()
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
     This function converts gps coordinates to image point coordinates
     for the image in imgTourImage
     ======================================================================== */
    func gpsCoordToPoints(coord:CLLocation) -> CGPoint {
        //get the top, bottom, left and right pixel coordinates of the image
        let imagePointSize = getImagePointSizeInImageView(imageView: imgTourImage)
        let imageLeft = 0.0
        let imageTop = 0.0
        let imageRight = Double(imagePointSize.width-1)
        let imageBottom = Double(imagePointSize.height-1)
        
        //interpolate x
        let x = imageLeft + (coord.coordinate.longitude - CAMPUS_LEFT_LONGITUDE) * (imageRight - imageLeft)/(CAMPUS_RIGHT_LONGITUDE - CAMPUS_LEFT_LONGITUDE)
        
        //interpolate y
        let y = imageTop + (coord.coordinate.latitude - CAMPUS_TOP_LATITUDE) * (imageBottom - imageTop)/(CAMPUS_BOTTOM_LATITUDE - CAMPUS_TOP_LATITUDE)
        
        //print("(\(coord.coordinate.latitude)), \(coord.coordinate.longitude) -> (\(x), \(y))")
        return CGPoint(x:x, y:y)
    }
    
    /* =========================================================================
     This function converts image point coordinates to gps coordinates
     for the image in imgTourImage
     ======================================================================== */
    func pointsToGpsCoord(imgPointCoord:CGPoint) -> CLLocation {
        //get the top, bottom, left and right pixel coordinates of the image
        let imagePointSize = getImagePointSizeInImageView(imageView: imgTourImage)
        let imageLeft = 0.0
        let imageTop = 0.0
        let imageRight = Double(imagePointSize.width-1)
        let imageBottom = Double(imagePointSize.height-1)
        
        //interpolate longitude (x)
        let slopex = (CAMPUS_RIGHT_LONGITUDE - CAMPUS_LEFT_LONGITUDE)/(imageRight - imageLeft)
        let lon = CAMPUS_LEFT_LONGITUDE + (Double(imgPointCoord.x) - imageLeft) * slopex
        
        let slopey = (CAMPUS_BOTTOM_LATITUDE - CAMPUS_TOP_LATITUDE)/(imageBottom - imageTop)
        let lat = CAMPUS_TOP_LATITUDE + (Double(imgPointCoord.y) - imageTop) * slopey
        
        //print("(\(imgPointCoord.x), \(imgPointCoord.y)) -> (\(lat)), \(lon)")
        return CLLocation(latitude: lat, longitude: lon)
    }
    
    /* =========================================================================
     function that draws the marker on the image.  The location of the marker
     is in gps coordinates.
     ======================================================================== */
    func setMarker(coord:CLLocation) {
        
        //set the marker based on the accuracy of the GPS signal
        //*** These limits should be set in the config file. ***
        let accuracyInFeet = coord.horizontalAccuracy/0.3048
        switch accuracyInFeet
        {
        case 0..<25:
            imgMarker.image = UIImage(named: "marker1")
        case 25..<50:
            imgMarker.image = UIImage(named: "marker2")
        case 50..<100:
            imgMarker.image = UIImage(named: "marker3")
        case 100..<200:
            imgMarker.image = UIImage(named: "marker4")
        default:
            imgMarker.image = nil
        }
        
        
        //draw the marker
        setMarkerOnImageView(marker:imgMarker, targetView: imgTourImage, targetLocation: gpsCoordToPoints(coord: coord))
        
        //update the label
        let lat = String(format: "%.6f", coord.coordinate.latitude)
        let lon = String(format: "%.6f", coord.coordinate.longitude)
        let accuracy = String(format: "%.1f", coord.horizontalAccuracy/0.3048)

        lblGpsCoord.text = "(\(lat), \(lon)) [~\(accuracy)]"
    }

    /* =========================================================================
     This function attempts to superimpose the supplied UIView object
     (the marker) centered on the target UIImageView based on the UIImageView's
     image coordinates.
     The function is intended to work on images that are "aspect fitted" in
     their frame.  In other words, the entire aspect-preserced image must
     be displayed for the coordinate transforms to work properly.
     "aspect-fitted" images often have blank border on the left and right or
     on top and bottom, depending on which dimension limits the size of the
     image in its frame.  This function handles both cases and draws
     the marker centered at the correct coordinates in the image.
     ======================================================================== */
    func setMarkerOnImageView(marker:UIView, targetView:UIImageView, targetLocation:CGPoint){
        
        let targetImgOrigin = getImageOffsetInImageView(imageView: targetView)
        
        //translate the point to put it in frame coordinates
        let targetLocationInFrameCoord = CGPoint(x:targetLocation.x + targetImgOrigin.x, y:targetLocation.y + targetImgOrigin.y)
        
        //print(targetLocation, targetLocationInFrameCoord)
        
        //draw the marker at the offset position
        marker.center = CGPoint(x:targetLocationInFrameCoord.x,  y:targetLocationInFrameCoord.y)
    }
    
    
    /* =========================================================================
     Given a UIImageView object, this function attempts to calculate the
     size of the image in the view in points.
     The function is intended to work on images that are "aspect fitted" in
     their frame.  In other words, the entire aspect-preserved image must
     be displayed for the coordinate transforms to work properly.
     "aspect-fitted" images often have blank border on the left and right or
     on top and bottom, depending on which dimension limits the size of the
     image in its frame.  This function handles both cases and returns the
     image size as a CGSize.
     ======================================================================== */
    func getImagePointSizeInImageView(imageView:UIImageView) -> CGSize {
        let imagePixelSize = imageView.image!.size
        let imageFrameSize = imageView.frame.size
        let imageAR = imagePixelSize.width/imagePixelSize.height
        let imageFrameAR = imageView.frame.width/imageView.frame.height
        
        var imagePointSize = CGSize()
        //determine the location of the image relative to its super view
        if imageFrameAR > imageAR {
            //print("limited by height")
            imagePointSize.height = imageFrameSize.height
            imagePointSize.width = imagePointSize.height*imagePixelSize.width/imagePixelSize.height
            //print(imagePointSize)
        }
        else {
            //print("limited by width")
            imagePointSize.width = imageFrameSize.width
            imagePointSize.height = imagePointSize.width*imagePixelSize.height/imagePixelSize.width
            //print(imagePointSize)
        }
        return imagePointSize
    }
    
    
    /* =========================================================================
     Given a UIImageView object, this function attempts to calculate the
     X-Y offset of the image in the view.
     The function is intended to work on images that are "aspect fitted" in
     their frame.  In other words, the entire aspect-preserved image must
     be displayed for the coordinate transforms to work properly.
     "aspect-fitted" images often have blank border on the left and right or
     on top and bottom, depending on which dimension limits the size of the
     image in its frame.  This function handles both cases and returns the
     offset of the image as a CGPoint.
     ======================================================================== */
    func getImageOffsetInImageView(imageView:UIImageView) -> CGPoint {
        let imageFrameSize = imageView.frame.size
        let imagePointSize = getImagePointSizeInImageView(imageView: imageView)
        let imageOrigin = CGPoint(x:(imageFrameSize.width-imagePointSize.width)/2, y:(imageFrameSize.height-imagePointSize.height)/2)
        
        return imageOrigin
    }
    
    /* =========================================================================
     From Stack Exchange
     https://stackoverflow.com.mevn.nethttp://stackoverflow.com.mevn.net/a/34461183
     
     This function attempts to report the RGBA value of the pixel under a
     point on a view.  The point is passed in as a CGPoint object and the
     view is a UIView object.  While the function returns an alpha value,
     this value seems to always be 255.  Oddly, when the actual value of the
     alpha channel is not 255 (255-opaque), the RGB value returned is the
     composite color of the translucent layer and the background.  In such
     cases, the alpha value is still reported as 255.
     ======================================================================== */
    func getPixelColorAtPoint(point:CGPoint, sourceView: UIView) -> UIColor {
        let pixel=UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace=CGColorSpaceCreateDeviceRGB()
        let bitmapInfo=CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context=CGContext(data: pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        var color: UIColor?=nil
        if let context=context {
            context.translateBy(x: -point.x, y: -point.y)
            sourceView.layer.render(in: context)
            color=UIColor(red: CGFloat(pixel[0])/255.0,green: CGFloat(pixel[1])/255.0,blue: CGFloat(pixel[2])/255.0,alpha: CGFloat(pixel[3])/255.0)
            pixel.deallocate(capacity: 4)
            
        }
        return color!
        
    }

    /* =========================================================================
     ======================================================================== */
    func setTourMode(_ tourMode:ETourMode) {
        //var image:UIImage?
        var tour_image:UIImage?

        if tourMode == self.tourMode {return}   //nothing to do
        
        switch tourMode {
        case .map:
            //image = UIImage(named: "film")
            tour_image = UIImage(named: "campus_map")
            imgTourImage.contentMode = .scaleAspectFit
            imgBuildings.isHidden = false
            imgMarker.isHidden = false
            self.tourMode = .map
        case .walk:
            //image = UIImage(named: "map")
            tour_image = UIImage(named: "default_arch")
            imgTourImage.contentMode = .scaleAspectFill
            imgBuildings.isHidden = true
            imgMarker.isHidden = true
            self.tourMode = .walk
        default:
            print("invalid tour mode: \(tourMode)")
        }   //switch
        
        //btnMapMediaStop.setImage(image, for: .normal)
        setMediaButtons()
        imgTourImage.image = tour_image //.setImage(tour_image, for: .normal)        i
        
    }   //func

    /* =========================================================================
     ======================================================================== */
    func turnGpsOn(on: Bool) {
        gpsOn = on
        setMediaButtons()
    }
    
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnGpsOnOffTouchUpInside(_ sender: Any) {
        turnGpsOn(on: !gpsOn)
    }

    
    /* =========================================================================
     rewind 10 seconds
     ======================================================================== */
    @IBAction func btnRewindTouchUpInside(_ sender: Any) {
        AVStreamer.rewind(seconds: 10)
    }
    
    /* =========================================================================
     re-play from the beginning
     ======================================================================== */
    @IBAction func btnRePlayTouchUpInside(_ sender: Any) {
        AVStreamer.replay()
        mediaState = .playing
        setMediaButtons()
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnMapMediaStopTouchUpInside(_ sender: Any) {
        //this button beomes the stop button when media is playing or paused
        if mediaState == .playing || mediaState == .paused {
            
            AVStreamer.stop()
            if avView != nil {
                avView?.removeFromSuperview()
            }
            else {
                print("****** ERROR: the stop button was clicked, but there is no active media playing.  The stop button should not have been enabled.")
            }
            mediaState = .stopped
            
            setMediaButtons()
            return
        }
        
        switch tourMode {
        case .walk: //current mode is walk, so switch to map
            setTourMode(.map)
        case .map:  //current mode is map, so switch to walk
            setTourMode(.walk)
        default:
            break
            //print("invalid tour mode.")
        }   //switch
    }   //func
    
    
    /* =========================================================================
     this function attempts to load the RTF data from the provided rtf_url
     ======================================================================== */
    func getDefaultRichText( defaultRtfUrl:String) -> NSAttributedString {
        //richText = nil  //set a default value
        
        if let url = URL(string: defaultRtfUrl) {
            do {
                //read the data from the rtf file
                let data = try Data(contentsOf: url)
                
                //convert the data into an atrributed string
                let richText = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
                return richText
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of \(defaultRtfUrl)")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL for \(defaultRtfUrl)")
        }
        //return an empty NSAttributedString object if we fail to load the default RTF
        return NSAttributedString()
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyUpTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude - JOYSTICK_Y_INC, longitude:latestGpsLocation.coordinate.longitude)
        //setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyDownTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude + JOYSTICK_Y_INC, longitude:latestGpsLocation.coordinate.longitude)
        //setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyRightTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude, longitude:latestGpsLocation.coordinate.longitude + JOYSTICK_X_INC)
        //setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyLeftTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude, longitude:latestGpsLocation.coordinate.longitude - JOYSTICK_X_INC)
        //setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     Use the middle button to go back to the mniddke
     ======================================================================== */
    @IBAction func btnJoyMiddleTouchUpInside(_ sender: Any) {
        latestGpsLocation = CLLocation(latitude:CAMPUS_LATITUDE, longitude:CAMPUS_LONGITUDE)
        setMarker(coord: latestGpsLocation)
        for poi in (campusTour?.poiManager.POIs)! {
            let bearing = campusTour?.poiManager.poiBearingDegrees(fromLocation: latestGpsLocation, headingDegrees: 90.0, poi: poi)
            print("poi:\(poi.poiID!) @ \(bearing!) degs.")
        }
    }
    

}


/* =========================================================================
 ======================================================================== */
//----------  ----------

