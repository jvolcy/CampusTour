//
//  CPoiManager.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/4/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit


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
    var POIs = [CPoi]()
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
                        //set latitude, logitude and radiusFT to 0 if they are nil
                        let latitude = Double(poiRecordFields[2]) ?? 0.0
                        let longitude = Double(poiRecordFields[3]) ?? 0.0
                        let radiusFt = Double(poiRecordFields[4]) ?? 0.0
                        let rtf_url = String(poiRecordFields[5])
                        let img_url = String(poiRecordFields[6])
                        let audio_url = String(poiRecordFields[7])
                        let video_url = String(poiRecordFields[8])
                        
                        //build the poi object
                        let new_poi = CPoi()
                        new_poi.poiID = poiID
                        new_poi.title = title
                        new_poi.coord = gps_coord(latitude:latitude, longitude:longitude)
                        new_poi.radiusFt = radiusFt
                        new_poi.rtf_url = rtf_url
                        new_poi.img_url = img_url
                        new_poi.audio_url = audio_url
                        new_poi.video_url = video_url
                        
                        POIs.append(new_poi)    //add the poi to the POIs array
                    }   //if poiRecordFields[0][poiRecordFields[0].startIndex] != "#"
                    
                }   //for poiRecord in poiRecords
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of \(CT_POI_FILE)")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL for \(CT_POI_FILE)")
        }
        
        /*for poi in POIs {
            print(poi.toString(), "\n")
        }
        */
    }   //init()
    
    
    /* =========================================================================
     This function returns the closest POI that is in range of the supplied coordinates
     ======================================================================== */
    func getNearestPoiInRange(coord:gps_coord) -> CPoi? {
        //find all POIs in range
        let poisInRange = getPoisInRange(coord: coord)
        
        if poisInRange.count > 0 {
            //Use minPoi and minDist as search indexes for finding the minimum distance
            //Initialize these appropriately for the search
            var minPoi = poisInRange[0] //assume the first POI is the closest
            var minDist = poisInRange[0].radiusFt!   //start with a value guaranteed to be >= the min distance
            
            //go through the list of POIs in range and find the minimum
            for poi in poisInRange {
                //calculate the distance to the poi in the list
                let dist = poi.distanceFrom(gpsCoord: coord)!
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
    func getPoisInRange(coord:gps_coord) -> [CPoi] {
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

}   //CPoiManager clasas



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------

