//
//  HomeViewController.swift
//  CampusTour
//
//  Created by Jerry Volcy on 1/2/18.
//  Copyright © 2018 Jerry Volcy. All rights reserved.
//

import UIKit

/* =========================================================================
 ======================================================================== */
class HomeViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    //refeence to the tour choice picker
    @IBOutlet weak var pikTourChoice: UIPickerView!
    
    //reference to the "Start Tour" button
    @IBOutlet weak var btnStart: UIButton!
    
    let tourPickerData = [["General College Tour", "Parent's Tour", "Student Tour", "Historic Tour"]]
    
    /* =========================================================================
     viewDidLoad()
     ======================================================================== */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TO DO:  The tourPickerData should be loaded from an on-line source
        
        //assign the tour picker delegate and data source to self
        pikTourChoice.dataSource = self
        pikTourChoice.delegate = self

        print("HomeViewController viewDidLoad")
    }

    /* =========================================================================
     didReceiveMemoryWarning()
     ======================================================================== */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// ********************* Start Tour Picker Section *********************
    
    /* =========================================================================
     The number of compoenets in the picker data (# of lists in the datasource)
     ======================================================================== */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        //we only have 1 picker, so we don't need to check which one is invoked
        return tourPickerData.count
    }
    
    /* =========================================================================
     The number of items in the specified list in the data source
     ======================================================================== */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        //we only have 1 picker, so we don't need to check which one is invoked
        return tourPickerData[component].count
    }
    
    /* =========================================================================
      The data to return for the row and component (column) that's being passed in
     ======================================================================== */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        //we only have 1 picker, so we don't need to check which one is invoked
        return tourPickerData[component][row]
    }
    
    /* =========================================================================
      Catpure the picker view selection
     ======================================================================== */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        //we only have 1 picker, so we don't need to check which one invoked this call.
        print(tourPickerData[component][row])
    }
    
// ********************* End Tour Picker Section *********************
    
    
    
    /* =========================================================================
     ======================================================================== */
    @IBAction func btnStartTouchUpInside(_ sender: Any) {
        //campusTour!.func3()
        
        //un-hide the tabBar
        tabBarController?.tabBar.isHidden = false
        
        //select the second tab
        tabBarController?.selectedIndex = 1
        
        //re-label the "Start Tour" button to "Start New Tour"
        btnStart.setTitle("Start New Tour", for: .normal)
    }
    
}

