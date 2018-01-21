//
//  CCampusTour.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import Foundation
import CoreLocation


/* =========================================================================
 The CCampusTour class is the central process to the CampusTour application.
 It coordinates the LocationServices, PoiManager and AVStreamer to
 serve up GPS-based tour data to the UI.
 ======================================================================== */
class CCampusTour : NSObject {
    
    
    var ctLocationServices : CCTLocationServices!
    var poiManager : CPoiManager!
    
    init(CtDataBaseUrl: String, CtPoiIndexFilename:String){
        super.init()
        
        //instantiate the GPS lcoations services
        ctLocationServices = CCTLocationServices(updateIntervalSec:4.0)
        
        //instantiate the POI manager
        poiManager = CPoiManager(CtDataBaseUrl:CtDataBaseUrl, CtPoiIndexFilename:CtPoiIndexFilename)
        
        /* sign up for notification from location services.  This notification
         is a custom notification that tell us that a newly update GPS
         location is available */
        NotificationCenter.default.addObserver(self, selector: #selector(gotNewLocationFromLocationServices(_:)),
                                               name: locationServicesUpdatedLocations, object: nil);

        /*
        //let test_coord = gps_coord(latitude: 33.745135,longitude: -84.412361) //near Mcalpin
        let test_coord = CLLocation(latitude: 33.745193,longitude: -84.409265)   //tapley & SS

        let poisInRange = poiManager.getPoisInRange(coord: test_coord)
        print("#poisInRange = \(poisInRange.count)")
        for poi in poisInRange {
            print("\(poi.poiID!) distance=\(poi.coord.distance(from: test_coord)) meters.")
        }
        
        print("distance to ACC = \(poiManager.getPoi(byID: "ACC")?.coord.distance(from: test_coord))")
        */
    }


    /* =========================================================================
     Add a deinit to this class to remove it from the default notification
     center
     ======================================================================== */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /* =========================================================================
     newly updated GPS coordinate notifications callback function.  The
     notificaiton argument is a gps_coord object.
     ======================================================================== */
    @objc func gotNewLocationFromLocationServices(_ notification: Notification){
        let coord:CLLocation = notification.object as! CLLocation
        //print("got new location! (\(coord.coordinate.latitude), \(coord.coordinate.longitude)")

    }
    

    
}



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------
