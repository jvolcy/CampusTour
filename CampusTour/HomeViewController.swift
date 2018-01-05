//
//  FirstViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var pikTourChoice: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("HomeViewController viewDidLoad")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func btnStartTouchUpInside(_ sender: Any) {
        //campusTour!.func3()
    }
    
}

