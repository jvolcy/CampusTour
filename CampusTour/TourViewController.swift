//
//  SecondViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class TourViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // radiansToDegrees function
    func radiansToDegrees (_ radians: Double)->Double {
        return radians * 180 / Double.pi
    }
    
    // radiansToDegrees function
    func degreesToRadians (_ degrees: Double)->Double {
        return degrees * Double.pi / 180
    }
    
    
     /* This function calculates the distance between two (latitude, longitude) coordinates using the haversine formula.
     The Swift implementation is adapted from a script provided by Moveable Type under a Creative Commons license. */
    func calculateDistance(lat1:Double, lon1:Double, lat2:Double, lon2:Double) -> Double {
        //let R = 6371.0; // km
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


}


