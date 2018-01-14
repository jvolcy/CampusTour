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
    @IBOutlet weak var btnMap: UIButton!
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

    //enumera possible media states
    enum EMediaState {case stopped, playing, finished, paused, unknown}
    //set the default media state
    var mediaState:EMediaState = .stopped
    
    //enumerate the tour modes
    enum ETourMode {case map, walk, notSet}
    //set the default tour mode
    var tourMode:ETourMode = .notSet
 
    // ---------------------- START CAMPUS MAP DATA ----------------------------
    /* The data in this section is specific to the image file campus_map.png.
     This file is 4538 × 3956 and 3,564,877 bytes.  Using a different campus
     image file will invalidate the data below. */
    static let CAMPUS_IMG_SIZE_X = 4538
    static let CAMPUS_IMG_SIZE_Y = 3956
    
    static let CAL_POINT1_X = 540
    static let CAL_POINT1_Y = 454
    static let CAL_POINT1_LAT = 33.746832
    static let CAL_POINT1_LON = -84.413719

    static let CAL_POINT2_X = 3551
    static let CAL_POINT2_Y = 2631
    static let CAL_POINT2_LAT = 33.744402
    static let CAL_POINT2_LON = -84.409692
    
    static let SLOPEX = (CAL_POINT2_LON - CAL_POINT1_LON)/Double(CAL_POINT2_X - CAL_POINT1_X)
    static let CAMPUS_LEFT_LONGITUDE = CAL_POINT1_LON + Double(0 - CAL_POINT1_X) * SLOPEX
    static let CAMPUS_RIGHT_LONGITUDE = CAL_POINT1_LON +  Double(CAMPUS_IMG_SIZE_X - CAL_POINT1_X) * SLOPEX

    static let SLOPEY = (CAL_POINT2_LAT - CAL_POINT1_LAT)/Double(CAL_POINT2_Y - CAL_POINT1_Y)
    static let CAMPUS_TOP_LATITUDE = CAL_POINT1_LAT + Double(0 - CAL_POINT1_Y) * SLOPEY
    static let CAMPUS_BOTTOM_LATITUDE = CAL_POINT1_LAT + Double(CAMPUS_IMG_SIZE_Y - CAL_POINT1_Y) * SLOPEY

    let CAMPUS_LATITUDE = (CAMPUS_TOP_LATITUDE+CAMPUS_BOTTOM_LATITUDE)/2
    let CAMPUS_LONGITUDE = (CAMPUS_LEFT_LONGITUDE+CAMPUS_RIGHT_LONGITUDE)/2
    // ---------------------- END CAMPUS MAP DATA ------------------------------
    
    //---------- joystick controls constants ----------
    let JOYSTICK_X_INC = (CAMPUS_RIGHT_LONGITUDE - CAMPUS_LEFT_LONGITUDE)/100
    let JOYSTICK_Y_INC = (CAMPUS_BOTTOM_LATITUDE - CAMPUS_TOP_LATITUDE)/100
        
    /* =========================================================================
     ======================================================================== */
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //set the default tour mode
        setTourMode(.walk)
        
        if SCCT_DebugMode == true {
            /* set the default location to the center of the map if we are in
 debug mode. */
            let poi = campusTour?.poiManager.getPoi(byID: "MANLEY_CENTER")
            latestGpsLocation = poi!.coord //CLLocation(latitude:CAMPUS_LATITUDE, longitude:CAMPUS_LONGITUDE)
            setMarker(coord: latestGpsLocation)
        }
        
        //instantiate the A/V Streamer
        AVStreamer = CAVStreamer()

        //fix aspect ratio problem with images in the buttons (not settable throug IB)
        btnPlayPause.imageView?.contentMode = .scaleAspectFit
        btnRePlay.imageView?.contentMode = .scaleAspectFit
        btnRewind.imageView?.contentMode = .scaleAspectFit
        btnMap.imageView?.contentMode = .scaleAspectFit
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
     Thss is the gesture recognizer for the buildings image
     ======================================================================== */
    @objc func handleImgBuildingsTap(recognizer: UITapGestureRecognizer) {
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
            
            //print("## (\(coord.coordinate.latitude), \(coord.coordinate.longitude))")
        }
    }
    

    /* =========================================================================
     newly updated GPS coordinate notifications callback function.  The
     notificaiton argument is a gps_coord object.
     ======================================================================== */
    @objc func gotNewLocationFromLocationServices(_ notification: Notification){
        let coord:CLLocation = notification.object as! CLLocation
        //print("got new location! (\(coord.coordinate.latitude), \(coord.coordinate.longitude)")
        print("$", terminator:"")
        setMarker(coord: coord)
        
        let poisInRange = campusTour?.poiManager.getPoisInRange(coord: coord)
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
            imgCheck.image = UIImage(named:"status_visited")
            displayTopLogo(coverTitleAndCheck: false)
        }
        else {
            //if we are not near a POI, turn off the building layer
            imgBuildings.image = UIImage(named:"NONE")
            displayTopLogo(coverTitleAndCheck: true)
        }
        
        //print("distance to ACC = \(poiManager.getPoi(byID: "ACC")?.coord.distance(from: test_coord))")

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
        /*
        if let poi = campusTour?.poiManager.getPoi(byVideoUrl: url) {
            if poi == campusTour?.poiManager.getNearestPoiInRange(coord: <#T##gps_coord#>) {
                //this is still the nearest POI, do not dismiss its window
                return
            }
        }
         */
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
     This function attempts to play the media (audio or video) at the
     supplied URL to the supplied UIView.  For audio, pass a nil value
     for the UIView
     ======================================================================== */
    func playMedia(url:String, outputView:UIView?)
    {
        if let outView = outputView {
            // a UIView window has been supplied.  Use it for video output
            avView = AVStreamer.playMedia(url:url, outputUIViewWidth:outView.bounds.size.width, outputUIViewHeight: outView.bounds.size.height, showPlaybackControls:false)
            
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
            playMedia(url: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/DEFAULT.mp4", outputView: viewTour /*imgTourImage*/)
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
        let x = imageLeft + (coord.coordinate.longitude-TourViewController.CAMPUS_LEFT_LONGITUDE) * (imageRight - imageLeft)/(TourViewController.CAMPUS_RIGHT_LONGITUDE-TourViewController.CAMPUS_LEFT_LONGITUDE)
        
        //interpolate y
        let y = imageTop + (coord.coordinate.latitude-TourViewController.CAMPUS_TOP_LATITUDE) * (imageBottom - imageTop)/(TourViewController.CAMPUS_BOTTOM_LATITUDE - TourViewController.CAMPUS_TOP_LATITUDE)
        
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
        let slopex = (TourViewController.CAMPUS_RIGHT_LONGITUDE - TourViewController.CAMPUS_LEFT_LONGITUDE)/(imageRight - imageLeft)
        let lon = TourViewController.CAMPUS_LEFT_LONGITUDE + (Double(imgPointCoord.x) - imageLeft) * slopex
        
        let slopey = (TourViewController.CAMPUS_BOTTOM_LATITUDE - TourViewController.CAMPUS_TOP_LATITUDE)/(imageBottom - imageTop)
        let lat = TourViewController.CAMPUS_TOP_LATITUDE + (Double(imgPointCoord.y) - imageTop) * slopey
        
        //print("(\(imgPointCoord.x), \(imgPointCoord.y)) -> (\(lat)), \(lon)")
        return CLLocation(latitude: lat, longitude: lon)
    }
    
    /* =========================================================================
     function that draws the marker on the image.  The location of the marker
     is in gps coordinates.
     ======================================================================== */
    func setMarker(coord:CLLocation) {
        //draw the marker
        setMarkerOnImageView(marker:imgMarker, targetView: imgTourImage, targetLocation: gpsCoordToPoints(coord: coord))
        
        //update the label
        lblGpsCoord.text = "(\(coord.coordinate.latitude), \(coord.coordinate.longitude))"
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
        var image:UIImage?
        var tour_image:UIImage?

        if tourMode == self.tourMode {return}   //nothing to do
        
        switch tourMode {
        case .map:
            image = UIImage(named: "film")
            tour_image = UIImage(named: "campus_map")
            imgTourImage.contentMode = .scaleAspectFit
            imgBuildings.isHidden = false
            imgMarker.isHidden = false
            self.tourMode = .map
        case .walk:
            image = UIImage(named: "map")
            tour_image = UIImage(named: "default_arch")
            imgTourImage.contentMode = .scaleAspectFill
            imgBuildings.isHidden = true
            imgMarker.isHidden = true
            self.tourMode = .walk
        default:
            print("invalid tour mode: \(tourMode)")
        }   //switch
        
        btnMap.setImage(image, for: .normal)
        imgTourImage.image = tour_image //.setImage(tour_image, for: .normal)        i
        
    }   //func
    
    /* =========================================================================
     rewind 10 seconds
     ======================================================================== */
    @IBAction func btnRewindTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     re-play from the beginning
     ======================================================================== */
    @IBAction func btnRePlayTouchUpInside(_ sender: Any) {
        AVStreamer.replay()
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnMapTouchUpInside(_ sender: Any) {
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
     ======================================================================== */
    @IBAction func btnJoyUpTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude - JOYSTICK_Y_INC, longitude:latestGpsLocation.coordinate.longitude)
        setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyDownTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude + JOYSTICK_Y_INC, longitude:latestGpsLocation.coordinate.longitude)
        setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyRightTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude, longitude:latestGpsLocation.coordinate.longitude + JOYSTICK_X_INC)
        setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyLeftTouchUpInside(_ sender: Any) {
        latestGpsLocation =  CLLocation(latitude:latestGpsLocation.coordinate.latitude, longitude:latestGpsLocation.coordinate.longitude - JOYSTICK_X_INC)
        setMarker(coord: latestGpsLocation)
    }
    
    /* =========================================================================
     Use the middle button to go back to the mniddke
     ======================================================================== */
    @IBAction func btnJoyMiddleTouchUpInside(_ sender: Any) {
        latestGpsLocation = CLLocation(latitude:CAMPUS_LATITUDE, longitude:CAMPUS_LONGITUDE)
        setMarker(coord: latestGpsLocation)
    }
    

}


/* =========================================================================
 ======================================================================== */
//----------  ----------

