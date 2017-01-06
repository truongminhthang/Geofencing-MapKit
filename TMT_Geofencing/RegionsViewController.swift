//
//  ViewController.swift
//  TMT_Geofencing
//
//  Created by Trương Thắng on 1/4/17.
//  Copyright © 2017 Trương Thắng. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RegionsViewController: UIViewController {
    
    @IBOutlet weak var regionsMapView: MKMapView!
    @IBOutlet weak var updatesTableView: UITableView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var addRegion: UIBarButtonItem!
    var updateEvents: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotification()
        updatesTableView.rowHeight = 60
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    lazy var locationManager : CLLocationManager = {
        var locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        return locationManager
    }()
    
    func registerNotification() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] (notification) in
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self?.locationManager.stopUpdatingLocation()
                self?.locationManager.startMonitoringSignificantLocationChanges()
            } else {
                // Error: Significant location change monitoring is not available
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: nil) { [weak self](notification) in
            if CLLocationManager.significantLocationChangeMonitoringAvailable() {
                self?.locationManager.stopMonitoringSignificantLocationChanges()
                self?.locationManager.startUpdatingLocation()
            } else {
                // Error: Significant location change monitoring is not available
            }
            
            if (self?.updatesTableView.isHidden == false) {
                self?.updatesTableView.reloadData()
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            
        case .denied:
            let alertController = UIAlertController(title: "Location services", message: "Location services were previously denied by the user. Please enable location services for this app in settings.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            
        default:
            locationManager.startUpdatingLocation()
        }
        
        regionsMapView.userTrackingMode = .none
        let regions = locationManager.monitoredRegions
        for region in regions {
            let annotation = RegionAnnotation(withRegion: region as! CLCircularRegion)
            regionsMapView.addAnnotation(annotation)
        }
    }
    
    deinit {
        locationManager.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchView(_ sender: Any) {
        // Swap the hidden status of the map and table view so that the appropriate one is now showing.
        regionsMapView.isHidden = !regionsMapView.isHidden
        updatesTableView.isHidden = !updatesTableView.isHidden
        
        addRegion.isEnabled = !regionsMapView.isHidden
        if !updatesTableView.isHidden {
            updatesTableView.reloadData()
        }
    }
    
    @IBAction func addRegionDidTap() {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Create a new region based on the center of the map view.
            let coord = CLLocationCoordinate2D(latitude: regionsMapView.centerCoordinate.latitude, longitude: regionsMapView.centerCoordinate.longitude)
            let newRegion = CLCircularRegion(center: coord, radius: 200, identifier: "\(coord)")
            let myRegionAnnotation = RegionAnnotation(withRegion: newRegion)
            myRegionAnnotation.coordinate = newRegion.center
            myRegionAnnotation.radius = newRegion.radius
            
            self.regionsMapView.addAnnotation(myRegionAnnotation)
            locationManager.startMonitoring(for: newRegion)
        }
    }
    
    
}

// MARK: - UITableViewDataSource

extension RegionsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return updateEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        configureCell(cell: cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        cell.textLabel?.text = updateEvents[indexPath.row]
    }
}

// MARK: - <#Mark#>

extension RegionsViewController: CLLocationManagerDelegate {
    // When the user has granted authorization, start the standard location service.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            // Start the standard location service.
            locationManager.startUpdatingLocation()
        }
    }
    // A core location error occurred.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError: \(error)")
    }
    
    // The system delivered a new location.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count == 1 {
            let userLocation = MKCoordinateRegionMakeWithDistance(locations.first!.coordinate, 1000, 1000)
            regionsMapView.setRegion(userLocation, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let event = "did Enter region: \(region.identifier) at \(Date())"
        updateEvents.append(event)
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let event = "did Exit region: \(region.identifier) at \(Date())"
        updateEvents.append(event)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        let event = "monitoring did fail for region: \(region?.identifier ?? "Unknown") at \(Date())"
        updateEvents.append(event)
    }
}

extension RegionsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is RegionAnnotation {
            
            let currentAnnotaion = annotation as? RegionAnnotation
            let annotationIdentifier = currentAnnotaion?.title ?? ""
            var regionView = regionsMapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? RegionAnnotationView
            
            if regionView == nil {
                regionView = RegionAnnotationView(with: annotation)
                regionView?.map = regionsMapView
                
                // Create a button for the left callout accessory view of each annotation to remove the annotation and region being monitored.
                let removeRegionButton = UIButton(frame: CGRect( origin: CGPoint.zero, size: CGSize(width: 25, height: 25)))
                removeRegionButton.setImage(#imageLiteral(resourceName: "RemoveRegion"), for: UIControlState.normal)
                regionView?.leftCalloutAccessoryView = removeRegionButton
            } else {
                regionView?.annotation = annotation
                regionView?.theAnnotation = annotation as? RegionAnnotation
            }
            regionView?.updateRadiusOverlay()
            return regionView
        }
        return nil
    }
    
    // Return the map overlay that depicts the region.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleView = MKCircleRenderer(overlay: overlay)
        circleView.strokeColor = UIColor.blue
        circleView.fillColor = UIColor.orange.withAlphaComponent(0.3)
        return circleView
    }
    
    // Enable the user to reposition the pins representing the regions by dragging them.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        let regionView =  view as! RegionAnnotationView
        let regionAnotaion = regionView.annotation as! RegionAnnotation
        // If the annotation view is starting to be dragged, remove the overlay and stop monitoring the region.
        if newState == .starting {
            regionView.removeRadiusOverlay()
            locationManager.stopMonitoring(for: regionAnotaion.region)
        }
        if oldState == .dragging && newState == .ending {
            regionView.updateRadiusOverlay()
            let newRegion = CLCircularRegion(center: regionAnotaion.coordinate, radius: 200, identifier: "\(regionAnotaion.coordinate.latitude) - \(regionAnotaion.coordinate.longitude)")
            regionAnotaion.region = newRegion
            locationManager.startMonitoring(for: regionAnotaion.region)
        }
    }
    
    // The X was tapped on a region annotation, so remove that region form the map, and stop monitoring that region.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let regionView = view as! RegionAnnotationView
        let regionAnotaion = regionView.annotation as! RegionAnnotation
        // Stop monitoring the region, remove the radius overlay, and finally remove the annotation from the map.
        locationManager.stopMonitoring(for: regionAnotaion.region)
        regionView.removeRadiusOverlay()
        self.regionsMapView.removeAnnotation(regionAnotaion)
    }
    
}

// MARK: - UINavigationBarDelegate

extension RegionsViewController: UINavigationBarDelegate {
    
}

