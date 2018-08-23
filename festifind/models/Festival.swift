//
//  Festival.swift
//  festifind
//
//  Created by Andrew Gonzales-Raines on 6/5/18.
//  Copyright © 2018 Andrew Gonzales. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

//  Festival Object for JSON feed.
struct Festival {
    
    var id: Int
    var title: String
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var tickets: Array<String>
    var artists: Array<String>
    var startDate: String
    var endDate: String
    var thumbnail: String
    var link: String
    
    init(id: Int, title: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, tickets: Array<String>, artists: Array<String>, startDate: String, endDate: String, thumbnail: String, link: String) {
        self.id = id
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.artists = artists
        self.tickets = tickets
        self.startDate = startDate
        self.endDate = endDate
        self.thumbnail = thumbnail
        self.link = link
    }
    
}

