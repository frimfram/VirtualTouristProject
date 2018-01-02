//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/3/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!

    let PIN_REUSE_ID = "pinphotoview"
    let REMOVE_PICTURES = "Remove selected pictures"
    let NEW_COLLECTION = "New Collection"
    
    var selectedLocation: Location?
    var coreDataStack: CoreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // Insert, Delete, and Update index for the fetched results controller
    var insertIndexes = [IndexPath]()
    var deleteIndexes = [IndexPath]()
    var updateIndexes = [IndexPath]()

    var selectedIndexes = [IndexPath]()
    var totalPageNumber : Int = 1
    var currentPageNumber = 1
    var downloadCounter = 0
    
    lazy var fetchedResultsController: NSFetchedResultsController<Image> = {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Image")
        request.sortDescriptors = [NSSortDescriptor(key: "imageURL", ascending: true)]
        request.predicate = NSPredicate(format: "location == %@", self.selectedLocation!)
        let resultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<Image>, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        return resultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        fetchedResultsController.delegate = self
        initFlowLayout(size: view.frame.size)
        performFetch()
        initMap()
        initPhotoData()
        newCollectionButton.isEnabled = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        initFlowLayout(size: size)
    }
    
    @IBAction func onNewCollectionClicked(_ sender: UIButton) {
        if newCollectionButton.titleLabel?.text == NEW_COLLECTION {
            performNewCollection()
        } else {
            performDeleteSelected()
        }
    }
    
    func performNewCollection() {
        newCollectionButton.isEnabled = false
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            for object in fetchedObjects {
                coreDataStack.context.delete(object)
            }
            coreDataStack.save()
        }
        currentPageNumber = (currentPageNumber < totalPageNumber) ? (currentPageNumber + 1) : totalPageNumber
        collectionView.isHidden = false
        loadPhotosFromFlickr(currentPageNumber)
        downloadImages()
    }
    
    func performDeleteSelected() {
        for selected in selectedIndexes {
            coreDataStack.context.delete(fetchedResultsController.object(at: selected))
        }
        selectedIndexes.removeAll()
        coreDataStack.save()
        newCollectionButton.setTitle(NEW_COLLECTION, for: .normal)
    }
    
    func downloadImages() {
        coreDataStack.performBackgroundBatchOperation { (workerContext) in
            if let fetchedObjs = self.fetchedResultsController.fetchedObjects {
                for image in fetchedObjs {
                    if image.imageBinary == nil {
                        _ = FlickrClient.shared.downloadImage(imageURL: image.imageURL!) { (imageData, error) in
                            guard error == nil else {
                                return
                            }
                            guard let imageData = imageData else {
                                return
                            }
                            image.imageBinary = imageData as NSData
                        }
                    }
                }
            }
        }
    }

    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to perform fetch")
        }
    }
    
    func initFlowLayout(size: CGSize) {
        let space: CGFloat = 3.0
        let dimension: CGFloat = (size.width - (2*space)) / 3.0
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func initMap() {
        guard let selected = selectedLocation else {
            return
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = selected.latitude
        annotation.coordinate.longitude = selected.longitude
        let center = CLLocationCoordinate2D(latitude: selected.latitude, longitude: selected.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(annotation)
    }
    
    func initPhotoData() {
        if (fetchedResultsController.fetchedObjects?.count)! < 1 {
            loadPhotosFromFlickr(currentPageNumber)
        }
    }
    
    func loadPhotosFromFlickr(_ page: Int) {
        guard let selected = selectedLocation else {
            return
        }
        FlickrClient.shared.searchPhotos(selected.longitude, selected.latitude, page) { (result, pageNumber, error) in
            guard error == nil else {
                self.showAlert("Error fetch images from Flickr")
                return
            }
            guard let result = result else {
                self.showAlert("Error fetch images from Flickr")
                return
            }
            self.coreDataStack.context.perform {
                for url in result {
                    let image = Image(url: url, data: nil, context: self.coreDataStack.context)
                    self.selectedLocation?.addToImages(image)
                }
            }
            self.totalPageNumber = pageNumber!
        }
    }
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension PhotosViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = nil
        cell.activityView.startAnimating()
        let image = fetchedResultsController.object(at: indexPath)
        if let imageData = image.imageBinary {
            cell.imageView.image = UIImage(data: imageData as Data)
            cell.activityView.stopAnimating()
            if downloadCounter > 0 {
                downloadCounter -= 1
            }
            if downloadCounter == 0 {
                newCollectionButton.isEnabled = true
            }
        } else {
            downloadCounter += 1
            let task = FlickrClient.shared.downloadImage(imageURL: image.imageURL!) { (imageData, error) in
                guard error == nil else {
                    return
                }
                self.coreDataStack.context.perform {
                    image.imageBinary = imageData as NSData?
                }
                DispatchQueue.main.async {
                    cell.activityView.stopAnimating()
                }
            }
            cell.taskToCancelCellIsReused = task
        }
        return cell
    }
}

extension PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if !selectedIndexes.contains(indexPath) {
            selectedIndexes.append(indexPath)
            cell?.alpha = 0.5
        } else {
            selectedIndexes.remove(at: selectedIndexes.index(of: indexPath)!)
            cell?.alpha = 1
        }
        if selectedIndexes.count > 0 {
            newCollectionButton.setTitle(REMOVE_PICTURES, for:.normal)
        } else {
            newCollectionButton.setTitle(NEW_COLLECTION, for: .normal)
        }
    }
    
}

extension PhotosViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: PIN_REUSE_ID) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: PIN_REUSE_ID)
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .red
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
}

extension PhotosViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertIndexes.removeAll()
        deleteIndexes.removeAll()
        updateIndexes.removeAll()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertIndexes.append(newIndexPath)
            }
        case .delete:
            if let indexPath = indexPath {
                deleteIndexes.append(indexPath)
            }
        case .update:
            if let indexPath = indexPath {
                updateIndexes.append(indexPath)
            }
        default:
            break
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: insertIndexes)
            self.collectionView.deleteItems(at: deleteIndexes)
            self.collectionView.reloadItems(at: updateIndexes)
        }, completion: nil)
    }
}







