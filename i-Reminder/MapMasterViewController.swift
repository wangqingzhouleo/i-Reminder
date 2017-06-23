//
//  MapMasterViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 2/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MapMasterViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    let locationManager = CLLocationManager()
    var routePolylines = [MKPolyline]()
    let maxSpan = MKCoordinateSpanMake(0.005, 0.005)
    
//    var animatedOverlay: AnimatedOverlay?
    var animatedOverlayList = [AnimatedOverlay]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.mapView.delegate = self
        self.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // If location manager can get user's location, then set region to user location.
        if let location = locationManager.location
        {
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(location.coordinate, 15000, 15000), animated: true)
        }
        
        setFirstToolbarButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Set map shows user location based on location service setting.
        mapView.showsUserLocation = CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse
        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if CLLocationManager.locationServicesEnabled()
            {
                mapView.setRegion(MKCoordinateRegionMakeWithDistance(manager.location!.coordinate, 15000, 15000), animated: true)
            }
        default:
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func loadData()
    {
        removeAnimatedOverlay()
        
        mapView.removeAnnotations(mapView.annotations)
//        removeCircleRender()
        for category in tmpCategoryList
        {
            // For each category in the list, convert it to a custom pin then added it on the map.
            let annotation = CustomPin()
            annotation.pinColor = NSKeyedUnarchiver.unarchiveObject(with: category.color as Data) as! UIColor
            annotation.coordinate = CLLocationCoordinate2D(latitude: category.latitude as! Double, longitude: category.longitude as! Double)
            annotation.title = category.title
            annotation.subtitle = category.annotationTitle
            annotation.reminderList = category.reminderList.allObjects as! [Reminder]
            annotation.selectedIndex = IndexPath(row: category.index as! Int, section: 0)
            annotation.category = category
            mapView.addAnnotation(annotation)
            
            if category.remindRadius != nil
            {
                // This method is no longer userful since there's animated circle.
//                // Add a circle radius for each category pin on the map
//                let overlay = CustomCircle(centerCoordinate: annotation.coordinate, radius: category.remindRadius! as Double)
//                overlay.color = NSKeyedUnarchiver.unarchiveObjectWithData(category.color) as! UIColor
//                
//                mapView.addOverlay(overlay)
                
                
                // If user want to be notified for this category, then display animated circle for this annotation.
                addAnimationToAnnotation(annotation, forCategory: category)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation)
        {
            // If annotatio is user location, use default annotation.
            return nil
        }
        else
        {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            
            // Set pin color to category color.
            view.pinTintColor = (annotation as! CustomPin).pinColor
            view.isEnabled = true
            view.canShowCallout = true
            view.animatesDrop = true
            
            // Right button is detail disclosure, tells user this call out can show more information on click.
            let rightButton = UIButton(type: .detailDisclosure)
            rightButton.tintColor = UIColor(red: 0.0392, green: 0.8078, blue: 0.1647, alpha: 1)
            let leftButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            leftButton.setTitle(nil, for: .selected)
            
            // Set left button's image on call out accessory to a car image, user can have more options by clicking this button.
            leftButton.setImage(UIImage(named: "get direction"), for: UIControlState())
            leftButton.imageView?.tintColor = UIColor(red: 0.0392, green: 0.8078, blue: 0.1647, alpha: 1)
            
            view.rightCalloutAccessoryView = rightButton
            view.leftCalloutAccessoryView = leftButton
            
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // When any pin is tapped, show an alert which contains some information about that branch with further options: Get direction or Call
        if control == view.rightCalloutAccessoryView
        {
            if let pin = view.annotation as? CustomPin
            {
                if let navigationVC = storyboard?.instantiateViewController(withIdentifier: "categoryDetailNavigation") as? UINavigationController
                {
                    let detailVC = navigationVC.topViewController as! CategoryDetailTableViewController
                    let category = pin.category
                    detailVC.currentList = loadCurrentReminderList(inCategory: category!)
                    detailVC.masterButtonColor = NSKeyedUnarchiver.unarchiveObject(with: category!.color) as? UIColor
                    detailVC.selectedCategoryIndexPath = pin.selectedIndex
                    navigationController?.showDetailViewController(navigationVC, sender: self)
                }
            }
        }
        else if control == view.leftCalloutAccessoryView
        {
            // User has 3 options for direction: Display direction on current map, open direction in Google Maps (if use installed Google Maps on the phone) or open direction in Apple Maps.
            if let pin = view.annotation as? CustomPin
            {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "Show Route", style: .default, handler: {
                    (alert: UIAlertAction) in self.showRoute(pin)
                }))
                if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
                {
                    alert.addAction(UIAlertAction(title: "Navigate by Google Maps", style: .default, handler: {
                        (alert: UIAlertAction) in self.openGoogleMap(pin)
                    }))
                }
                alert.addAction(UIAlertAction(title: "Navigate by Apple Maps", style: .default, handler: {
                    (alert: UIAlertAction) in self.openAppleMap(pin)
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func setFirstToolbarButton()
    {
        // Create a button at left of the toolbar, indicate whether the map's center is user's current location
        let button = MKUserTrackingBarButtonItem(mapView: mapView)
        button.target = self
        toolBar.items?.append(button)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolBar.items?.append(flexibleSpace)
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways && CLLocationManager.authorizationStatus() != .authorizedWhenInUse
        {
            // If location service is off, tell user the message and method to open it.
            let alert = UIAlertController(title: "Location Services Off", message: "Turn on Location Services in Settings > Privacy to allow i-Reminder to determine your current location", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKPolyline.self)
        {
            // If the overlay is may route, set it to blue color
            let render = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            render.strokeColor = UIColor(red: 0.3490, green: 0.6471, blue: 0.9647, alpha: 1)
            return render
        }
//        else
//        {
//            // If overlay is circle, set color to category color
//            let circle = overlay as! CustomCircle
//            let render = MKCircleRenderer(overlay: overlay)
//            render.lineWidth = 2
//            render.strokeColor = circle.color.colorWithAlphaComponent(0.4)
//            render.fillColor = circle.color.colorWithAlphaComponent(0.15)
//            
//            return render
//        }
        
        return MKOverlayRenderer()
    }
    
    func clearRoute()
    {
        // Remove all overlays on the map in order to clear the route
        mapView.removeOverlays(routePolylines)
        routePolylines.removeAll()
        if toolBar.items?.count > 2
        {
            toolBar.items?.removeLast()
        }
    }
    
    func showRoute(_ pin: CustomPin)
    {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
        {
            // Clear previous route first.
            clearRoute()
            // Then ask directions request for a particular direction for current location and destination place.
            let request = MKDirectionsRequest()
            request.source = MKMapItem.forCurrentLocation()
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate, addressDictionary: nil))
            request.requestsAlternateRoutes = false
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            // Then ask MKDirections to calculate directions.
            directions.calculate(completionHandler: { (response: MKDirectionsResponse?, error: NSError?) in
                guard response != nil else {return}
                
                for route in response!.routes
                {
                    self.mapView.add(route.polyline, level: .aboveRoads)
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(120, 100, 120, 100), animated: true)
                    self.routePolylines.append(route.polyline)
                }
                
                // Add a cancen button at the right side of the toolbar. When the button is pressed, cancel the route.
                let cancelButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(self.clearRoute))
                self.toolBar.items?.append(cancelButton)
            } as! MKDirectionsHandler)
        }
        else
        {
            // Display message to tell user location service is off, so cannot display directions on the map.
            let alert = UIAlertController(title: "Location Services Off", message: "Turn on Location Services in Settings > Privacy to allow Working Rights to determine your current location", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func openGoogleMap(_ pin: CustomPin)
    {
        // Open Google Maps to display route
        let url = URL(string: "comgooglemaps://?daddr=\(pin.coordinate.latitude),\(pin.coordinate.longitude)&directionsmode=driving")!
        UIApplication.shared.openURL(url)
    }
    
    func openAppleMap(_ pin: CustomPin)
    {
        // Open Apple Maps to display route
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: pin.coordinate, addressDictionary: nil))
        mapItem.name = pin.subtitle
        let launchOptions: NSDictionary = NSDictionary(object: MKLaunchOptionsDirectionsModeDriving, forKey: MKLaunchOptionsDirectionsModeKey as NSCopying)
        
        MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), mapItem], launchOptions: launchOptions as? [String : AnyObject])
    }
    
    
    // Add animation to the annotations
    // Source from http://yickhong-ios.blogspot.com.au/2012/04/animated-circle-on-mkmapview.html
    func addAnimationToAnnotation(_ annotation: CustomPin, forCategory category: Category)
    {
        if let radius = category.remindRadius as? Double, category.remindRadius != nil
        {
            let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, radius, radius)
            let rect = mapView.convertRegion(region, toRectTo: mapView)
            
            let animatedOverlay = AnimatedOverlay(frame: rect)
            mapView.addSubview(animatedOverlay)
            
            let color = NSKeyedUnarchiver.unarchiveObject(with: category.color as Data) as! UIColor
            animatedOverlay.startAnimatingWithColor(color, andFrame: rect)
            animatedOverlayList.append(animatedOverlay)
        }
    }
    
    func removeAnimatedOverlay()
    {
        if animatedOverlayList.count > 0
        {
            for item in animatedOverlayList
            {
                item.stopAnimating()
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Remove all overlays when map started drag
        removeAnimatedOverlay()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Re-add animations when region stop change
        for item in mapView.annotations
        {
            if !item.isEqual(mapView.userLocation)
            {
                addAnimationToAnnotation(item as! CustomPin, forCategory: (item as! CustomPin).category)
            }
        }
        
        if mapView.region.span.latitudeDelta < maxSpan.latitudeDelta && mapView.region.span.longitudeDelta < maxSpan.longitudeDelta
        {
            mapView.setRegion(MKCoordinateRegion(center: mapView.region.center, span: maxSpan), animated: true)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
