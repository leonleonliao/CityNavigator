//
//  AnnotatedItem.swift
//  Coursework
//
//  Created by Leon Liao on 19/1/2025.
//

import MapKit
import Foundation

struct AnnotatedItem : Identifiable {
    let id = UUID()
    var name : String
    var description: String
    var imageName: String
    var coordinate : CLLocationCoordinate2D
}
