//
//  LocationsView.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Combine

//通過這個擴展，CLLocationCoordinate2D 就符合 Equatable，並且可以用於 onChange 方法
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        let epsilon = 0.000001 // 精度範圍
        return abs(lhs.latitude - rhs.latitude) < epsilon && abs(lhs.longitude - rhs.longitude) < epsilon
    }
}

// 為了支持當前位置的功能，用於獲取並更新設備的當前位置
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var userHeading: CLLocationDirection? // 用戶朝向
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading() // 開始追踪用戶朝向
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //currentLocation = locations.last?.coordinate
        if let location = locations.last {
              print("Current Location：\(location.coordinate.latitude), \(location.coordinate.longitude)")
              currentLocation = location.coordinate
          }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading.trueHeading // 更新用戶朝向
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Failed to find user's location: \(error.localizedDescription)")
        }
}

/// 主視圖
struct LocationsView: View {
    @EnvironmentObject var locationsManager: LocationsManager // 獲取共享的數據模型
    @State private var username: String = "" // 當前用戶名
    @State private var isLoggedIn: Bool = false // 用戶是否登錄
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.37464, longitude: 114.14907),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @State private var nameStr: String = "New Point"
    @State private var latStr: String = ""
    @State private var lngStr: String = ""
    
    var onAddLocation: ((AnnotatedItem) -> Void)? // 新增閉包，用於通知外部添加地點
    
    // 用於選中標記的狀態
    @State private var selectedAnnotation: AnnotatedItem? = nil
    @State private var showDeleteConfirmation = false
    @State private var showDetailsSheet = false
    @State private var showEditSheet = false
    @State private var selectedIndex: Int? = nil // 儲存選中的地點索引
    @StateObject private var locationManager = LocationManager()
    @State private var showRoute = false
    @State private var routeOverlay: MKPolyline? = nil
    //使用 Combine 監聽用戶位置的變化，確保在 LocationsView 中添加 Combine 的訂閱屬性
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isNavigating = false // 是否正在導航
    @State private var isCalculatingRoute = false //跟踪是否正在計算路徑
    
    
    
    var body: some View {
        VStack {
            
            // 輸入框和按鈕，用於新增標記
            InputFields(
                nameStr: $nameStr,
                latStr: $latStr,
                lngStr: $lngStr,
                onAdd: addAnnotationFromInput
            )
            // 地圖
            ZStack {
                // 自定義 MapViewWrapper，用於處理點擊事件和標記操作
                MapViewWrapper(region: $region, savedLocations: locationsManager.savedLocations, nameStr: $nameStr, latStr: $latStr, lngStr: $lngStr, selectedAnnotation: $selectedAnnotation, showDeleteConfirmation: $showDeleteConfirmation, showEditSheet: $showEditSheet, locationManager: locationManager, routeOverlay: $routeOverlay, isNavigating: $isNavigating
                )
           
                // 放大與縮小按鈕
                VStack {
                    Spacer()// 將按鈕置於底部
                    HStack {
                        //Spacer()// 將按鈕置於右側
                        VStack(spacing: 10) {
                            //在卡片選擇後，顯示導航按鈕：
                            if !isNavigating, let index = selectedIndex {
                                Button("Navigate to \(locationsManager.savedLocations[index].name)") {
                                    startNavigation(to: locationsManager.savedLocations[index].coordinate)
                                }
                                //.padding()
                                .buttonStyle(.borderedProminent)
                                // 測試按鈕
                                Button("Edit") {
                                    selectedAnnotation = locationsManager.savedLocations.first // 任意選擇一個標記
                                    showDeleteConfirmation = true // 設置為 true 手動觸發 .alert()
                                }
                                .buttonStyle(.borderedProminent)
                                //.padding()
                            }
                            if isNavigating {
                                Button("Stop Navigation") {
                                    stopNavigation()
                                }
                                .padding()
                                .buttonStyle(.borderedProminent)
                                .foregroundColor(.red) // 使用紅色顯示停止導航的按鈕
                            }
                        }
                        .padding()
                    }
                }
            }
            .alert("Delete Annotation", isPresented: $showDeleteConfirmation, actions: {
                Button("View Details") {
                    showDetailsSheet = true
                }
                Button("Edit") {
                        showEditSheet = true
                    }
                Button("Cancel", role: .cancel, action: {})
                Button("Delete", role: .destructive, action: {
                    if let selectedAnnotation = selectedAnnotation {
                        removeAnnotation(selectedAnnotation)
                    }
                })
            }, message: {
                Text("Are you sure you want to delete the selected annotation?")
            })
            .sheet(isPresented: $showDetailsSheet) {
                if let annotation = selectedAnnotation {
                    VStack {
                        Text("Annotation Details")
                            .font(.headline)
                        Text("Name: \(annotation.name)")
                        Text("Latitude: \(annotation.coordinate.latitude)")
                        Text("Longitude: \(annotation.coordinate.longitude)")
                        Button("Close") {
                            showDetailsSheet = false
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let selectedAnnotationIndex = locationsManager.savedLocations.firstIndex(where: { $0.id == selectedAnnotation?.id }) {
                    EditAnnotationView(
                        annotation: $locationsManager.savedLocations[selectedAnnotationIndex],
                        onSave: {
                            showEditSheet = false
                        },
                        onCancel: {
                            showEditSheet = false
                        }
                    )
                }
            }

            // 橫向標記列表
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {// 將間距設置為 0，確保單次只顯示一個卡片
                        ForEach(locationsManager.savedLocations.indices, id: \.self) { index in
                            VStack {
                                Image(systemName: locationsManager.savedLocations[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .padding(.bottom, 10)
                                Text(locationsManager.savedLocations[index].name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 5)
                                Text(locationsManager.savedLocations[index].description)
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.6, height: 150)// 卡片寬度占屏幕 80%
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.blue.opacity(index == selectedIndex ? 0.9 : 0.6))
                            )
                            .scaleEffect(index == selectedIndex ? 1.1 : 1.0) //選中卡片放大效果
                            .onTapGesture {
                                selectedIndex = index // 更新选中的卡片索引
                                selectedAnnotation = locationsManager.savedLocations[index] // 更新選中的標記
                                focusOnAnnotation(locationsManager.savedLocations[index]) // 更新地图位置,聚焦到選中的地點
                            }
                            .animation(.spring(), value: selectedIndex)
                            .id(index)// 設置唯一 ID
                        }
                    }
                    .padding(.horizontal)

                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                handleCardSwipe(value: value, proxy: proxy)
                            }
                    )
                    .background(Color(.systemGray6))
                }
            }
        }
        

    }
    
    /// 根據輸入框中的值添加標記
    private func addAnnotationFromInput() {
        guard let lat = Double(latStr), let lng = Double(lngStr) else {
            print("Invalid latitude or longitude")
            return
        }

        let newAnnotation = AnnotatedItem(
            name: nameStr,
            description: "Default description",  // 添加默認描述
            imageName: "default.image",          // 添加默認圖片名稱
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
        )

        locationsManager.addLocation(newAnnotation)  // 將新地點添加到共享數據模型
        // 清空輸入框
        nameStr = "New Point"
        latStr = ""
        lngStr = ""
    }
  
    /// 處理卡片滑動
    private func handleCardSwipe(value: DragGesture.Value, proxy: ScrollViewProxy) {
        if value.translation.width < -50 && (selectedIndex ?? 0) < locationsManager.savedLocations.count - 1 {
            selectedIndex = (selectedIndex ?? 0) + 1
        } else if value.translation.width > 50 && (selectedIndex ?? 0) > 0 {
            selectedIndex = (selectedIndex ?? 0) - 1
        }
        // 滾動到所選的卡片
        withAnimation {
            if let selectedIndex = selectedIndex {
                proxy.scrollTo(selectedIndex, anchor: .center)
                focusOnAnnotation(locationsManager.savedLocations[selectedIndex])
            }
        }
    }

    /// 聚焦到指定標記
    private func focusOnAnnotation(_ annotation: AnnotatedItem) {
        selectedAnnotation = annotation // 更新選中的標記
         
        // 將地圖的 region 聚焦到目標地點
            let adjustedCenter = annotation.coordinate
            let adjustedSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        DispatchQueue.main.async {
            region = MKCoordinateRegion(
                center: adjustedCenter,
                //center: annotation.coordinate,
                span: adjustedSpan) // 放大地图
        }
    }
    
    //繪製路線 draw Route
    private func drawRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        guard !isCalculatingRoute else {
            print("Route calculation already in progress, skipping...")
            return
        }
        isCalculatingRoute = true // 設置為正在計算路徑
        print("Drawing route from (\(start.latitude), \(start.longitude)) to (\(destination.latitude), \(destination.longitude))")
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile // 設置交通方式為駕車
            
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                self.isCalculatingRoute = false // 路徑計算結束，重置標誌
            }
            
            if let error = error {
                print("Failed to calculate route: \(error.localizedDescription)")
                return
            }
            guard let route = response?.routes.first else {
                print("Failed to calculate route: \(error?.localizedDescription ?? "Unknown error")")
                    return
            }
            print("Route calculated successfully: Distance = \(route.distance) meters")
            DispatchQueue.main.async {
                
                // 清理舊路徑後添加新路徑
                if self.routeOverlay != nil {
                    print("Removing old route overlay...")
                    self.routeOverlay = nil // 清理舊覆蓋物
                }
                
                // 添加新路線，更新路徑
                self.routeOverlay = route.polyline
                self.showRoute = true
            }
        }
    }
    
    //開始導航 Start Navigation
    private func startNavigation(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = locationManager.currentLocation else { return }
        
        stopNavigation() // 確保舊導航被清理
        isNavigating = true
        drawRoute(from: currentLocation, to: destination)
        // 持續更新用戶位置
        locationManager.$currentLocation
            .receive(on: RunLoop.main)
            .sink {  newLocation in
                guard newLocation != nil else { return }
            }
            .store(in: &cancellables) // 使用 Combine 來管理訂閱
    }
    
    //更新導航路徑和地圖顯示區域
    private func updateNavigationPath(from userLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        // 動態繪製用戶當前位置到目的地的剩餘路徑
        drawRoute(from: userLocation, to: destination)

        // 更新地圖中心位置
        DispatchQueue.main.async {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01) // 顯示範圍
            )
        }
    }
    
    //當用戶選擇停止導航時，需要清理地圖上的路徑並退出導航模式
    private func stopNavigation() {
        isNavigating = false // 停止導航
        routeOverlay = nil   // 清理地圖上的路徑
        
        // 手動觸發地圖更新，確保清理路徑
        DispatchQueue.main.async {
            showRoute = false
        }
    }
    
    /// 放大地圖
    private func zoomIn() {
        region.span.latitudeDelta /= 2
        region.span.longitudeDelta /= 2
    }
       
    /// 縮小地圖
    private func zoomOut() {
        region.span.latitudeDelta = min(region.span.latitudeDelta * 2, 180) // 避免超出地圖緯度範圍
        region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 360) // 避免超出地圖經度範圍
    }
    

    /// 根據標記 id 刪除標記
    private func removeAnnotation(_ annotation: AnnotatedItem) {
            locationsManager.removeLocation(annotation)
            selectedAnnotation = nil
    }
    
    // 更新地圖區域到第一個標記
    private func updateRegionToFirstLocation() {
        if let firstLocation = locationsManager.savedLocations.first {
            region.center = firstLocation.coordinate
        }
    }
}

