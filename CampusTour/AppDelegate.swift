//
//  AppDelegate.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit
import CoreLocation

//global campusTour object
var campusTour:CCampusTour? = nil

//global Latest GPS coordinates
//var latestGpsLocation = CLLocation()

//config file
let CtConfigFileUrl = "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/ct_config.json"

/* SCCT_DebugMode is a global boolean that switches between running in debug
 mode and regular mode. */
var SCCT_DebugMode = true

/*  GPS_DebugMode is a global boolean that switches between running in
 GPS debug mode and regular mode.  In GPS debug mode, the global GPS locations,
 latestGpsLocation, are simulated through the use of a virtual joystick.*/
var GPS_DebugMode = false

//create the application configuration dictionary.  Keys and arguments of the dictionary are both strings
var appConfig = [String:String]()


/* =========================================================================
 this function reads the contents of the configuration filename and
 builds the application configuration dictionary, appConfig.  The
 configuration file is a json file containing an dictionary of string
 keys and string values only.
 ======================================================================== */
func readConfigFile(fileUrl:String) {
    if let url = URL(string: fileUrl) {
        do {
            //read the data from the json file
            let data = try Data(contentsOf: url)
            
            //create a [String:String ]dictionary of the entries
            appConfig = try JSONSerialization.jsonObject(with: data, options: []) as! [String: String]
            
        }   //do
        catch {
            // contents could not be loaded
            print("could not read contents of \(fileUrl)")
        }
    }   // if let url = URL(string:
    else {
        // the URL was bad!
        print("bad URL: \(fileUrl)")
    }
}


/* =========================================================================
 ======================================================================== */
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    /* =========================================================================
     ======================================================================== */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //first thing we have to do is read the configuration file for the application
        readConfigFile(fileUrl: CtConfigFileUrl)

        
        print("***** Config Data *****")
        for item in appConfig {
            print("\(item.key) = \(item.value)")
        }
        print("***********************")
        
        
        let CtPoiIndexFilename = appConfig["poiIndexFile"]!  //filename for poi index data (read from config file)

        // Override point for customization after application launch.
        //print("CFBundleVersion", Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        //print("CFBundleShortVersionString", Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        campusTour=CCampusTour(CtDataBaseUrl:appConfig["baseUrl"]!, CtPoiIndexFilename:CtPoiIndexFilename)
        return true
    }

    /* =========================================================================
     ======================================================================== */
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    /* =========================================================================
     ======================================================================== */
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    /* =========================================================================
     ======================================================================== */
   func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    /* =========================================================================
     ======================================================================== */
   func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    /* =========================================================================
     ======================================================================== */
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

