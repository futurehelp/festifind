//
//  MapViewController.swift
//  festifind
//
//  Created by Andrew Gonzales-Raines on 6/6/18.
//  Copyright © 2018 Andrew Gonzales. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import SwiftyJSON

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // Localize all the variables.
    var locationManager: CLLocationManager!
    let regionRadius: CLLocationDistance = 10000
    var coordinate1: CLLocationCoordinate2D!
    let mapView = MKMapView()
    var festival: [Festival] = []
    var startLocation = 1
    var flightLink = ""
    
    //  GPS variables.
    var coordinates: [CLLocationCoordinate2D] = []
    var initialLocation: CLLocation!
    var userLatitude: Double!
    var userLongitude: Double!
    var festivalLatitude: Double!
    var festivalLongitude: Double!
    let annotation = MKPointAnnotation()
    
    //  Get the Apple device.
    var iPhoneX = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  Get the window variables.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        
        if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436 {
            //iPhone X
            print("iphone X")
            iPhoneX = true
        }
        
        //  This will be scalable when inserting join festival data with festival friends.
        festivalLatitude = festival[0].latitude
        festivalLongitude = festival[0].longitude
        
        //  Add the navigation background color.
        var firstFrame = CGRect()
        if(iPhoneX == true)
        {
            firstFrame = CGRect(x: 0, y: 140, width: self.view.frame.width, height: self.view.frame.height)
        }
        else
        {
            firstFrame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height)
        }
        let firstView = UIView(frame: firstFrame)
        firstView.backgroundColor = UIColor(hex: "2A2B2E")
        view.addSubview(firstView)
        
        //  Add the left navigation extended cancel button.
        let extendedButton = UIButton(frame: CGRect(x: 0, y: barHeight + 16, width: 100, height: 100))
        extendedButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(extendedButton)
        
        //  Add the left navigation cancel button.
        let button = UIButton(frame: CGRect(x: 40, y: barHeight + 26, width: 40, height: 40))
        let image2 = UIImage(named: "back_button") as UIImage?
        button.setImage(image2, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(button)
        
        //  Add the ticket navigation button.
        let ticketButton = UIButton(frame: CGRect(x: 120, y: barHeight + 26, width: 40, height: 40))
        let ticketImage = UIImage(named: "tickets-new") as UIImage?
        ticketButton.setImage(ticketImage, for: .normal)
        ticketButton.addTarget(self, action: #selector(ticketButtonAction), for: .touchUpInside)
        self.view.addSubview(ticketButton)
        
        //  Add the flight navigation button.
        let flightButton = UIButton(frame: CGRect(x: 200, y: barHeight + 26, width: 40, height: 40))
        let flightImage = UIImage(named: "flight-new") as UIImage?
        flightButton.setImage(flightImage, for: .normal)
        flightButton.addTarget(self, action: #selector(flightButtonAction), for: .touchUpInside)
        self.view.addSubview(flightButton)
        
        //  Add the car navigation button.
        let carButton = UIButton(frame: CGRect(x: 280, y: barHeight + 26, width: 40, height: 40))
        let carButtonImage = UIImage(named: "car") as UIImage?
        carButton.setImage(carButtonImage, for: .normal)
        carButton.addTarget(self, action: #selector(carButtonAction), for: .touchUpInside)
        self.view.addSubview(carButton)
        
        //  Add the festival info.
        let festivalTitle = UILabel(frame: CGRect(x: 20, y: barHeight + 100, width: displayWidth, height: 100))
        festivalTitle.lineBreakMode = .byWordWrapping
        festivalTitle.numberOfLines = 0
        let festivalTitleColor = UIColor(hex: "58A4B0")
        festivalTitle.textColor = festivalTitleColor
        festivalTitle.font = UIFont (name: "Georgia-Bold", size: 18)
        festivalTitle.text = self.festival[0].title
        festivalTitle.sizeToFit()
        view.addSubview(festivalTitle)
        
        //  Add the MapView border.
        let mapViewBackground = UILabel(frame: CGRect(x: 14, y: barHeight + 160, width: (displayWidth - 40) + 12, height: 220 + 80))
        mapViewBackground.backgroundColor = UIColor(hex: "373F51")
        mapViewBackground.clipsToBounds = true
        mapViewBackground.layer.cornerRadius = 4
        view.addSubview(mapViewBackground)
        
        //  Add the MapView object.
        mapView.frame = CGRect(x: 20, y: barHeight + 200, width: displayWidth - 40, height: 220)
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.delegate = self
        mapView.clipsToBounds = true
        mapView.layer.cornerRadius = 2
        view.addSubview(mapView)
       
        //  Add the single day tickets label.
        let singleDayLabel = UILabel(frame: CGRect(x: 18, y: barHeight + 160, width: displayWidth / 2, height: 40))
        singleDayLabel.lineBreakMode = .byWordWrapping
        singleDayLabel.numberOfLines = 0
        let singleDayLabelColor = UIColor(hex: "A9BCD0")
        singleDayLabel.textColor = singleDayLabelColor
        singleDayLabel.font = UIFont (name: "Avenir-Heavy", size: 18)
        
        var singleDayStart = "Single Day: $"
        if self.festival[0].tickets[0] == "N/A"
        {
            singleDayStart = "Single Day: "
        }
        
        singleDayLabel.text = singleDayStart + self.festival[0].tickets[0]
        singleDayLabel.layer.cornerRadius = 4
        singleDayLabel.clipsToBounds = true
        singleDayLabel.backgroundColor = UIColor(hex: "373F51")
        singleDayLabel.frame.origin.y = mapView.frame.origin.y - singleDayLabel.frame.height
        view.addSubview(singleDayLabel)
        
        //  Add the weekend tickets label.
        let weekendLabel = UILabel(frame: CGRect(x: mapView.frame.maxX - 80, y: barHeight + 160, width: (displayWidth / 2) + 2, height: 40))
        weekendLabel.lineBreakMode = .byWordWrapping
        weekendLabel.numberOfLines = 0
        weekendLabel.textColor = singleDayLabelColor
        weekendLabel.textAlignment = .right
        weekendLabel.font = UIFont (name: "Avenir-Heavy", size: 18)
        
        var weekendStart = "All Days: $"
        if self.festival[0].tickets[1] == "N/A"
        {
            weekendStart = "All Days: "
        }
        weekendLabel.text = weekendStart + self.festival[0].tickets[1]
        weekendLabel.backgroundColor = UIColor(hex: "373F51")
        weekendLabel.layer.cornerRadius = 4
        weekendLabel.clipsToBounds = true
        weekendLabel.frame.origin.y = mapView.frame.origin.y - weekendLabel.frame.height
        weekendLabel.frame.origin.x = self.view.frame.width - weekendLabel.frame.width - 20
        view.addSubview(weekendLabel)
        
        weekendLabel.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 5).isActive = true
        weekendLabel.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: -2).isActive = true
        
        determineMyCurrentLocation()
        
        let festivalCoordinates = CLLocationCoordinate2D(latitude: festival[0].latitude, longitude: festival[0].longitude)
        self.coordinates.append(festivalCoordinates)
        
        let coordinatesToAppend = CLLocationCoordinate2D(latitude: userLatitude, longitude: userLongitude)
        self.coordinates.append(coordinatesToAppend)
        
        let geodesic = MKPolyline(coordinates: &self.coordinates, count: self.coordinates.count)
        self.mapView.add(geodesic)
        
        let aclCoordinate = CLLocation(latitude: festival[0].latitude, longitude: festival[0].longitude)
        let userCoordinate = CLLocation(latitude: userLatitude, longitude: userLongitude)
        
        //  Calculate the distance.
        let distanceInMiles = (aclCoordinate.distance(from: userCoordinate)) * 0.000621371
        print(distanceInMiles)
        
        
        annotation.coordinate = CLLocationCoordinate2D(latitude: festival[0].latitude, longitude: festival[0].longitude)
        mapView.addAnnotation(annotation)
        
        
        //  URL for festival and user airport json.
        let festivalAirportURL = "http://iatageo.com/getCode/" + String(festival[0].latitude) + "/" + String(festival[0].longitude)
        let userAirportURL = "http://iatageo.com/getCode/" + String(userLatitude) + "/" + String(userLongitude)
        
        //  Get user airport.
        Alamofire.request(userAirportURL, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                var userAirportCode = json["code"].string!
                if(userAirportCode == "BFK")
                {
                    userAirportCode = "DEN"
                }
                
                print("userAirportCode: \(userAirportCode)")
                self.flightLink = "https://skiplagged.com/flights/" + userAirportCode + "/"
                
                let startDateArray = self.festival[0].startDate.components(separatedBy: "-")
                var startDateEnd = String(Int(startDateArray[2])! - 1)
                if Int(startDateEnd)! < 10
                {
                    startDateEnd = "0" + startDateEnd
                }
                let newStartDate = startDateArray[0] + "-" + startDateArray[1] + "-" + String(startDateEnd)
                print("new start date: \(newStartDate)")
                
                let endDateArray = self.festival[0].endDate.components(separatedBy: "-")
                var endDateEnd = String(Int(endDateArray[2])! + 1)
                if Int(endDateEnd)! < 10
                {
                    endDateEnd = "0" + endDateEnd
                }
                let newEndDate = endDateArray[0] + "-" + endDateArray[1] + "-" + endDateEnd
                print("new end date: \(newEndDate)")
                
                //TEST DATA
                //AUS/2018-07-12/2018-07-18"
                
                //  Get festival airport.
                Alamofire.request(festivalAirportURL, method: .get).validate().responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        print("JSON: \(json)")
                        if let festivalAirportCode = json["code"].string
                        {
                            self.flightLink = self.flightLink + festivalAirportCode + "/" + newStartDate + "/" + newEndDate
                            
                            print("flightLink: \(self.flightLink)")
                            
                            print("festivalAirportCode: \(festivalAirportCode)")
                        }
                    case .failure(let error):
                        print(error)
                        self.flightLink = self.flightLink + "/" + newStartDate
                        
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
        
        
        
        //NOTES:
        //  color scheme: https://coolors.co/d8dbe2-a9bcd0-58a4b0-373f51-1b1b1e
        
        //  Add venue name label.
        let venueLabel = UILabel(frame: CGRect(x: 20, y: mapView.frame.maxY + 10, width: displayWidth / 2, height: 30))
        venueLabel.lineBreakMode = .byWordWrapping
        venueLabel.numberOfLines = 0
        let venueLabelColor = UIColor(hex: "989FCE")
        venueLabel.textColor = venueLabelColor
        venueLabel.font = UIFont (name: "Avenir-Light", size: 16)
        print("endIndex: \(self.festival[0].artists.endIndex - 1)")
        venueLabel.text = self.festival[0].artists[self.festival[0].artists.endIndex - 1]
        
        view.addSubview(venueLabel)
        
        //  good color scheme with gun metal: https://coolors.co/272838-5d536b-7d6b91-989fce-347fc4
        
        //  Add the distance Label.
        let distanceLabel = UILabel(frame: CGRect(x: displayWidth / 2, y: mapView.frame.maxY + 10, width: displayWidth / 2, height: 30))
        
        distanceLabel.textAlignment = .right
        distanceLabel.textColor = venueLabelColor
        distanceLabel.font = UIFont (name: "Avenir-Light", size: 16)
        distanceLabel.text = String(roundToNearestQuarter(num: Float(distanceInMiles))) + " miles"
        distanceLabel.frame.origin.y = mapView.frame.maxY + 10
        distanceLabel.frame.origin.x = self.view.frame.width - distanceLabel.frame.width - 20
        view.addSubview(distanceLabel)
        
        //  Add the festival date label.
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd, yyyy"
        dateFormatterPrint.amSymbol = "AM"
        dateFormatterPrint.pmSymbol = "PM"
        
        let festivalDateLabel = UILabel(frame: CGRect(x: 20, y: festivalTitle.frame.minY - 12, width: displayWidth - 20, height: 100))
        print("festival: \(self.festival[0].title) and startDate: \(self.festival[0].startDate)")
        
        //  Get the correct startDate.
        
        if let date = dateFormatterGet.date(from: self.festival[0].startDate){
            print(dateFormatterPrint.string(from: date))
            let festivalDate = dateFormatterPrint.string(from: date)
            festivalDateLabel.lineBreakMode = .byWordWrapping
            festivalDateLabel.numberOfLines = 0
            festivalDateLabel.textAlignment = .left
            let festivalDateLabelColor = UIColor(hex: "D8DBE2")
            festivalDateLabel.textColor = festivalDateLabelColor
            festivalDateLabel.font = UIFont (name: "Optima-Italic", size: 12)
            festivalDateLabel.text = festivalDate
            
            
            if let date = dateFormatterGet.date(from: self.festival[0].endDate){
                let festivalDate = dateFormatterPrint.string(from: date)
                festivalDateLabel.text = festivalDateLabel.text! + " - " + festivalDate
            }
            view.addSubview(festivalDateLabel)
            
            festivalDateLabel.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: -8).isActive = true
        }
        else {
            print("There was an error decoding the string.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
    }

    func roundToNearestQuarter(num : Float) -> Float {
        return round(num * 4.0)/4.0
    }
    
    func determineMyCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //  Update the user's current location.
        
        let userLocation: CLLocation = locations[0] as CLLocation
        
        let userlongitude = userLocation.coordinate.longitude
        let userlatitude = userLocation.coordinate.latitude
        let newDistance = CLLocation(latitude: userlatitude, longitude: userlongitude).distance(from: CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude))
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 2 * newDistance, 2 * newDistance)
        let adjustRegion = self.mapView.regionThatFits(region)
        self.mapView.setRegion(adjustRegion, animated:true)
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        //  We ran into an error. Let's see what it is, and fix it...
        print("Error \(error)")
    }
    
    @objc func buttonAction(sender: UIButton!) {
        let myViewController = storyboard?.instantiateViewController(withIdentifier: "viewController") as! ViewController
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(myViewController, animated: false, completion: nil)
    }
    
    @objc func ticketButtonAction(sender: UIButton!) {
        UIApplication.shared.open(URL(string : festival[0].link)!, options: [:], completionHandler: { (status) in
            
        })
    }
    
    @objc func flightButtonAction(sender: UIButton!) {
        UIApplication.shared.open(URL(string : flightLink)!, options: [:], completionHandler: { (status) in
            
        })
    }
    
    @objc func carButtonAction(sender: UIButton!) {
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
        {
            let urlString = "http://maps.google.com/?daddr=\(festival[0].latitude),\(festival[0].longitude)&directionsmode=driving"
            
            if let url = URL(string: "\(urlString)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        else
        {
            let urlString = "http://maps.apple.com/maps?daddr=\(festival[0].latitude),\(festival[0].longitude)&dirflg=d"
            if let url = URL(string: "\(urlString)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 3
        
        return renderer
    }

}