//將輸入框和按鈕提取為一個單獨的組件
struct InputFields: View {
    @Binding var nameStr: String
    @Binding var latStr: String
    @Binding var lngStr: String
    var onAdd: () -> Void

    var body: some View {
        HStack {
            TextField("Name", text: $nameStr)
                .textFieldStyle(.roundedBorder)
            TextField("Lat", text: $latStr)
                .textFieldStyle(.roundedBorder)
            TextField("Lng", text: $lngStr)
                .textFieldStyle(.roundedBorder)
            Button("Add") {
                onAdd()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// 自定義 UIViewRepresentable，用於封裝 MKMapView
struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    //@Binding var pointOfInterest: [AnnotatedItem]
    var savedLocations: [AnnotatedItem]
    @Binding var nameStr: String
    @Binding var latStr: String
    @Binding var lngStr: String
    @Binding var selectedAnnotation: AnnotatedItem?
    @Binding var showDeleteConfirmation: Bool
    @Binding var showEditSheet: Bool
    var locationManager: LocationManager
    @Binding var routeOverlay: MKPolyline?
    @Binding var isNavigating: Bool // 新增屬性，用於傳遞導航狀態
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        var locationManager: LocationManager
        
        init(parent: MapViewWrapper, locationManager: LocationManager) {
            self.parent = parent
            self.locationManager = locationManager
        }
        
        /// 處理地圖點擊事件，更新輸入框
        @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
            let mapView = sender.view as! MKMapView
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // 更新輸入框
            parent.latStr = String(format: "%.6f", coordinate.latitude)
            parent.lngStr = String(format: "%.6f", coordinate.longitude)
            parent.nameStr = "New Point"
        }
        /// 處理標記點擊事件
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation else { return }
            guard let matchedAnnotation = parent.savedLocations.first(where: {
                    $0.coordinate.latitude == annotation.coordinate.latitude &&
                    $0.coordinate.longitude == annotation.coordinate.longitude
            }) else { return }
            
            // 彈出選項（編輯或刪除）
            parent.selectedAnnotation = matchedAnnotation
            parent.showDeleteConfirmation = true
            //parent.showEditSheet = true
        }
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue // 路徑顏色
                renderer.lineWidth = 5.0            // 路徑寬度
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image = UIImage(systemName: "location.north.fill") // 用戶位置箭頭
                if let heading = locationManager.userHeading {
                    annotationView.transform = CGAffineTransform(rotationAngle: CGFloat(heading) * .pi / 180)
                }
                return annotationView
            }
            return nil
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        //return
        return Coordinator(parent: self, locationManager: locationManager)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true //顯示藍色當前位置標記
        // 設置初始區域
        //mapView.setRegion(region, animated: false)
        mapView.setRegion(region, animated: true)
        
