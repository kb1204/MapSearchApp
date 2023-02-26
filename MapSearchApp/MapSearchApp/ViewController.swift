import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore

class ViewController: UIViewController {
    
    
    private let mapView = MKMapView()
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private let locationManager = CLLocationManager()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
        
        mapView.delegate = self
        
        setupSearchController()
        
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
        
        setupLocationManager()
        
        setupMapView()
        
    }
    
    
    private func setupSearchController() {
        
        searchController.searchResultsUpdater = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = "Search for Places"
        
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.tintColor = .black // カーソルの色を黒に設定
        
        searchController.searchBar.backgroundColor = UIColor.white
        
        navigationItem.searchController = searchController
        
        definesPresentationContext = true // 必要な定数を設定
        
    }
    
    
    private func setupLocationManager() {
        
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.delegate = self
            
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            
            locationManager.startUpdatingLocation()
            
        }
        
    }
    
    
    private func setupMapView() {
        
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            
        ])
        
    }
    
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else {
            return nil
        }
        
        let identifier = "Annotation"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView?.canShowCallout = true
            
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        } else {
            
            annotationView?.annotation = annotation
            
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let annotation = view.annotation else {
            
            return
            
        }
        
        let alertController = UIAlertController(title: "Add Location?", message: "Do you want to add this location to Firebase?", preferredStyle: .alert)
        
        let addAction = UIAlertAction(title: "OK", style: .default) { [weak self] (_) in
            
            guard let self = self else {
                
                return
                
            }
            
            let db = Firestore.firestore()
            
            let documentID = annotation.title as! String
            
            let docRef = db.collection("mapData").document(documentID)
            
            let data: [String: Any] = ["address": annotation.title as Any, "latitude": annotation.coordinate.latitude, "longitude": annotation.coordinate.longitude]
            
            docRef.setData(data) { (error) in
                
                if let error = error {
                    
                    print("Error adding document: \(error.localizedDescription)")
                    
                } else {
                    
                    print("Documet added with ID: \(docRef.documentID)")
                    
                }
                
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(addAction)
        
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
}


extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            
            return
            
        }
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
}


extension ViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let query = searchController.searchBar.text, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            
            return
        }
        
        let request = MKLocalSearch.Request()
        
        request.naturalLanguageQuery = query
        
        if let location = locationManager.location {
            
            request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            
        }
        
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] (response,error) in
            
            
            guard let self = self else {
                
                return
                
            }
            
            guard let response = response else {
                
                return
                
            }
            
            let annotations = self.mapView.annotations
            
            self.mapView.removeAnnotations(annotations)
            
            for item in response.mapItems {
                
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = item.placemark.coordinate
                
                annotation.title = item.name
                
                annotation.subtitle = item.placemark.title
                
                self.mapView.addAnnotation(annotation)
                
            }
            
            if let firstAnnotation = self.mapView.annotations.first {
                
                let region = MKCoordinateRegion(center: firstAnnotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
                
                self.mapView.setRegion(region, animated: true)
                
            }
            
        }
        
    }
    
}

