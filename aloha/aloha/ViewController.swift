//
//  ViewController.swift
//  aloha
//
//  Created by Michelle Staton on 2/11/17.
//  Copyright © 2017 Michelle Staton. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class ViewController: UIViewController {
    
    var mapView = MKMapView()
    
    var messages: [Message] = []
    var locationManager = CLLocationManager()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        AlohaAPIClient.getAPIData { (response) in
            print("called api")
        }
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        loadAllMessages()
    }
    
    // MARK: Loading and saving functions
    func loadAllMessages() {
        messages = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        for savedItem in savedItems {
            guard let message = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Message else { continue }
            add(message: message)
        }
    }
    
    func saveAllMessages() {
        var items: [Data] = []
        for message in messages {
            let item = NSKeyedArchiver.archivedData(withRootObject: message)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    // MARK: Functions that update the model/associated views with messages changes
    func add(message: Message) {
        messages.append(message)
        mapView.addAnnotation(message as MKAnnotation)
        addRadiusOverlay(forMessage: message)
        updateMessagesCount()
    }
    
    func remove(message: Message) {
        if let indexInArray = messages.index(of: message) {
            messages.remove(at: indexInArray)
        }
        mapView.removeAnnotation(message as MKAnnotation)
        removeRadiusOverlay(forMessage: message)
        updateMessagesCount()
    }
    
    func updateMessagesCount() {
        title = "Messages (\(messages.count))"
        navigationItem.rightBarButtonItem?.isEnabled = (messages.count < 20)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forMessage message: Message) {
        mapView.add(MKCircle(center: message.coordinate, radius: message.radius))
    }
    
    func removeRadiusOverlay(forMessage message: Message) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        let overlays = mapView.overlays
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == message.coordinate.latitude && coord.longitude == message.coordinate.longitude && circleOverlay.radius == message.radius {
                mapView.remove(circleOverlay)
                break
            }
        }
    }
    
    // MARK: Other mapview functions
    func zoomToCurrentLocation(sender: AnyObject) {
        mapView.zoomToUserLocation()
    }
    
    func region(withMessage message: Message) -> CLCircularRegion {

        let region = CLCircularRegion(center: message.coordinate, radius: message.radius, identifier: message.identifier)

        region.notifyOnEntry = (message.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(message: Message) {

        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }

        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle:"Warning", message: "Your message is saved but will only be activated once you grant Aloha permission to access the device location.")
        }

        let region = self.region(withMessage: message)

        locationManager.startMonitoring(for: region)
    }
    
    func stopMonitoring(message: Message) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == message.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
}


// MARK: - Location Manager Delegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = status == .authorizedAlways
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
    
}

// MARK: - MapView Delegate
extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeotification"
        if annotation is Message {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteMessage")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = .purple
            circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        let message = view.annotation as! Message
        remove(message: message)
        saveAllMessages()
    }
    
}

// MARK: Helper Extensions
extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 10000, 10000)
        setRegion(region, animated: true)
    }
}

