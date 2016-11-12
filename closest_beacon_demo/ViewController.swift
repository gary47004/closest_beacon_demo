//
//  ViewController.swift
//  closest_beacon_demo
//
//  Created by gary on 2016/10/15.
//  Copyright © 2016年 gary. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseDatabase

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var startTime: UILabel!
    @IBOutlet weak var arrivalTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    @IBOutlet weak var departureTime: UILabel!
    
    @IBAction func rangingButton(sender: UIButton) {
        locationManager.startRangingBeaconsInRegion(region)
        locationManager(locationManager, didRangeBeacons:testBeacon, inRegion: region)
    }
    @IBAction func button(sender: UIButton) {
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-M-dd-H:mm"
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child(storagePlace).observeEventType(.Value, withBlock: {
            snapshot in
            
            let start = snapshot.value!["Start Date"] as? String
            let end = snapshot.value!["End Date"] as? String
            self.arrival = snapshot.value!["arrivalTime"] as? String
            self.departure = snapshot.value!["departureTime"] as? String
            let startCompare = format.dateFromString(start!)
            let endCompare = format.dateFromString(end!)
            
            let compareResultA = startCompare!.compare(self.now)
            let compareResultB = endCompare!.compare(self.now)
            self.intervalA = Int(startCompare!.timeIntervalSinceDate(self.now))
            self.intervalB = Int(endCompare!.timeIntervalSinceDate(self.now))
            
        })
    }
    
    
    let locationManager = CLLocationManager()
    let region = CLBeaconRegion(proximityUUID: NSUUID(UUIDString:"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!, identifier: "THLight")
    let testBeacon = [CLBeacon]()
    
    let now = NSDate()
    let formatter = NSDateFormatter()
    let myCalendar = NSCalendar.currentCalendar()
    var weekDay = ""
    var firstDay = ""
    var storagePlace = ""
    var arrival:String?
    var departure:String?
    var intervalA:Int?
    var intervalB:Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        weekDay = "00"+"\(myCalendar.component(.Weekday, fromDate: now))"
        
        let addingNumber = 1-Int(myCalendar.component(.Weekday, fromDate: now))
        
        let firstDayOfWeek = myCalendar.dateByAddingUnit(.Day, value: addingNumber, toDate: now, options: [])
        //現在日期加上addingNumber的日期
        formatter.dateFormat = "yyyy-M-dd"
        firstDay = formatter.stringFromDate(firstDayOfWeek!)
        
        storagePlace = "employeeShift/"+"010/"+"\(firstDay)"+"/102306111/"+"\(weekDay)"
        
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child(storagePlace).observeEventType(.Value, withBlock: {
            snapshot in
            
            self.startTime.text = snapshot.value!["Start Date"] as? String
            self.endTime.text = snapshot.value!["End Date"] as? String
            self.arrivalTime.text = snapshot.value!["arrivalTime"] as? String
            self.departureTime.text = snapshot.value!["departureTime"] as? String
            print("hi")
        })
        
        
        locationManager.delegate = self;
        
        if(CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse){
        locationManager.requestWhenInUseAuthorization()
        }
        
        
        print("HI"+"\(self.arrival)")
//允許app使用位置
//        locationManager.startRangingBeaconsInRegion(region)
////開始搜尋
//        locationManager(locationManager, didRangeBeacons:testBeacon, inRegion: region)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        let nearBeacons = beacons.filter{ $0.proximity != CLProximity.Unknown}
//只要有測到，就放進nearBeacons
        if (nearBeacons.count > 0){
            
            locationManager.stopRangingBeaconsInRegion(region)
//停止搜尋
            let date = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-M-dd-H:mm"
            let time = dateFormatter.stringFromDate(date)
            
            
            let clockIn = UIAlertController(title: "是否打卡？", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            //actionsheet無法
            let goToWork = UIAlertAction(title: "上班打卡", style: UIAlertActionStyle.Default, handler:{
                (action:UIAlertAction) -> () in
                self.postArrival(time)
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            let getOff = UIAlertAction(title: "下班打卡", style: UIAlertActionStyle.Default, handler: {
                (action:UIAlertAction) -> () in
                self.postDeparture(time)
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            let cancel = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler:{
                (action:UIAlertAction) -> () in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            let close = UIAlertAction(title: "關閉", style: UIAlertActionStyle.Default, handler:{
                (action:UIAlertAction) -> () in
                self.dismissViewControllerAnimated(true, completion: nil)
            })
            if(arrival == nil && departure == nil){
                clockIn.addAction(goToWork)
                clockIn.addAction(cancel)
                self.presentViewController(clockIn, animated: true, completion: nil)
                
            }else if(arrival != nil && departure == nil){
                clockIn.addAction(getOff)
                clockIn.addAction(cancel)
                self.presentViewController(clockIn, animated: true, completion: nil)
                
            }else if(arrival != nil && departure != nil){
                clockIn.title = "您已經在這個時段打卡完成"
                clockIn.message = "同一時段無法打兩次卡"
                clockIn.addAction(close)
                self.presentViewController(clockIn, animated: true, completion: nil)
            }
        }
        
        print("BEACONS: " + "\(beacons)")
        print("NEAR BEACONS: " + "\(nearBeacons)")
        
    }
    
    
    func postArrival(arrival : String){
        
        let post : [String : AnyObject] = ["arrivalTime" : arrival]
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child(storagePlace).updateChildValues(post)
        
        if(intervalA<0){
            let number = String(0-intervalA!)
            let late : [String : String] = ["late" : number]
            databaseRef.child(storagePlace).updateChildValues(late)
        }else{
            let number = "0"
            let late : [String : String] = ["late" : number]
            databaseRef.child(storagePlace).updateChildValues(late)
        }
    
    }
    
    func postDeparture(departure : String){
        
        let post : [String : AnyObject] = ["departureTime" : departure]
        
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child(storagePlace).updateChildValues(post)
        
        if(intervalB>0){
            let number = String(intervalB!-0)
            let leaveEarly : [String : String] = ["leaveEarly" : number]
            databaseRef.child(storagePlace).updateChildValues(leaveEarly)
        }else{
            let number = "0"
            let leaveEarly : [String : String] = ["leaveEarly" : number]
            databaseRef.child(storagePlace).updateChildValues(leaveEarly)
        }

    }
    

}

