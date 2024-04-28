//
//  Annotation.swift
//  MapKitApp
//
//  Created by Евгений Бухарев on 02.02.2024.
//

import Foundation
import MapKit

class Annotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var color: UIColor?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String? = "NoWherem", color: UIColor?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.color = color
        super.init()
    }
}
