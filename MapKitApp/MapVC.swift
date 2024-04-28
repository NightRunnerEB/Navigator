//
//  ViewController.swift
//  MapKitApp
//  Created by Евгений Бухарев on 02.02.2024.
//
import UIKit
import CoreLocation
import MapKit

class MapVC: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate
{
    let locationManager = CLLocationManager()
    var coordinatesArray = [CLLocationCoordinate2D]()
    var annotationsArray = [MKAnnotation]()
    var overlaysArray = [MKOverlay]()
    
    let mapView: MKMapView = {
        let control = MKMapView()
        control.layer.cornerRadius = 15
        control.layer.masksToBounds = true
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.showsScale = true
        control.showsCompass = true
        control.showsTraffic = true
        control.showsBuildings = true
        control.showsUserLocation = true
        return control
    }()
    
    
    let startLocation: UITextField = {
        let control = UITextField()
        control.backgroundColor = UIColor.gray
        control.textColor = UIColor.white
        control.placeholder = "From"
        control.layer.cornerRadius = 2
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.font = UIFont.systemFont(ofSize: 15)
        control.borderStyle = UITextField.BorderStyle.roundedRect
        control.autocorrectionType = UITextAutocorrectionType.yes
        control.keyboardType = UIKeyboardType.default
        control.returnKeyType = UIReturnKeyType.go
        control.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return control
    }()
    
    
    let finishLocation: UITextField = {
        let control = UITextField()
        control.backgroundColor = UIColor.gray
        control.textColor = UIColor.white
        control.placeholder = "To"
        control.layer.cornerRadius = 2
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        control.font = UIFont.systemFont(ofSize: 15)
        control.borderStyle = UITextField.BorderStyle.roundedRect
        control.autocorrectionType = UITextAutocorrectionType.yes
        control.keyboardType = UIKeyboardType.default
        control.returnKeyType = UIReturnKeyType.go
        control.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        return control
    }()
    
    
    let goButton: UIButton = {
        let control = UIButton()
        control.addTarget(MapVC.self, action: #selector(getYourRoute), for: .touchUpInside)
        control.setTitle("Go!", for: .normal)
        control.backgroundColor = UIColor.blue
        control.titleLabel?.textColor = UIColor.white
        control.layer.cornerRadius = 4
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    let clearButton: UIButton = {
        let control = UIButton()
        control.addTarget(MapVC.self, action: #selector(clearAll), for: .touchUpInside)
        control.setTitle("Clear!", for: .normal)
        control.backgroundColor = UIColor.red
        control.titleLabel?.textColor = UIColor.black
        control.layer.cornerRadius = 4
        control.clipsToBounds = false
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    
    
    @objc
    func getYourRoute(_ sender: UIButton) {
        
        let completion1 = doAfterOne
        
        if self.mapView.annotations.count > 0 {
            self.mapView.removeAnnotations(self.annotationsArray)
            self.annotationsArray = []
        }
        
        if self.overlaysArray.count > 0 {
            self.mapView.removeOverlays(self.overlaysArray)
            self.overlaysArray = []
        }
        
        self.coordinatesArray = []
        
        if ( // self.startLocation.text!.count == 0 ||
            self.finishLocation.text!.count == 0 ||
            self.startLocation == self.finishLocation) {
            return
        }
        
        if self.startLocation.text!.count == 0 {
            guard let sourceCoordinate = locationManager.location?.coordinate else { return }
//            showCurrent(coordinates: sourceCoordinate, completion: completion1)
            self.coordinatesArray.append(sourceCoordinate)
            doAfterOne()
        } else {
            DispatchQueue.global(qos: .utility).async {
                self.findLocation(location: self.startLocation.text!, showRegion: false, completion: completion1)
            }
        }
        
    }
    
    
    private func findLocation(location: String, showRegion: Bool = false, completion: @escaping () -> Void ) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { (placemarks, error) in
            if let placemark = placemarks?.first {
                let coordinates = placemark.location!.coordinate
                self.coordinatesArray.append(coordinates)
                let point = Annotation(coordinate: coordinates, title: location, color: UIColor.purple)
                
                if let country = placemark.country {
                    point.subtitle = country
                }

                self.mapView.addAnnotation(point)
                self.annotationsArray.append(point)
                
                if showRegion {
                    self.mapView.centerCoordinate = coordinates
                    let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
                    let region = MKCoordinateRegion(center: coordinates, span: span)
                    self.mapView.setRegion(region, animated: showRegion)
                }
            } else {
                print(String(describing: error))
            }
            completion()
        }
    }
    
    
    private func showCurrent(coordinates: CLLocationCoordinate2D, showRegion: Bool = false, completion: @escaping () -> Void ) {
        
        self.coordinatesArray.append(coordinates)
        let point = MKPointAnnotation()
        point.coordinate = coordinates
        point.title = ""
        point.subtitle = ""

        self.mapView.addAnnotation(point)
        self.annotationsArray.append(point)
        
        if showRegion {
            self.mapView.centerCoordinate = coordinates
            let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
            let region = MKCoordinateRegion(center: coordinates, span: span)
            self.mapView.setRegion(region, animated: showRegion)
        }
        completion()
    }
    
    
    private func doAfterOne() {
        let completion2 = findLocations
        DispatchQueue.global(qos: .utility).async {
            self.findLocation(location: self.finishLocation.text!, showRegion: true, completion: completion2)
        }
    }
    
    
    private func findLocations() {
        if self.coordinatesArray.count < 2 {
            return
        }
        
        let markLocationOne = MKPlacemark(coordinate: self.coordinatesArray.first!)
        let markLocationTwo = MKPlacemark(coordinate: self.coordinatesArray.last!)
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: markLocationOne)
        directionRequest.destination = MKMapItem(placemark: markLocationTwo)
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            if error != nil {
                print(String(describing: error))
            } else {
                let myRoute: MKRoute? = response?.routes.first
                if let a = myRoute?.polyline {
                    if self.overlaysArray.count > 0 {
                        self.mapView.removeOverlays(self.overlaysArray)
                        self.overlaysArray = []
                    }
                    self.overlaysArray.append(a)
                    self.mapView.addOverlay(a)
                    
                    // Настройка отображения маршрута на карте
                    let rect = a.boundingMapRect
                    self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
                    
                    self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: true)
                }
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        startMap()
    }
    
    
    private func startMap() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation = locations[0] as CLLocation
        manager.stopUpdatingLocation()
        
        let location = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    
    private func setupUI() {
        startLocation.delegate = self
        finishLocation.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        
        self.view.addSubview(startLocation)
        self.view.addSubview(finishLocation)
        self.view.addSubview(goButton)
        self.view.addSubview(mapView)
        self.view.addSubview(clearButton)
        
        locationManager.startUpdatingLocation()
        setupToHideKeyboardOnTapOnView()
        
        goButton.pinRight(to: view)
        goButton.pinTop(to: view, 50)
        goButton.setHeight(78)
        goButton.setWidth(78)
        
        startLocation.pinLeft(to: view)
        startLocation.pinTop(to: view, 50)
        startLocation.pinRight(to: goButton, 88)
        startLocation.setHeight(34)
        
        finishLocation.pinLeft(to: view)
        finishLocation.pinTop(to: startLocation, 44)
        finishLocation.pinRight(to: goButton, 88)
        finishLocation.setHeight(34)
        
        clearButton.pinBottom(to: view, 20)
        clearButton.pinRight(to: view, 13)
        
        mapView.pinLeft(to: view)
        mapView.pinTop(to: finishLocation, 44)
        mapView.pinRight(to: view)
        mapView.pinBottom(to: view)
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.green
            polylineRenderer.lineWidth = 4
        }
        return polylineRenderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        var anView: MKAnnotationView?
        let reuseId: String

        if annotation is Annotation {
            reuseId = "custom_marker"
            anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            }
            anView?.image = UIImage(systemName: "house")
            anView?.canShowCallout = false

        }

        return anView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        UIView.animate(withDuration: 1.5, animations: {
            view.transform = CGAffineTransform(scaleX: 3, y: 3) // Увеличиваем объект в 3 раза
        })
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        UIView.animate(withDuration: 1.5, animations: {
            view.transform = .identity // Возвращаем объект к исходному размеру
        })
    }

    
    @objc
    func clearAll(_ sender: UIButton) {
        mapView.removeOverlays(overlaysArray)
        overlaysArray.removeAll()
        
        mapView.removeAnnotations(annotationsArray)
        annotationsArray.removeAll()
        
        startLocation.text = ""
        finishLocation.text = ""
        
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 3000, longitudinalMeters: 3000)
        mapView.setRegion(region, animated: true)

    }
}
