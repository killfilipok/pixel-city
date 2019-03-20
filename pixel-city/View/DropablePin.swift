//
//  DropablePin.swift
//  pixel-city
//
//  Created by Philip on 3/19/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import UIKit
import MapKit


class DroppablePin: NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D
    var identifire: String
    
    init(coordinate: CLLocationCoordinate2D, identifire: String){
        self.coordinate = coordinate
        self.identifire = identifire
        super.init()
    }
}
