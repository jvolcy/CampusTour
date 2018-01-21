//
//  CPoiManager.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import Foundation
import CoreLocation

/* =========================================================================
 ======================================================================== */
class CPoiManager {
    
    /* create a constant to hold the location of the CT POI FILE, scct_poi.tsv.
     SCCT = Spelman College Campus Tour
     The file scct_poi.tsv is a tab-separated value file.  Each line of the
     file is a record that corresponds to a single POI.  Each record is divided
     into 7 fields: as follows:
     field      Type    Description/Purpose
     0          String  POI_ID = a unique ID String
     1          String  TITLE = the title for the POI
     2          String  DECS = the tour details for the particular POI
     3          Double  LATITUDE = GPS latitude
     4          Double  LONGITUDE = GPS longitude
     5          Double  RADISU_FT = the radius (in feet) from the POI where it is considered to be "in range"
     6          String  URL = the URL for the media content associated with the POI*/
    
    
    // The POIs array is an array of poi structures.  Each structure contains all the data outlined above for each POI
    //(POI_ID, TITLE, DESC, LATITUDE, LONGITUDE, RADIUS_FT, URL)
    var POIs = [CPoi]()
    //var POIs = [(POI_ID:String, TITLE:String, DESC:String, LATITUDE:Double, LONGITUDE:Double, RADIUS_FT:Double, URL:String)]()
    
    //base URL for all data
    var CtDataBaseUrl:String!
    
    //filename of the POI index file
    var CtPoiIndexFilename:String!
    
    //full URL of the POI index file
    var CtPoiIndexFile:String!
    
    /* =========================================================================
     The initializer will open the POI file and load its contents into the POIs array
     ======================================================================== */
    init (CtDataBaseUrl:String, CtPoiIndexFilename:String) {
        self.CtDataBaseUrl = CtDataBaseUrl
        self.CtPoiIndexFilename = CtPoiIndexFilename
        
        //compose the full URL of the POI index file
        CtPoiIndexFile = CtDataBaseUrl+CtPoiIndexFilename
        
        //read the JSON POI index file
        readPoiData(poiIndexFileUrl: CtPoiIndexFile)

        /*
        for poi in POIs {
            print(poi.toString(), "\n")
        }
        */
    }   //init()
    
    
    /* =========================================================================
     this function reads the JSON POI index file and stores its contents in
     the CPoi array, POIs
     ======================================================================== */
    func readPoiData(poiIndexFileUrl:String) {
        if let url = URL(string: poiIndexFileUrl) {
            do {
                //read the data from the json file
                let data = try Data(contentsOf: url)
                
                //create a [String:String ]dictionary of the entries
                let d = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                //"pois" is an array of dictionaries
                for poi in d!["pois"] as! [[String:String]] {
                    //each poi is a dictionary that describes a point of interest
                    //extract the data from the record
                    let poiID = poi["POI_ID"]!
                    let title = poi["TITLE"]!
                    //set latitude, logitude and radiusFT to 0 if they are nil
                    let latitude = Double(poi["LATITUDE"]!) ?? 0.0
                    let longitude = Double(poi["LONGITUDE"]!) ?? 0.0
                    let radiusInMeters = (Double(poi["RADIUS_FT"]!) ?? 0.0) * 0.3048   //convert to meters
                    var rtf_url = poi["RTF_URL"]!
                    var img_url = poi["IMG_URL"]!
                    var audio_url = poi["AUDIO_URL"]!
                    var video_url = poi["VIDEO_URL"]!
                    
                    /* Here, we append the the filename to the base URL to
                     create full URL names for the rtf, jpg, mp3 and mp4
                     files.  The special cases of DEFAULT and NONE are
                     handled here. */
                    
                    //compose the RTF URL
                    switch rtf_url {
                    case "DEFAULT":
                        //for this case, use the POI_ID as the filename
                        rtf_url = CtDataBaseUrl + poiID + ".rtf"
                    case "NONE":
                        //for this case, leave the url as "NONE"
                        break
                    default:
                        //for all other cases, append the supplied filename to the base URL
                        rtf_url = CtDataBaseUrl + rtf_url
                    }
                    
                    //compose the JPG URL
                    switch img_url {
                    case "DEFAULT":
                        //for this case, use the POI_ID as the filename
                        img_url = CtDataBaseUrl + poiID + ".jpg"
                    case "NONE":
                        //for this case, leave the url as "NONE"
                        break
                    default:
                        //for all other cases, append the supplied filename to the base URL
                        img_url = CtDataBaseUrl + img_url
                    }
                    
                    //compose the MP3 URL
                    switch audio_url {
                    case "DEFAULT":
                        //for this case, use the POI_ID as the filename
                        audio_url = CtDataBaseUrl + poiID + ".mp3"
                    case "NONE":
                        //for this case, leave the url as "NONE"
                        break
                    default:
                        //for all other cases, append the supplied filename to the base URL
                        audio_url = CtDataBaseUrl + audio_url
                    }
                    
                    //compose the MP4 URL
                    switch video_url {
                    case "DEFAULT":
                        //for this case, use the POI_ID as the filename
                        video_url = CtDataBaseUrl + poiID + ".mp4"
                    case "NONE":
                        //for this case, leave the url as "NONE"
                        break
                    default:
                        //for all other cases, append the supplied filename to the base URL
                        video_url = CtDataBaseUrl + video_url
                    }
                    
                    //build the poi object using the full URLs
                    let new_poi = CPoi(poiID: poiID,
                                       title: title,
                                       coord: CLLocation(latitude:latitude, longitude:longitude),
                                       radiusInMeters: radiusInMeters,
                                       rtf_url: rtf_url,
                                       img_url: img_url,
                                       audio_url: audio_url,
                                       video_url: video_url)
                    
                    POIs.append(new_poi)    //add the poi to the POIs array
                }   //for poi in
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of \(poiIndexFileUrl)")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL: \(poiIndexFileUrl)")
        }

    }

    
    /* =========================================================================
     This function returns the closest POI that is in range of the supplied coordinates
     ======================================================================== */
    func getNearestPoiInRange(coord:CLLocation) -> CPoi? {
        //find all POIs in range
        let poisInRange = getPoisInRange(coord: coord)
        
        if poisInRange.count > 0 {
            //Use minPoi and minDist as search indexes for finding the minimum distance
            //Initialize these appropriately for the search
            var minPoi = poisInRange[0] //assume the first POI is the closest
            var minDist = poisInRange[0].radiusInMeters!   //start with a value guaranteed to be >= the min distance
            
            //go through the list of POIs in range and find the minimum
            for poi in poisInRange {
                //calculate the distance to the poi in the list
                let dist = poi.coord.distance(from: coord)
                if dist < minDist { //new min found
                    minDist = dist
                    minPoi = poi
                }   //if dist
            }   //for poi in poisInRange
            return minPoi
        }   //if poisInRange.count > 0

        return nil
    }