        // 禁用 3D 地图和地形渲染
        mapView.showsBuildings = false
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        mapView.mapType = .standard // 可尝试切换为 .satellite 或 .hybrid

        // 添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if selectedAnnotation == nil, let currentLocation = locationManager.currentLocation {
            print("Updating map to current location.")
            uiView.setCenter(currentLocation, animated: true)
        }

        // 如果有選中的地點，保持地圖聚焦在選中的地點
        if let annotation = selectedAnnotation {
            let targetRegion = MKCoordinateRegion(center: annotation.coordinate,
                                                      span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            print("Updating map to selected annotation: \(annotation.name)")
            uiView.setRegion(targetRegion, animated: true)
        }
        
        
        // 清理舊標記並添加新標記
        uiView.removeAnnotations(uiView.annotations)
        let annotations = savedLocations.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = item.name
            annotation.coordinate = item.coordinate
            return annotation
        }
        uiView.addAnnotations(annotations)
        
        // 如果存在舊的 routeOverlay，並且正在導航，則更新它
        if let existingOverlay = routeOverlay, isNavigating {
            print("Updating route overlay on map...")
            // 如果地圖上已存在該覆蓋物，則不需要移除
            if !uiView.overlays.contains(where: { $0 as? MKPolyline == existingOverlay }) {
                uiView.addOverlay(existingOverlay)
            }

            // 調整地圖顯示區域
            let routeRect = existingOverlay.boundingMapRect
            let edgePadding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            uiView.setVisibleMapRect(routeRect, edgePadding: edgePadding, animated: true)
        }

        // 如果導航已停止，清理所有路徑
        if !isNavigating {
            print("Stopping navigation, clearing all overlays...")
            uiView.overlays.forEach { overlay in
                if overlay is MKPolyline {
                    uiView.removeOverlay(overlay)
                }
            }
        }
    }
}


/// Edit Annotation View
struct EditAnnotationView: View {
    @Binding var annotation: AnnotatedItem
    var onSave: () -> Void // 不需要傳遞數據，因為 `@Binding` 已經是雙向綁定
    var onCancel: () -> Void // 新增取消的回調
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $annotation.name)
                TextField("Latitude", value: $annotation.coordinate.latitude, format: .number)
                TextField("Longitude", value: $annotation.coordinate.longitude, format: .number)
            }
            .navigationTitle("Edit Annotation")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        onCancel() // 調用取消回調
                    }
                }
            }
        }
    }
}

struct LocationsView_Previews: PreviewProvider {
    static var previews: some View {
        LocationsView()
    }
}
