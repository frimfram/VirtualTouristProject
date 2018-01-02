//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jean Ro on 11/26/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var coreDataStack: CoreDataStack?
    
    let APP_TITLE = "Virtual Tourist"
    let OK_TITLE = "OK"
    let EDIT_BUTTON_TITLE = "Edit"
    let DONE_BUTTON_TITLE = "Done"
    let LATITUDE = "Latitude"
    let LONGITUDE = "Longitude"
    let LATITUDE_DELTA = "LatitudeDelta"
    let LONGITUDE_DELTA = "LongitudeDelta"
    let MAP_ANNOTATION_REUSE_ID = "pin"
    var idEditing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
        mapView.delegate = self
        initialize()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = APP_TITLE
    }
    @IBAction func onLongPressed(_ sender: UILongPressGestureRecognizer) {
        let pressedPoint = sender.location(in: mapView)
        let pressedCoordinate = mapView.convert(pressedPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = pressedCoordinate
        var isFound = false
        for existingAnnotation in mapView.annotations {
            if existingAnnotation.coordinate.latitude == pressedCoordinate.latitude && existingAnnotation.coordinate.longitude == pressedCoordinate.longitude {
                isFound = true
                break
            }
        }
        if !isFound {
            mapView.addAnnotation(annotation)
            let newLoc = Location(longitude: pressedCoordinate.longitude, latitude: pressedCoordinate.latitude, context: (coreDataStack?.context)!)
            loadPhotosFromFlickr(1, newLoc)
        }
    }
    
    @IBAction func onEdit(_ sender: UIBarButtonItem) {
        if editButton.title == EDIT_BUTTON_TITLE {
            deleteLabel.isHidden = false
            editButton.title = DONE_BUTTON_TITLE
            isEditing = true
        } else {
            deleteLabel.isHidden = true
            editButton.title = EDIT_BUTTON_TITLE
            isEditing = false
        }
    }
    
    private func initialize() {
        deleteLabel.isHidden = true
        if let lat = UserDefaults.standard.object(forKey: LATITUDE) {
            let latitude = lat as! Double
            let longitude = UserDefaults.standard.double(forKey: LONGITUDE)
            let latitudeDelta = UserDefaults.standard.double(forKey: LATITUDE_DELTA)
            let longitudeDelta = UserDefaults.standard.double(forKey: LONGITUDE_DELTA)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        loadSavedLocations()
    }
    
    private func loadSavedLocations() {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        if let result = try? coreDataStack?.context.fetch(request) {
            var locationAnnotations = [MKPointAnnotation]()
            for location in result! {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = location.latitude
                annotation.coordinate.longitude = location.longitude
                locationAnnotations.append(annotation)
            }
            mapView.addAnnotations(locationAnnotations)
        }
    }
    
    private func loadPhotosFromFlickr(_ page: Int, _ location: Location) {
        FlickrClient.shared.searchPhotos(location.longitude, location.latitude, page) { (result, pageNumber, error) in
            guard error == nil else {
                return
            }
            guard let result = result else {
                return
            }
            for url in result {
                self.coreDataStack?.context.perform {
                    let image = Image(url: url, data: nil, context: (self.coreDataStack?.context)!)
                    location.totalFlickrPages = Int32(pageNumber!)
                    location.addToImages(image)
                }
            }
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: MAP_ANNOTATION_REUSE_ID) as? MKPinAnnotationView {
            pinView.annotation = annotation
            return pinView
        }
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: MAP_ANNOTATION_REUSE_ID)
        pinView.canShowCallout = false
        pinView.pinTintColor = .red
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: LATITUDE)
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: LONGITUDE)
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: LATITUDE_DELTA)
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: LONGITUDE_DELTA)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        let selectedCoord: CLLocationCoordinate2D = annotation.coordinate
        if let location = loadSavedLocation(latitude: selectedCoord.latitude, longitude: selectedCoord.longitude) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                coreDataStack?.context.delete(location)
                coreDataStack?.save()
            } else {
                let vc:PhotosViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotosViewController
                vc.selectedLocation = location
                vc.totalPageNumber = location.value(forKey: "totalFlickrPages") as! Int
                navigationItem.title = OK_TITLE
                navigationController?.pushViewController(vc, animated: true)
            }
            
        }
    }
    
    private func loadSavedLocation(latitude: Double, longitude: Double) -> Location? {
        let request: NSFetchRequest<Location> = Location.fetchRequest()
        if let fetchResults = try? coreDataStack?.context.fetch(request) {
            for result in fetchResults! {
                if result.latitude == latitude && result.longitude == longitude {
                    return result
                }
            }
        }
        return nil
    }
    
}