    /* =========================================================================
     Get a list of all POIs in range of the specified coordinates
     ======================================================================== */
    func getPoisInRange(coord:CLLocation) -> [CPoi] {
        var poisInRange = [CPoi]()
        
        //traverse the list of POIs and find those in range
        for poi in POIs {
            if poi.isInRange(gpsCoord: coord) == true {
                poisInRange.append(poi)
            }   // if poi.isInRange...
        }   //for poi in POIs
        return poisInRange
    }   //func


    /* =========================================================================
     Find a POI with a POI_ID that matchews the provided string
     ======================================================================== */
    func getPoi(byID:String) -> CPoi? {
        /* search the pois in the POIs list and return the first one with
        an ID that matches byID. */
        for poi in POIs {
            if poi.poiID == byID {
                return poi
            }
        }
        //none was found; return nil
        return nil
    }

    
    
    /* =========================================================================
     This searches for any POI with a video url that matches the supplied
     string.  Note that this may not result in a unique answer as multiple
     POIs may share the same video url.  The function returns nil if no
     match is found.
     ======================================================================== */
    func getPoi(byVideoUrl:String) -> CPoi? {
        /* search the pois in the POIs list and return the first one with
         an ID that matches byID. */
        for poi in POIs {
            if poi.video_url == byVideoUrl {
                return poi
            }
        }
        //none was found; return nil
        return nil
    }

    /* =========================================================================
     This searches for any POI with an audio url that matches the supplied
     string.  Note that this may not result in a unique answer as multiple
     POIs may share the same audio url.  The function returns nil if no
     match is found.
     ======================================================================== */
    func getPoi(byAudioUrl:String) -> CPoi? {
        /* search the pois in the POIs list and return the first one with
         an ID that matches byID. */
        for poi in POIs {
            if poi.audio_url == byAudioUrl {
                return poi
            }
        }
        //none was found; return nil
        return nil
    }

    
    /* =========================================================================
     ======================================================================== */

    func DegreesToRadians(_ degrees: Double ) -> Double {
        return degrees * Double.pi / 180.0
    }
    
    /* =========================================================================
     ======================================================================== */
    func RadiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
    
    
    /* =========================================================================
     Function to calculate the bearing in radians of one CLLocation relative to
     another.
     Adapted from
     https://stackoverflow.com/a/31817498
     ======================================================================== */
    func getBearingRadian(fromLocation:CLLocation, toLocation:CLLocation) -> Double {
        
        let lat1 = DegreesToRadians(fromLocation.coordinate.latitude)
        let lon1 = DegreesToRadians(fromLocation.coordinate.longitude)
        
        let lat2 = DegreesToRadians(toLocation.coordinate.latitude);
        let lon2 = DegreesToRadians(toLocation.coordinate.longitude);
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x)
        
        return radiansBearing
    }
    
    /* =========================================================================
     Function to calculate the bearing in degrees of one CLLocation relative to
     another.
     Adapted from
     https://stackoverflow.com/a/31817498
     ======================================================================== */
    func getBearingDegrees(fromLocation:CLLocation, toLocation:CLLocation) -> Double{
        return   getBearingRadian(fromLocation:fromLocation, toLocation:toLocation)
    }

    
    /* =========================================================================
     This function returns the bearing of a poi relative to an observer's
     position and heading.
     
     radians heading
               0
               ^
               |
     3pi/2 <--- ---> pi/2
               |
               v
               pi
     ======================================================================== */
    func poiBearingRadians (fromLocation:CLLocation, headingRadians:Double, poi:CPoi) -> Double {
        //calculate the bearing relative to North
        let northBearing = getBearingRadian(fromLocation: fromLocation, toLocation: poi.coord)
        //now offset by the user's actual heading
        let bearing = northBearing - headingRadians
        
        //we want a value between 0 and 2pi
        //while bearing < 0 { bearing += 2*Double.pi}
        
        return bearing
    }

    /* =========================================================================
     This function returns the bearing of a poi relative to an observer's
     position and heading.
     
     degree heading
               0
               ^
               |
       270 <--- ---> 90
               |
               v
              180
     ======================================================================== */
    func poiBearingDegrees (fromLocation:CLLocation, headingDegrees:Double, poi:CPoi) -> Double {
        let bearing = poiBearingRadians(fromLocation: fromLocation, headingRadians: DegreesToRadians(headingDegrees), poi: poi)
        return RadiansToDegrees(bearing)
    }

    
}   //CPoiManager clasas



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------

