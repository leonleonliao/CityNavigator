//
//  AnnotatedItem.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import MapKit
import Foundation

import CoreLocation

struct AnnotatedItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var imageName: String
    var coordinate: CLLocationCoordinate2D
    

    init(id: UUID = UUID(), name: String, description: String, imageName: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.name = name
        self.description = description
        self.imageName = imageName
        self.coordinate = coordinate
    }

    // 手動實現 Hashable 協議
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(imageName)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }

    // 自定義相等檢查（必須與 hash(into:) 保持一致）
    static func == (lhs: AnnotatedItem, rhs: AnnotatedItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.description == rhs.description &&
               lhs.imageName == rhs.imageName &&
               lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    // 自定義編碼和解碼，因為 CLLocationCoordinate2D 不支持直接編碼
    enum CodingKeys: String, CodingKey {
        case id, name, description, imageName, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        imageName = try container.decode(String.self, forKey: .imageName)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
