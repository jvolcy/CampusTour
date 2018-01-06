//
//  CCampusTour.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit
import CoreLocation

/* =========================================================================
 The CCampusTour class is the central process to the CampusTour application.
 It coordinates the LocationServices, PoiManager and AVStreamer to
 serve up GPS-based tour data to the UI.
 ======================================================================== */
class CCampusTour : NSObject, CLLocationManagerDelegate {
    
    /* actors within the application that wish to be notified when
     a newly updated gps coordinate is available should subscribe for
     notification by using the subscribeForNewCoordNotification()
     bu passing a callback function of the form (gps_coord)->().  The
     array newCoordSubscribers is a list of subscribers.  Once an
     actor has subscribed, there is currently no way to un-subscribe. */
    var newCoordSubscribers : [(gps_coord)->()] = [(gps_coord)->()]()
    
    var ctLocationServices : CCTLocationServices!
    var poiManager : CPoiManager!

    override init(){
        super.init()
        
        //ctLocationServices = CCTLocationServices(updateIntervalSec:2.0, delegate: self)
        poiManager = CPoiManager()
    }
    
    /* =========================================================================
     ======================================================================== */
    func subscribeForNewCoordNotification(f : @escaping (gps_coord)->()){
        newCoordSubscribers.append(f)
    }
    
    
    /* =========================================================================
     CLLocationManagerDelegate:didUpdateLocations delegate
     ======================================================================== */
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        
        let latestCoord = gps_coord(latitude: latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude)
        
        //update the label
        /*
        let msg = "(Latitude, logitude) =" + String(format: "%.4f",
                                                            latestLocation.coordinate.latitude) +
            ", " + String(format: "%.4f",
                          latestLocation.coordinate.longitude) +
            "\nhorizontalAccuracy =" + String(format: "%.4f",
                                              latestLocation.horizontalAccuracy) +
            "\n<b>altitude</b> =" + String(format: "%.4f",
                                           latestLocation.altitude) +
            "\nverticalAccuracy =" + String(format: "%.4f",
                                            latestLocation.verticalAccuracy) /* +
            "\n\nCount: " + String(updateCount)
        
        updateCount += 1 */
         */
        
        //print("\(locations.count): \(latestCoord.toString())")
        
        //call all subscribers to new coordinates
        for subscriberCallback in newCoordSubscribers{
            subscriberCallback(latestCoord)
        }
    }

    
    /* =========================================================================
     CLLocationManagerDelegate:didFailWithError delegate
     ======================================================================== */
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("******", error, "******")
    }


    
}



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------
