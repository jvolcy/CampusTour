//
//  CPoiManager.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

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
 define a point of interest structure.  This contains all the data about
 an individual POI.
 ======================================================================== */
struct poi
{
    var poiID:String!
    var title:String!
    var desc:String!
    var coord:gps_coord!
    //var coord:(latitude:Double, longitude:Double)!
    //var latitude:Double!
    //var longitude:Double!
    var radiusFt:Double!
    var url:String!
    
    //default initializer does nothing
    init(){}
    
    //initializer
    init(poiID:String, title:String, desc:String, coord:gps_coord, radiusFt:Double, url:String) {
        self.poiID = poiID
        self.title = title
        self.desc = desc
        self.coord = coord
        self.radiusFt = radiusFt
        self.url = url
    }
}

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
    private let CT_POI_FILE = "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/scct_poi.tsv"
    
    
    // The POIs array is an array of poi structures.  Each structure contains all the data outlined above for each POI
    //(POI_ID, TITLE, DESC, LATITUDE, LONGITUDE, RADIUS_FT, URL)
    var POIs = [poi]()
    //var POIs = [(POI_ID:String, TITLE:String, DESC:String, LATITUDE:Double, LONGITUDE:Double, RADIUS_FT:Double, URL:String)]()

    
    /* =========================================================================
     The initializer will open the POI file and load its contents into the POIs array
     ======================================================================== */
    init () {
        //extract the data from the POI file and create an array of POIs.
        if let url = URL(string: CT_POI_FILE) {
            do {
                let contents = try String(contentsOf: url, encoding:.ascii)
                
                /* Spliting the contents of the scct_poi.tsv file into individual lines using String.split()
                 is not working.  This appears to be a bug in XCode or Swift.  The segment of code below
                 illustrates the issue:
                 
                 if contents.contains("\r") {
                 print("I found: a NL")
                 }
                 else{
                 print("No NL found")
                 }
                 
                 let x = contents.index(of: "\r")
                 print (x)
                 
                 Here, contents is the string read from the URL.  The code above checks to see if
                 contents contains a "\r".  Then, it attempts to find the location of the "\r" in
                 the string.  When the code runs, it confirms that the string does indeed contain
                 a "\r", but then it fails to find it when a search is performed.
                 
                 In the same way, the line
                 let pois = str.split(separator: "\r")
                 fails to yield the expected array of records in contents.  This is perhaps
                 a problem of encoding, but different encodings didn't yield better results.
                 
                 What seems to work (reason unclear) is to parse through contents
                 character by character and to reconstruct a new string, contents2.
                 Performing split on this new string seems to work.
                 */
                
                var contents2=""
                
                for i in contents {
                    let u = UInt8(ascii: i.unicodeScalars.first!)
                    contents2 += String(UnicodeScalar(UInt8(u)))
                }
                
                //split the file by "\r" characters to create an array of POI records.
                let poiRecords = contents2.split(separator: "\r")//, omittingEmptySubsequences: false)
                
                /* now go through the POI records and split each one into a POI tuple before adding
                 them to the POI array.  All POI records that begin with a "#" character will be ignored. */
                for poiRecord in poiRecords {
                    // Read the records one at a time and check to see that they don't start with a "#"
                    let poiRecordFields = poiRecord.split(separator: "\t", omittingEmptySubsequences: false)
                    
                    //avoid records that have been commented out
                    if poiRecordFields[0][poiRecordFields[0].startIndex] != "#" {
                        //extract the data from the record
                        let poiID = String(poiRecordFields[0])
                        let title = String(poiRecordFields[1])
                        var desc = String(poiRecordFields[2])
                        //set latitude, logitude and radiusFT to 0 if they are nil
                        let latitude = Double(poiRecordFields[3]) ?? 0.0
                        let longitude = Double(poiRecordFields[4]) ?? 0.0
                        let radiusFt = Double(poiRecordFields[5]) ?? 0.0
                        let url = String(poiRecordFields[6])
                        
                        //replace <br> and <BR> with "\n" in the POI description
                        desc = desc.replacingOccurrences(of: "<br>", with: "\n")
                        desc = desc.replacingOccurrences(of: "<BR>", with: "\n")
                        
                        //build the poi object
                        var new_poi:poi = poi()
                        new_poi.poiID = poiID
                        new_poi.title = title
                        new_poi.desc = desc
                        new_poi.coord = gps_coord(latitude:latitude, longitude:longitude)
                        //new_poi.coord = (latitude:latitude, longitude:longitude)
                        //new_poi.latitude = latitude
                        //new_poi.longitude = longitude
                        new_poi.radiusFt = radiusFt
                        new_poi.url = url
                        
                        /*
                        //build the poi tuple
                        let poi = (POI_ID:poiID, TITLE:title, DESC:desc, LATITUDE:latitude, LONGITUDE:longitude, RADIUS_FT:radiusFt, URL:url)
                        */
                        
                        POIs.append(new_poi)    //add the poi to the POIs array
                        }   //if poiRecordFields[0][poiRecordFields[0].startIndex] != "#"
                    
                    print(POIs)
                }   //for poiRecord in poiRecords
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of scct_poi.tsv")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL for scct_poi.tsv")
        }
    }   //init()
    
    
    /* =========================================================================
     This function returns the closest POI that is in range of the supplied coordinates
     ======================================================================== */
    func getNearestPoiInRange(coord:gps_coord) -> poi?
    {
        return nil
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

    
}   //CPoiManager clasas



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------

