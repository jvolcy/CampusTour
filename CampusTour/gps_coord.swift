//
//  gps_coord.swift
//  GpsRouteSimulator
//
//  Created by Jerry Volcy on 1/5/18.
//  Copyright © 2018 Spelman College. All rights reserved.
//

import Foundation
/* =========================================================================
 This file contains the definition of the gps_coord structure as well
 as a few supporting functions that manipulate gps_coordinates.
 ======================================================================== */


/* =========================================================================
 define a gps coordinate structure.  This simply holds latitude and
 longitude information.
 ======================================================================== */
struct gps_coord {
    var latitude:Double!
    var longitude:Double!
    
    //default initializer does nothing
    init(){}
    
    //initializer
    init(latitude:Double, longitude:Double){
        self.latitude = latitude
        self.longitude = longitude
    }
    
    //function to convert coords to a formatted string
    func toString() -> String {
        return String(format: "(%0.6f, %0.6f)", latitude, longitude)
    }
}


/* =========================================================================
 radiansToDegrees function
 ======================================================================== */
func radiansToDegrees (_ radians: Double)->Double {
    return radians * 180.0 / Double.pi
}

/* =========================================================================
 radiansToDegrees function
 ======================================================================== */
func degreesToRadians (_ degrees: Double)->Double {
    return degrees * Double.pi / 180.0
}


/* =========================================================================
 This function calculates the distance between two (latitude, longitude)
 coordinates using the haversine formula.
 The Swift implementation is adapted from a script provided by Moveable
 Type under a Creative Commons license.
 
 The distance between the GPS coordinates
 (33.744856, -84.411643) and (33.745541, -84.411243) is estimated to be
 277.47 feet based on data from Google Maps.  This function was tested
 against that value and reports a distance of 277.79.
 ======================================================================== */
func calculateDistance(coord1:gps_coord, coord2:gps_coord) -> Double? {
    //if either coordinate is nill, return nil
    if coord1.latitude==nil || coord1.longitude==nil
        || coord2.latitude==nil || coord2.longitude==nil {return nil}
    
    //extract the latitudes and logitudes from the gps coords
    let lat1 = coord1.latitude!
    let lon1 = coord1.longitude!
    let lat2 = coord2.latitude!
    let lon2 = coord2.longitude!
    
    //do the distance calculations
    let radiusOfEarhInFeet = 20902000.0
    let dLat = degreesToRadians(lat2 - lat1)    //delta latitude
    let dLon = degreesToRadians(lon2 - lon1)    //delta longitude
    //haversine: c is the angular distance in radians, and a is the square of half the chord length between the two coordinates
    let a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    let c = 2 * atan2(sqrt(a), sqrt(1 - a));
    let distance = radiusOfEarhInFeet * c;
    return distance;
}



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------
