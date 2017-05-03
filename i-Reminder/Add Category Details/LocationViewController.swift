//
//  LocationViewController.swift
//  i-Reminder
//
//  Created by Qingzhou Wang on 3/09/2016.
//  Copyright © 2016 Qingzhou Wang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LocationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var searchController: UISearchController!
    
    let locationManager = CLLocationManager()
    var delegate: AddCategoryTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.dropPinByLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        // Add a gesture on mapview to detect is the map been dragged
        
//        if CLLocationManager.locationServicesEnabled()
//        {
//            searchRegionCenter = mapView.userLocation.coordinate
//        }
//        else
//        {
//            searchRegionCenter = CLLocationCoordinate2D(latitude: -37.81362, longitude: 144.96305)
//        }
        
        // Configure the search controller
        // Source https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
        let searchResultTable = storyboard!.instantiateViewControllerWithIdentifier("SearchResultTableViewController") as! SearchResultTableViewController
        searchController = UISearchController(searchResultsController: searchResultTable)
        searchController.searchResultsUpdater = searchResultTable
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search Location"
        navigationItem.titleView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        searchResultTable.mapView = mapView
        searchResultTable.handleMapSearchDelegate = self
        
        mapView.showsUserLocation = CLLocationManager.authorizationStatus() == .AuthorizedAlways || CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse
    }
    
    override func viewWillAppear(animated: Bool) {
        // If user is adding a new category, then set map region to current location. Otherwise set to category location.
        super.viewWillAppear(animated)
        let annotation = delegate?.annotation ?? nil
        if annotation != nil
        {
            mapView.addAnnotation(annotation!)
            mapView.setRegion(MKCoordinateRegionMakeWithDistance(annotation!.coordinate, 1500, 1500), animated: true)
        }
        else
        {
            if let location = locationManager.location
            {
                mapView.setRegion(MKCoordinateRegionMakeWithDistance(location.coordinate, 15000, 15000), animated: true)
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        delegate?.resignFirstResponder()
        delegate?.adjustContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
        mapView.showsUserLocation = status == .AuthorizedAlways || status == .AuthorizedWhenInUse
    }
    
    func dropPinZoomIn(placemark: MKPlacemark){
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name

        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        mapView.addAnnotation(annotation)
        mapView.setRegion(MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1500, 1500), animated: true)
        delegate?.annotation = annotation
        delegate?.chooseLocationCell.detailTextLabel?.text = annotation.title!
    }
    
    func dropPinByLongPress(gesture: UILongPressGestureRecognizer)
    {
        // Implement drop pin on the map by long press
        // Source http://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift
        if gesture.state == UIGestureRecognizerState.Began
        {
            mapView.removeAnnotations(mapView.annotations)
            let touchPoint = gesture.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: { (placemarks, error) in
                if error != nil
                {
                    print("Reverse geocoder failed with error" + error!.localizedDescription)
                    return
                }
                
                if placemarks?.count > 0
                {
                    let placemark = MKPlacemark(placemark: placemarks![0])
                    annotation.title = placemark.name
                    if let city = placemark.locality,
                        let state = placemark.administrativeArea {
                        annotation.subtitle = "\(city) \(state)"
                    }
                }
                else
                {
                    annotation.title = "Unknown Place"
                }
                self.mapView.addAnnotation(annotation)
                self.delegate?.annotation = annotation
                self.delegate?.chooseLocationCell.detailTextLabel?.text = annotation.title!
            })
        }
    }
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        // Show the map if current state is hidden
//        if mapView.hidden
//        {
//            UIView.animateWithDuration(0.25, animations: {
//                self.mapView.hidden = false
//                })
//        }
//        // Clear all current annotations and add selected address to map
//        mapView.removeAnnotations(mapView.annotations)
//        
//        let selectedPlacemark = matchingItems[indexPath.row].placemark
//        let annotation = MKPointAnnotation()
//        annotation.coordinate = selectedPlacemark.coordinate
//        annotation.title = selectedPlacemark.name
//        if let city = selectedPlacemark.locality,
//            let state = selectedPlacemark.administrativeArea {
//            annotation.subtitle = "\(city) \(state)"
//        }
//        
//        mapView.addAnnotation(annotation)
//        mapView.setRegion(MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000), animated: true)
//        searchBar.endEditing(true)
//        delegate?.annotation = annotation
//        delegate?.chooseLocationCell.detailTextLabel?.text = annotation.title!
//    }
    
//    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        resultAnnotationList.removeAll()
//        if searchText.characters.count == 0
//        {
//            mapView.hidden = true
//            tableView.reloadData()
//        }
//        else
//        {
//            let request = MKLocalSearchRequest()
//            request.naturalLanguageQuery = searchText
//            request.region = MKCoordinateRegionMakeWithDistance(searchRegionCenter, 5000000, 5000000)
//            let search = MKLocalSearch(request: request)
//            
//            search.startWithCompletionHandler { response, _ in
//                guard let response = response else {
//                    return
//                }
//                for item in response.mapItems
//                {
//                    let annotation = MKPointAnnotation()
//                    annotation.coordinate = item.placemark.coordinate
//                    annotation.title = item.placemark.name
//                    self.resultAnnotationList.append(annotation)
//                }
//                self.tableView.reloadData()
//            }
//        }
//    }
    
//    func updateSearchResultsForSearchController(searchController: UISearchController) {
//        guard let searchBarText = searchBar.text else { return }
//        
//        let request = MKLocalSearchRequest()
//        request.naturalLanguageQuery = searchBarText
//        request.region = MKCoordinateRegionMakeWithDistance(searchRegionCenter, 1000000, 1000000)
//        let search = MKLocalSearch(request: request)
//        
//        search.startWithCompletionHandler { response, _ in
//            guard let response = response else {
//                return
//            }
//            self.matchingItems = response.mapItems
//            self.tableView.reloadData()
//        }
//    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isEqual(mapView.userLocation)
        {
            // Do not change default annotation for user locaiton.
            return nil
        }
        else
        {
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            view.pinTintColor = delegate?.categoryColorCell.textLabel?.textColor
            view.enabled = true
            view.canShowCallout = true
            view.animatesDrop = true
            
            return view
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        // Select the annotation automatically after 0.5 seconds.
        performSelector(#selector(self.selectPin), withObject: nil, afterDelay: 0.5)
    }
    
    func selectPin()
    {
        for annotation in mapView.annotations
        {
            if !annotation.isEqual(mapView.userLocation)
            {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        searchRegionCenter = manager.location?.coordinate
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
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
