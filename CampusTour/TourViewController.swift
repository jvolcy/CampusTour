//
//  TourViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit
import AVKit

class TourViewController: UIViewController {

    @IBOutlet weak var txtTourInfo: UITextView! //main tour information attributed text display
    @IBOutlet weak var btnMap: UIButton!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var btnRePlay: UIButton!
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet var imgTourImage: UIImageView!    //central display of the tour view
    @IBOutlet weak var lblGpsCoord: UILabel!
    @IBOutlet weak var vStackJoyStick: UIStackView!
    
    
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
        
        /* register for notification when an AVPalerItem has finished playing.  Note that
         notification will not be sent if the player is stopped.  We will use the
         default application notification center*/
        NotificationCenter.default.addObserver(self,
                            selector: #selector(mediaPlayBackFinished(_:)),
                            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
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
        should be removed. */
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
        
        let targetImgOrigin = getImageOffsetInUImageView(imageView: targetView)
        
        //translate the point to put it in frame coordinates
        let targetLocationInFrameCoord = CGPoint(x:targetLocation.x + targetImgOrigin.x, y:targetLocation.y + targetImgOrigin.y)
        
        //print(targetLocation, targetLocationInFrameCoord)
        
        //draw the marker at the offset position
        marker.center = CGPoint(x:targetLocationInFrameCoord.x,  y:targetLocationInFrameCoord.y)
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
    func getImageOffsetInUImageView(imageView:UIImageView) -> (CGPoint) {
        //let campusImageOriginRelativeToSuperView = imgCampusMap.frame.origin
        let imagePixelSize = imageView.image!.size
        let imageFrameSize = imageView.frame.size
        let imageAR = imagePixelSize.width/imagePixelSize.height
        let imageFrameAR = imageView.frame.width/imageView.frame.height
        
        var imagePointSize = CGSize()
        //determine the location of the image relative to its super view
        if imageFrameAR > imageAR {
            print("limited by height")
            imagePointSize.height = imageFrameSize.height
            imagePointSize.width = imagePointSize.height*imagePixelSize.width/imagePixelSize.height
            
            //print(imagePointSize)
        }
        else {
            print("limited by width")
            imagePointSize.width = imageFrameSize.width
            imagePointSize.height = imagePointSize.width*imagePixelSize.height/imagePixelSize.width
            
            //print(imagePointSize)
        }
        
        //let targetImgOrigin = CGPoint(x:0, y:0)
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
        var tour_image:UIImage?
        
        switch tourMode {
        case .map:
            image = UIImage(named: "film")
            tour_image = UIImage(named: "campus_map")
            imgTourImage.contentMode = .scaleAspectFit
            tourMode = .walk
        case .walk:
            image = UIImage(named: "map")
            tour_image = UIImage(named: "default_arch")
            imgTourImage.contentMode = .scaleAspectFill
            tourMode = .map
        }   //switch
        
        btnMap.setImage(image, for: .normal)
        imgTourImage.image = tour_image //.setImage(tour_image, for: .normal)        i
        

    }   //func
    
    
    let CAMPUS_TOP_LATITUDE = 33.747151
    let CAMPUS_BOTTOM_LATITUDE = 33.743234
    let CAMPUS_LEFT_LONGITUDE = -84.414763
    let CAMPUS_RIGHT_LONGITUDE = -84.408572
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyUpTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyDownTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyRightTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnJoyLeftTouchUpInside(_ sender: Any) {
    }
    
    /* =========================================================================
     Use the middle button to go back to the mniddke
     ======================================================================== */
    @IBAction func btnJoyMiddleTouchUpInside(_ sender: Any) {
        let CAMPUS_LATITUDE = (CAMPUS_TOP_LATITUDE+CAMPUS_BOTTOM_LATITUDE)/2
        let CAMPUS_LONGITUDE = (CAMPUS_LEFT_LONGITUDE+CAMPUS_RIGHT_LONGITUDE)/2
    }
    
    /* =========================================================================
     campus upper left:  33.747151, -84.414763
     campus lower right: 33.743234, -84.408572
     Delta:               0.003917,  -0.006191
     ======================================================================== */
    @IBAction func btnJoyUpTouchDownRepeat(_ sender: Any) {
    }
}


