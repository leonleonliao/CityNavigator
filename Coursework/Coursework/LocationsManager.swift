//
//  LocationsManager.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import Foundation
import CoreLocation

class LocationsManager: ObservableObject {
    @Published var savedLocations: [AnnotatedItem] = [] // 保存的地點列表
    private let staticLocations: [AnnotatedItem] // 靜態地點列表
    private var userDefaultsKey: String = ""// 當前用戶的唯一鍵

    init(username: String) {
        self.userDefaultsKey = "locations_\(username)"
        // 初始化靜態地點（所有用戶共享）
        self.staticLocations = [
            AnnotatedItem(name: "IVE(ST)", description: "A vocational education institution.", imageName: "building.2", coordinate: .init(latitude: 22.39002, longitude: 114.19834)),
            AnnotatedItem(name: "Ocean Park", description: "A marine mammal park, oceanarium, and amusement park.", imageName: "tortoise", coordinate: .init(latitude: 22.24825, longitude: 114.17566)),
            AnnotatedItem(name: "The Peak", description: "A famous tourist attraction with panoramic views.", imageName: "mountain.2", coordinate: .init(latitude: 22.27723, longitude: 114.14519)),
            AnnotatedItem(name: "Hong Kong Disneyland", description: "A magical theme park with Disney characters.", imageName: "sparkles", coordinate: .init(latitude: 22.31296, longitude: 114.04123))
        ]
    }
    
    // 用戶登錄後同步數據
    func syncWithAccount(username: String) {
        self.userDefaultsKey = "locations_\(username)"
        loadSavedLocations() // 加載用戶保存的地點
        mergeStaticLocations() // 合併靜態地點
    }

    // 登出操作：清除當前用戶的地點
    func logout() {
        savedLocations = [] // 清空當前地點列表
        userDefaultsKey = "" // 清空用戶鍵
    }

    // 合併靜態地點：僅在保存的地點列表中不存在時才添加
    private func mergeStaticLocations() {
        for location in staticLocations {
            if !savedLocations.contains(where: { $0.name == location.name && $0.coordinate.latitude == location.coordinate.latitude && $0.coordinate.longitude == location.coordinate.longitude }) {
                savedLocations.append(location)
            }
        }
    }
    
    // 添加新地點
    func addLocation(_ location: AnnotatedItem) {
        // 避免重複添加
        guard !savedLocations.contains(where: {
            $0.name == location.name &&
            $0.coordinate.latitude == location.coordinate.latitude &&
            $0.coordinate.longitude == location.coordinate.longitude
        }) else { return }
            
        savedLocations.append(location)
        saveLocationsToUserDefaults()
    }

    // 刪除地點
    func removeLocation(_ location: AnnotatedItem) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            savedLocations.remove(at: index)
            saveLocationsToUserDefaults()
        }
        //savedLocations.removeAll { $0.id == location.id }
    }
    
    // 更新地點
    func updateLocation(_ updatedLocation: AnnotatedItem) {
        if let index = savedLocations.firstIndex(where: { $0.id == updatedLocation.id }) {
            savedLocations[index] = updatedLocation
            saveLocationsToUserDefaults()
        }
    }
    
    // 從 UserDefaults 加載保存的地點
    private func loadSavedLocations() {
        guard !userDefaultsKey.isEmpty else { return } // 如果沒有用戶，則不加載
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let locations = try? JSONDecoder().decode([AnnotatedItem].self, from: data) {
            savedLocations = locations
        }
    }

    // 保存地點到 UserDefaults
    private func saveLocationsToUserDefaults() {
        guard !userDefaultsKey.isEmpty else { return } // 如果沒有用戶，則不保存
        if let data = try? JSONEncoder().encode(savedLocations.filter { !staticLocations.contains($0) }) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
