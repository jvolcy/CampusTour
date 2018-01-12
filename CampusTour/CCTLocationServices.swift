//
//  CCTLocationServices.swift
//  gpsTest
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//
//
/* =========================================================================
 This file houses the Campus Tour location services, CTLocationServices,
 class.  CTLS (Campus Tour Location Services) periodically reads the
 current GPS position and posts a custom notification to the default
 notifications center when the location reading becomes available.
 Initialize with an update interval in seconds.
 
 This class derives from CLLocationManagerDelegate interface and
 implements 2 of the stipulated functions of that interface:
 didUpdateLocations and didFailWithError.  The function stubs are
 
 func locationManager(_ manager: CLLocationManager,
 didUpdateLocations locations: [CLLocation]) { }
 
 and
 
 func locationManager(_ manager: CLLocationManager,
 didFailWithError error: Error) { }

 The didUpdateLocation delegate of the CLLocationsManager interface
 posts a notification to the default application Notifications Center.
 Any actor wishing to be notified of the availability of new GPS
 data should register a notification observer.  Here is the sample code
 to do so:
 
 NotificationCenter.default.addObserver(self, selector: #selector(my_func(_:)),
         name: locationServicesUpdatedLocations, object: nil);
 
 Here, my_func() is the location function on the actor's side.  It can be
 implemented with this skeleton code:
 
 @objc func my_func(_ notification: Notification){
     let coord:gps_coord = notification.object as! gps_coord
     print("got new location!", coord.toString())
 }
 Be sure to remove your observer before you quit:
 deinit {
 NotificationCenter.default.removeObserver(self)
 }


 Your application should update the "Privacy - Location When In Use Usage
 Description" subkey in the project Info.plist.  This is a subkey of
 the "Information Property List" key.  A suggested value for this
 subkey is "This App needs your location to deliver information about
 your location on campus."  If the subkey does not exist, it should
 be added under the "Information Property List" key.
 
 ======================================================================== */

import Foundation
import CoreLocation

//create a new global notification name for new GPS data
let locationServicesUpdatedLocations = NSNotification.Name ("locationServicesUpdatedLocations")

class CCTLocationServices: NSObject, CLLocationManagerDelegate {
    private var locationManager : CLLocationManager!
    private var timer : Timer?
    private var bPause = false
    
    init (updateIntervalSec:Double) {
        super.init()
        
        //create the locationManager
        locationManager = CLLocationManager()
        //set the desired location accuracy to max
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //assign the delegate
        locationManager.delegate = self
        //get user permission to use location services
        locationManager.requestWhenInUseAuthorization()
        
        //setup the timer
        startTimer(updateIntervalSec: updateIntervalSec)
    }

    /* =========================================================================
     CLLocationManagerDelegate:didUpdateLocations delegate
     ======================================================================== */
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        /*
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        let latestCoord = gps_coord(latitude: latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude)
         
         NotificationCenter.default.post(name: locationServicesUpdatedLocations, object: latestCoord)
        */
        
        
        if SCCT_DebugMode == false {
            /* update the global GPS coordinates if we are not in
            debug mode.  In debug mode, those coordinates are updated
            elsewhere. */
            latestGpsLocation = locations[locations.count - 1]
        }
        
        /* post a notification to the default notification center.  The object
         to be passed to the notification observers is the newly acquired
         GPS coordinates. */
        /* note that whether or not we are in debug mode, we send a
         notification of a newly available location. */
        NotificationCenter.default.post(name: locationServicesUpdatedLocations, object: latestGpsLocation)

    }

    /* =========================================================================
     CLLocationManagerDelegate:didFailWithError delegate
     ======================================================================== */
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("******", error, "******")
    }


    /* =========================================================================
     The internal CTLS timer start automatically when init() executes.
     However, the timer can be stopped by a call to stopTimer() and can be
     restarted by calling startTimer().  If the timer is already running,
     this function simply unpauses it, if it is paused.  Otherwise, the
     function has no effect.  Use the stop/start functions to change the
     CTLS timer interval.  To simply pause the retrieval of new GPS data
     w/o starting/stopping the periodic timer, use the pause() and
     unpause() functions.
     ======================================================================== */
    func startTimer(updateIntervalSec:Double) {
        if timer == nil {
            //timer = Timer()
            timer = Timer.scheduledTimer(
                timeInterval: updateIntervalSec, //in seconds
                target: self, //where you'll find the selector (next argument)
                selector: #selector(timerFunction), //MyClass is the current class
                userInfo: nil,
                repeats: true)  //runs continuously
        }
        
        //un-pause() location services in case it has been paused.
        unpause()
    }

    
    /* =========================================================================
     Call this function to stop the internal CTLS timer.  The timer can be
     re-started with a call to startTimer()
     ======================================================================== */
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        
    }

    /* =========================================================================
     Whereas the start/stop timer functions start and stop the timer, which in
     turn, halts location services, pausing/unpausing the CTLS allows the timer
     loop to continue, but when the system is paused, location services are not
     invoked.  This reduces batter consumption and should be used while a CT
     video is playing.  This could also be used if the user decides to manually
     pause the application.
     ======================================================================== */
    func pause(){
        bPause = true   /* indicate that no new location data is required
         until the system is unpaused. */
    }
    
    /* =========================================================================
     Un-pause the retrieval of new GPS data
     ======================================================================== */
    func unpause(){
        bPause = false  /* indicate that new location data is needed.  The new data
        will arrive at the next timerFunction invocation. */
    }

    /* =========================================================================
     The timer function is called by the system Timer everytime the timer
     period expires.
     ======================================================================== */
    @objc private func timerFunction()
    {
        /* retrieving the GPS location is expensive.  Use pause()/unpause()
        to suspend the activity w/o halting the timer. */
        if bPause == false {
            locationManager.requestLocation()
            /* the didUpdateLocations() delegate will be called when the request is complete */
        }
    }

    
}




/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------
