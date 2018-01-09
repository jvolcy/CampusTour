//
//  AboutViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    @IBOutlet weak var txtAboutInfo: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        displayAttributedTextFromURL(rtfFileUrl: "https://raw.githubusercontent.com/jvolcy/SCCampusTour/master/about.rtf", targetView: txtAboutInfo)
    }


    /* =========================================================================
     ======================================================================== */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /* =========================================================================
     This function reads the contents of an RTF file through the supplied URL.
     The function then sends the attributed text to the supplied UITextView.
     ======================================================================== */
    func displayAttributedTextFromURL(rtfFileUrl:String, targetView:UITextView) {
        
        //extract the data from the POI file and create an array of POIs.
        if let url = URL(string: rtfFileUrl) {
            do {
                //read the data from the rtf file
                let data = try Data(contentsOf: url)
                
                //convert the data into an atrributed string
                let richText = try NSAttributedString(data: data, options: [:], documentAttributes: nil)
                
                //display in the textfiled (which must be configured for attributed text, not plain text)
                targetView.attributedText = richText
            }   //do
            catch {
                // contents could not be loaded
                print("could not read contents of \(rtfFileUrl)")
            }
        }   // if let url = URL(string:
        else {
            // the URL was bad!
            print("bad URL for \(rtfFileUrl)")
        }
    }
    

    
}



/* =========================================================================
 ======================================================================== */
//----------  ----------
//----------  ----------

