//
//  RegionAnnotation.swift
//  TMT_Geofencing
//
//  Created by Trương Thắng on 1/4/17.
//  Copyright © 2017 Trương Thắng. All rights reserved.
//

import MapKit

class RegionAnnotation: NSObject,MKAnnotation {
    var region: CLRegion
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance {
        willSet {
            willChangeValue(forKey: "subtitle")
        }
        didSet {
            didChangeValue(forKey: "subtitle")
        }
    }
    var title: String?
    var subtitle: String? {
        return "Lat: \(coordinate.latitude), Lon: \(coordinate.longitude), Rad: \(radius)"
    }
    
    init(withRegion newRegion: CLCircularRegion) {
        coordinate = newRegion.center
        radius = newRegion.radius
        region = newRegion
        title = "Monitored Region"
    }
    
}
