//
//  CPoi.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/6/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit


/* =========================================================================
 define a point of interest class.  This contains all the data about
 an individual POI.
 
 Note that POIs must be a class and not a structure.  This is becuase
 the POI status has to persist as a POI is passed from function to
 function.  Structures are passed by value.  Chaning the status of a
 copy would not change the status of a commonly accessed object.
 ======================================================================== */
class CPoi
{
    //enumerate the possible status of a POI: NotVisited, Visted or Other
    enum EPoiStatus {
        case NotVisited
        case Visited
        case Other
    }
    
    var poiID:String!
    var title:String!
    var coord:gps_coord!
    var radiusFt:Double!
    var rtf_url:String!
    var img_url:String!
    var audio_url:String!
    var video_url:String!
    var status = EPoiStatus.NotVisited
    
    //default initializer does nothing
    init(){
        status = .NotVisited
    }
    
    /* =========================================================================
     initializer
     ======================================================================== */
    init(poiID:String, title:String, coord:gps_coord, radiusFt:Double, rtf_url:String, img_url:String, audio_url:String, video_url:String) {
        self.poiID = poiID
        self.title = title
        self.coord = coord
        self.radiusFt = radiusFt
        self.rtf_url = rtf_url
        self.img_url = img_url
        self.audio_url = audio_url
        self.video_url = video_url
        status = .NotVisited
    }
    
    /* =========================================================================
     String formatting of CPoi
     ======================================================================== */
    func toString() ->String {
        let str = "poiID: \(poiID ?? "nil")\n" +
            "title: \(title ?? "nil")\n" +
            "coord: (\(coord != nil ? "\(coord!.latitude!), \(coord!.longitude!)" : "nil"))\n" +
            "radiusFt: \(radiusFt != nil ? "\(radiusFt!)" : "nil")\n" +
            "rtf_url: \(rtf_url ?? "nil")\n" +
            "img_url: \(img_url ?? "nil")\n" +
            "audio_url: \(audio_url ?? "nil")\n" +
        "video_url: \(video_url ?? "nil")\n"
        
        return str
    }
    
    /* =========================================================================
     calculate the distance from the poi
     ======================================================================== */
    func distanceFrom(gpsCoord:gps_coord) -> Double?
    {
        return calculateDistance(coord1: gpsCoord, coord2: coord)
    }

    /* =========================================================================
     calculate the distance from the poi
     ======================================================================== */
    func isInRange(gpsCoord:gps_coord) -> Bool
    {
        //calculate and unwrap the distance from the provided GPS coord
        if let dist = calculateDistance(coord1: gpsCoord, coord2: coord) {
            //if the unwrapped distance is within range, return true, otherwise return false
            return (dist <= radiusFt ? true : false)
        }   //if let dist...
        else {
            //if the calculated distance is nil, return false
            return false
        }   //else
    }   //func isInRange( ...
    
}
