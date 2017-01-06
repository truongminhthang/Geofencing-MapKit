//
//  RegionAnnotationView.swift
//  TMT_Geofencing
//
//  Created by Trương Thắng on 1/5/17.
//  Copyright © 2017 Trương Thắng. All rights reserved.
//

import MapKit



class RegionAnnotationView: MKPinAnnotationView {
    weak var map : MKMapView?
    weak var theAnnotation: RegionAnnotation?
    var isRadiusUpdated: Bool = false
    var radiusOverlay: MKCircle?
    init(with annotation: MKAnnotation) {
        super.init(annotation: annotation, reuseIdentifier: annotation.title ?? "reuseIdentifier")
        canShowCallout = true
        isMultipleTouchEnabled = false
        isDraggable = true
        animatesDrop = true
        map = nil
        theAnnotation = annotation as? RegionAnnotation
        pinTintColor = UIColor.purple
        radiusOverlay = MKCircle.init(center: theAnnotation!.coordinate, radius: theAnnotation!.radius)
        map?.add(radiusOverlay!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func removeRadiusOverlay() {
        // Find the overlay for this annotation view and remove it if it has the same coordinates.
        for overlay in map!.overlays {
            if overlay.isKind(of: MKCircle.self) {
                let circleOverlay = overlay as! MKCircle
                let coord = circleOverlay.coordinate
                if coord.latitude == self.theAnnotation?.coordinate.latitude && coord.longitude == self.theAnnotation?.coordinate.longitude {
                    map!.remove(overlay)
                }
            }
        }
        isRadiusUpdated = false
    }
    
    // Update the circular overlay if the radius has changed.
    func updateRadiusOverlay() {
        if isRadiusUpdated == false {
            self.isRadiusUpdated = true
            canShowCallout = false
            let overlay = MKCircle(center: theAnnotation!.coordinate, radius: theAnnotation!.radius)
            map?.add(overlay)
            canShowCallout = true
        }
    }
    
}
