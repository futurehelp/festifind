//
//  ViewController.swift
//  festifind
//
//  Created by Andrew Gonzales-Raines on 5/31/18.
//  Copyright © 2018 Andrew Gonzales. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreLocation
import MapKit


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    //  Create the object for all of the blog articles.
    var festivals: [Festival] = []
    var searchList: [Festival] = []

    //  Variable for the table view.
    private var myTableView: UITableView!
    
    //  Variables for the searchbar.
    var searchBar: UISearchBar!
    var searchFound = 0
    
    //  Variables to start tracking location.
    var locationManger = CLLocationManager()
    var currentLocation: CLLocation!
    
    //  Variable for filtered data.
    var filteredData: [String]!
    
    //  Variable for tracking which iPhone device is present.
    var iPhoneX = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Variables for bar height, display width, and display height.
        let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
        let displayWidth: CGFloat = self.view.frame.width
        let displayHeight: CGFloat = self.view.frame.height
        
        //  Check which device is present.
        if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436 {
            print("iphone X")
            iPhoneX = true
        }
        
        var firstFrame = CGRect()
        //  Add navigation frame with the appropriate background color.
        if(iPhoneX == true)
        {
            //  We found an iPhoneX so let's build the nav frame with this device.
            firstFrame = CGRect(x: 0, y: 140, width: self.view.frame.width, height: self.view.frame.height)
        }
        else
        {
            //  We did NOT find an iPhoneX so let's build the nav frame with this device.
            firstFrame = CGRect(x: 0, y: 100, width: self.view.frame.width, height: self.view.frame.height)
        }
        
        //  Color the frame and add it to the view.
        let firstView = UIView(frame: firstFrame)
        firstView.backgroundColor = UIColor(hex: "2A2B2E")
        view.addSubview(firstView)
        
        //  NOTES:
        //  cool grey background
        //  hex: 5A5A66
        
        //  New Apple authoriation functions, so let us call them.
        locationManger.requestWhenInUseAuthorization()
        locationManger.requestAlwaysAuthorization()
        
        //  Get the user's location.
        if( CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() ==  .authorizedAlways){
            
            currentLocation = locationManger.location
            
        }
        
        //  Build the search bar with the most fascinating properties on earth...
        searchBar = UISearchBar(frame: CGRect(x: 20, y: barHeight + 16, width: 260, height: 20))
        searchBar.searchBarStyle = UISearchBarStyle.prominent
        searchBar.placeholder = " Search..."
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.layer.cornerRadius = 10
        searchBar.layer.borderWidth = 2
        searchBar.layer.borderColor = UIColor.darkGray.cgColor
        searchBar.clipsToBounds = true
        searchBar.tintColor = UIColor(hex: "2A2B2E")
        searchBar.backgroundImage = UIImage()
        let textFieldInsideUISearchBar = searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideUISearchBar?.font = UIFont (name: "AvenirNext-BoldItalic", size: 16.0)
        searchBar.delegate = self
        self.view.addSubview(searchBar)
        
        //  Add location pin icon.
        let goButton = UIButton(frame: CGRect(x: searchBar.frame.maxX + 20, y: barHeight + 24, width: 34, height: 34))
        let menuButtonImage = UIImage(named: "location-pin-circle") as UIImage?
        goButton.setImage(menuButtonImage, for: .normal)
        goButton.addTarget(self, action: #selector(locateButton), for: .touchUpInside)
        self.view.addSubview(goButton)
        
        //  Create the blog table.
        myTableView = UITableView(frame: CGRect(x: 0, y: barHeight + 100, width: displayWidth, height: (displayHeight - barHeight) - 100))
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        myTableView.dataSource = self
        myTableView.delegate = self
        myTableView.backgroundColor = UIColor(hex: "2A2B2E")
        myTableView.separatorStyle = .none
        myTableView.separatorColor = UIColor(hex: "A188A6")
        self.view.addSubview(myTableView)
        
        //  Fetch all the JSON data.
        executeFetch()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        //  Search Function for the search bar.
        
        //  Start from nothing.
        self.searchList.removeAll()
        self.searchFound = 0
        if(searchText.isEmpty != true)
        {
            //  Let's loop through the entire count before we proceed to the individuals...
            for i in (0..<festivals.count)
            {
                //  Search the artist list for the search characters.
                let filteredList = festivals[i].artists.filter { item in
                    return item.lowercased().contains(searchText.lowercased())
                }
                
                //  We found matches, so let us list them for the user.
                if(filteredList.count > 0)
                {
                    let isIndexValid = festivals.indices.contains(i)
                    if(isIndexValid == true)
                    {
                        print(festivals[i].title)
                        //  Populate our new object with beautiful data.
                        self.searchList.append(Festival(id: self.festivals[i].id, title: self.festivals[i].title as String, latitude: self.festivals[i].latitude as CLLocationDegrees, longitude: self.festivals[i].longitude as CLLocationDegrees, tickets: self.festivals[i].tickets , artists: self.festivals[i].artists , startDate: self.festivals[i].startDate as String, endDate: self.festivals[i].endDate as String, thumbnail: self.festivals[i].thumbnail as String, link: self.festivals[i].link as String))
                        self.searchFound = 1
                    }
                }
            }
        }
        myTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func executeFetch() {
        //  Load the blog from the json feed off the raspi.
        Alamofire.request("http://apbracing.com/festival3.json", method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                //  Clear the array.
                self.festivals.removeAll()
                
                //  Capture and parse the JSON data.
                let json = JSON(value)
                print("JSON: \(json)")
                let jsonObjectArray = JSON(value).array!
                
                for jsonObject in jsonObjectArray {
                    let id = jsonObject["id"].int!
                    let title = jsonObject["title"].string!
                    let latitude = jsonObject["latitude"].double!
                    let longitude = jsonObject["longitude"].double!
                    let tickets = jsonObject["tickets"].arrayObject
                    let artists = jsonObject["artists"].arrayObject
                    let startDate = jsonObject["startDate"].string!
                    let endDate = jsonObject["endDate"].string!
                    let thumbnail = jsonObject["thumbnail"].string
                    let link = jsonObject["link"].string!
                    
                    //  Only display current festivals.
                    let date = Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    let festivalDate = dateFormatter.date(from: endDate)
                    
                    //  Verify it is a valid festival by date, then add the object.
                    if(festivalDate! > date)
                    {
                        self.festivals.append(Festival(id: Int(id), title: title as String, latitude: latitude as CLLocationDegrees, longitude: longitude as CLLocationDegrees, tickets: tickets as! Array<String>, artists: artists as! Array<String>, startDate: startDate as String, endDate: endDate as String, thumbnail: thumbnail as! String, link: link as String))
                    }
                    
                }
            case .failure(let error):
                //  Meh we are at an error, so let's record it and then diagnose it.
                print(error)
            }
            
            //  Reload the table.
            self.myTableView.reloadData()
 
        }
    }

    @objc func locateButton(sender: UIButton!)
    {
        // Error checking for location.
        guard
            let userLatitude = currentLocation?.coordinate.latitude,
            let userLongitude = currentLocation?.coordinate.longitude
            else {
                print("no location found")
                return
        }
        
        //  Find all festivals within 200 miles.
        print(currentLocation.coordinate.latitude)
        print(currentLocation.coordinate.longitude)
        self.searchList.removeAll()
        for i in (0..<festivals.count)
        {
            //  Get festival and user coordinates.
            let festivalCoordinate = CLLocation(latitude: festivals[i].latitude, longitude: festivals[i].longitude)
            let userCoordinate = CLLocation(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
            //  Calculate the distance.
            let distanceInMiles = (festivalCoordinate.distance(from: userCoordinate)) * 0.000621371
            print(distanceInMiles)
            
            //  Check if festival is nearby.
            if(distanceInMiles < 200)
            {
                //  Wow it is nearby, so let us add it to the searchList object.
                self.searchList.append(Festival(id: self.festivals[i].id, title: self.festivals[i].title as String, latitude: self.festivals[i].latitude as CLLocationDegrees, longitude: self.festivals[i].longitude as CLLocationDegrees, tickets: self.festivals[i].tickets , artists: self.festivals[i].artists , startDate: self.festivals[i].startDate as String, endDate: self.festivals[i].endDate as String, thumbnail: self.festivals[i].thumbnail as String, link: self.festivals[i].link as String))
                self.searchFound = 1
            }
            
        }
        myTableView.reloadData()
        //  Remove the keyboard if the user clicks outside the keyboard area.
        dismissKeyboard()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //  Caclulate the table list index.
        if(searchFound == 1)
        {
            return searchList.count
        }
        else
        {
            return festivals.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let displayWidth: CGFloat = self.view.frame.width
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        cell.backgroundColor = UIColor(hex: "2A2B2E")

        //  Load the JSON data
        let url: URL
        if(self.searchFound == 1)
        {
            //  Get the URL.
            print(self.searchList[indexPath.row].thumbnail)
            url = URL(string: self.festivals[indexPath.row].thumbnail)!
        }
        else
        {
            //  Get the URL.
            url = URL(string: self.festivals[indexPath.row].thumbnail)!
        }
        
        
        //  Create a URL Session.
        let session = URLSession.shared
        
        let task = session.dataTask(with:url) { (data, response, error) in
            if error == nil {
                //  Grab the data and translate it into an image.
                let downloadedImage = UIImage(data: data!)
                // Now let us run the UI updating on the main dispatch queue.
                DispatchQueue.main.async {
                    
                    //  Clear the current table.
                    for view in cell.subviews {
                        view.removeFromSuperview()
                    }
                    cell.layer.anchorPointZ = CGFloat(indexPath.row)
                    cell.clipsToBounds = true
                    
                    //  Load the festival image.
                    let image = downloadedImage
                    let imageView = UIImageView(image: image!)
                    imageView.frame = CGRect(x: 20, y: 16, width: 100, height: 60)
                    cell.addSubview(imageView)
                    
                    //  Load the festival title.
                    let festivalTitle = UILabel(frame: CGRect(x: imageView.frame.maxX + 10, y: -20, width: (displayWidth / 2) + 40, height: 100))
                    festivalTitle.lineBreakMode = .byWordWrapping
                    festivalTitle.numberOfLines = 0
                    festivalTitle.textAlignment = .left
                    let festivalTitleColor = UIColor(hex: "A4C2A8")
                    festivalTitle.textColor = festivalTitleColor
                    festivalTitle.font = UIFont (name: "Georgia-Bold", size: 16)
                    festivalTitle.contentMode = .scaleToFill
                    
                    if(self.searchFound == 1 && self.searchList.indices.contains(indexPath.row) == true)
                    {
                        festivalTitle.text = self.searchList[indexPath.row].title
                    }
                    else
                    {
                        festivalTitle.text = self.festivals[indexPath.row].title
                    }
                    cell.addSubview(festivalTitle)
                    
                    //  Add the festival date.
                    let dateFormatterGet = DateFormatter()
                    dateFormatterGet.dateFormat = "yyyy-MM-dd"
                    
                    let dateFormatterPrint = DateFormatter()
                    dateFormatterPrint.dateFormat = "MMM dd, yyyy"
                    dateFormatterPrint.amSymbol = "AM"
                    dateFormatterPrint.pmSymbol = "PM"
                    
                    let festivalDateLabel = UILabel(frame: CGRect(x: imageView.frame.maxX + 10, y: 16, width: 400, height: 100))
                    print("festival: \(self.festivals[indexPath.row].title) and startDate: \(self.festivals[indexPath.row].startDate)")
                    
                    //  Get the correct startDate.
                    var startDate = self.festivals[indexPath.row].startDate
                    if(self.searchFound == 1 && self.searchList.indices.contains(indexPath.row) == true)
                    {
                        startDate = self.searchList[indexPath.row].startDate
                    }
                    
                    //  Get the correct endDate.
                    var endDate = self.festivals[indexPath.row].endDate
                    if(self.searchFound == 1 && self.searchList.indices.contains(indexPath.row) == true)
                    {
                        endDate = self.searchList[indexPath.row].endDate
                    }
                    
                    
                    if let date = dateFormatterGet.date(from: startDate){
                        print(dateFormatterPrint.string(from: date))
                        let festivalDate = dateFormatterPrint.string(from: date)
                        festivalDateLabel.lineBreakMode = .byWordWrapping
                        festivalDateLabel.numberOfLines = 0
                        festivalDateLabel.textAlignment = .left
                        let festivalDateLabelColor = UIColor(hex: "8AC4FF")
                        festivalDateLabel.textColor = festivalDateLabelColor
                        festivalDateLabel.font = UIFont (name: "Optima-Italic", size: 12)
                        festivalDateLabel.text = festivalDate
                        
                        
                        if let date = dateFormatterGet.date(from: endDate){
                            let festivalDate = dateFormatterPrint.string(from: date)
                            festivalDateLabel.text = festivalDateLabel.text! + " - " + festivalDate
                        }
                        
                        cell.addSubview(festivalDateLabel)
                    }
                    else {
                        print("There was an error decoding the string")
                    }
                    
                    
                    
                    //  Add the table separator line.
                    //  Add the navigation background color.
                    let separatorLine = CGRect(x: 0, y: 99, width: displayWidth, height: 1)
                    let separatorLineView = UIView(frame: separatorLine)
                    separatorLineView.backgroundColor = UIColor(hex: "A188A6")
                    cell.addSubview(separatorLineView)
                    
                }
            }
        }
        //  Start the task or resume it.
        task.resume()
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //  Table cell has been selected so let us go to the map screen.
        let myViewController = storyboard?.instantiateViewController(withIdentifier: "mapViewController") as! MapViewController
        
        if(self.searchFound == 1)
        {
            print("use search list")
            myViewController.festival = [searchList[indexPath.row]]
        }
        else
        {
            myViewController.festival = [festivals[indexPath.row]]
        }
        
        myViewController.userLatitude = currentLocation.coordinate.latitude
        myViewController.userLongitude = currentLocation.coordinate.longitude
        
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        self.present(myViewController, animated: false, completion: nil)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}

// Remove the keyboard when necessary.
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
