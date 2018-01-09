//
//  CAVStreamer.swift
//  audioStream
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit
import AVKit        //for AVPlayerViewController


/* =========================================================================
 The CAVStreamer manages the A/V for the Campus Tour App.
 CAVStreamer derives from NSObject so that we can use the notification
 system to get notice when audio or video media has finished playing.
 ======================================================================== */
class CAVStreamer: NSObject {
    
    private var player:AVPlayer!
    private var avPlayerController:AVPlayerViewController!
    
    /* =========================================================================
     Create the avPlayerController on startup
     ======================================================================== */
    override init()
    {
        super.init()
        
        //instantiate the A/V player
        avPlayerController = AVPlayerViewController()

        //fill the View with the content (may clip the video)
        avPlayerController.videoGravity = "AVLayerVideoGravityResizeAspectFill"
        
        /* register for notification when an AVPalerItem has finished playing.  Note that
         notification will not be sent if the player is stopped.  We will use the
         default application notification center*/
        NotificationCenter.default.addObserver(self, selector: #selector(mediaPlayBackFinished(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil);

    }
    
    
    /* =========================================================================
     Add a deinit to this class to remove it from the default notification
     center
     ======================================================================== */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    /* =========================================================================
     callback frunction for the media finished playing notification
     ======================================================================== */
    @objc func mediaPlayBackFinished(_ notification: Notification){
        print("playbackFinished")
    }
    
    /* =========================================================================
     playMedia() is used to stream either audio or video media based on a
     supplied URL.  The only require parameter is the url.  This will result
     in an audio only output.  For video, you must supply the width and height
     of the target UIWindow in which the video will be displayed.  The
     function returns a UIView which most likely needs to be added as a
     subview in the caller's UI.  Example:
     
     AVStreamer = CAVStreamer()
     avUIView = AVStreamer.playMedia(url:a_video_url, outputUIViewWidth:100, outputUIViewHeight:200)
     callerView.addSubview(avUIView)

     ======================================================================== */
    func playMedia(url:String, outputUIViewWidth:CGFloat?=nil, outputUIViewHeight:CGFloat?=nil, showPlaybackControls:Bool=true) -> UIView? {
        
        //we will only play one thing at a time
        if player != nil {
            stop()
        }
        
        //create a player object based on the provided URL
        player = AVPlayer(url: URL(string: url)!)
        //set the volume to max (rely on the device's volume control)
        player.volume = 1.0
        player.rate = 1.0   //not sure what this does.  Is it needed?  -JV
        
        /* if either the output width or height is not specified, assume audio only.
        in that case, the function will return nil.  Otherwise, we will create a
         UIView using the avPlayerController and return it to the caller. */
        if outputUIViewWidth != nil && outputUIViewHeight != nil {
            avPlayerController.player = player
            avPlayerController.view.frame = CGRect(x: 0, y: 0, width: outputUIViewWidth!, height: outputUIViewHeight!)
            avPlayerController.showsPlaybackControls = showPlaybackControls
            player.play()
            return avPlayerController.view
        }
        
        //begin play
        player.play()
        return nil
    }
    
    
    /* =========================================================================
     ======================================================================== */
    func stop(){
        pause()
        player!.seek(to: CMTimeMake(0, 1))
    }
    
    /* =========================================================================
     ======================================================================== */
    func replay(){
        player!.seek(to: CMTimeMake(0, 1))
        unpause()
    }
    
    /* =========================================================================
     ======================================================================== */
    func pause(){
        player.pause()
    }
    
    /* =========================================================================
     ======================================================================== */
    func unpause(){
        player.play()
    }

}



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------
