//
//  AboutViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("AboutViewController viewDidLoad")
        campusTour!.subscribeForNewCoordNotification(f:self.callback)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func callback(coord:gps_coord)->(){
        print("AboutView callback: \(coord.toString())")
    }

    
}

