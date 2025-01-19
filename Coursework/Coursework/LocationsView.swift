//
//  LocationsView.swift
//  Coursework
//
//  Created by Leon Liao on 19/1/2025.
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

// 為了支持當前位置的功能，用於獲取並更新設備的當前位置
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //currentLocation = locations.last?.coordinate
        if let location = locations.last {
              print("Current Location：\(location.coordinate.latitude), \(location.coordinate.longitude)")
              currentLocation = location.coordinate
          }
    }
}

/// 主視圖
struct LocationsView: View {
    @State private var pointOfInterest = [
        AnnotatedItem(name: "IVE(ST)", description: "A vocational education institution.", imageName: "building.2", coordinate: .init(latitude: 22.39002, longitude: 114.19834)),
        AnnotatedItem(name: "Ocean Park", description: "A marine mammal park, oceanarium, and amusement park.", imageName: "tortoise", coordinate: .init(latitude: 22.24825, longitude: 114.17566)),
        AnnotatedItem(name: "The Peak", description: "A famous tourist attraction with panoramic views.", imageName: "mountain.2", coordinate: .init(latitude: 22.27723, longitude: 114.14519)),
        AnnotatedItem(name: "Hong Kong Disneyland", description: "A magical theme park with Disney characters.", imageName: "sparkles", coordinate: .init(latitude: 22.31296, longitude: 114.04123))
    ]
    
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.37464, longitude: 114.14907),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    @State private var nameStr: String = "New Point"
    @State private var latStr: String = ""
    @State private var lngStr: String = ""
    
    // 用於選中標記的狀態
    @State private var selectedAnnotation: AnnotatedItem? = nil
    @State private var showDeleteConfirmation = false
    @State private var showDetailsSheet = false
    @State private var showEditSheet = false
    @State private var selectedIndex: Int? = nil // 儲存選中的地點索引
    @StateObject private var locationManager = LocationManager()
    @State private var showRoute = false
    @State private var routeOverlay: MKPolyline? = nil
    
    var body: some View {
        VStack {
            // 輸入框和按鈕，用於新增標記
            HStack {
                TextField("Name", text: $nameStr)
                    .textFieldStyle(.roundedBorder)
                TextField("Lat", text: $latStr)
                    .textFieldStyle(.roundedBorder)
                TextField("Lng", text: $lngStr)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    addAnnotationFromInput()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            // 地圖
            ZStack {
                // 自定義 MapViewWrapper，用於處理點擊事件和標記操作
                MapViewWrapper(region: $region, pointOfInterest: $pointOfInterest, nameStr: $nameStr, latStr: $latStr, lngStr: $lngStr, selectedAnnotation: $selectedAnnotation, showDeleteConfirmation: $showDeleteConfirmation, showEditSheet: $showEditSheet, locationManager: locationManager, routeOverlay: $routeOverlay
                )
              /*  .onAppear {
                    if let currentLocation = locationManager.currentLocation {
                            region.center = currentLocation
                    }
                }
                .edgesIgnoringSafeArea(.top)
                .frame(height: 500)*/
                // 放大與縮小按鈕
                VStack {
                    Spacer()// 將按鈕置於底部
                    HStack {
                        //Spacer()// 將按鈕置於右側
                        VStack(spacing: 10) {
                            /*
                            Button(action: zoomIn) {
                                Image(systemName: "plus.magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            Button(action: zoomOut) {
                                Image(systemName: "minus.magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                             */
                            //在卡片選擇後，顯示導航按鈕：
                            if let index = selectedIndex {
                                Button("Navigate to \(pointOfInterest[index].name)") {
                                    startNavigation(to: pointOfInterest[index].coordinate)
                                }
                                .padding()
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }
                }
            }

            // 橫向標記列表
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {// 將間距設置為 0，確保單次只顯示一個卡片
                        ForEach(pointOfInterest.indices, id: \.self) { index in
                            VStack {
                                Image(systemName: pointOfInterest[index].imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                    .padding(.bottom, 10)
                                Text(pointOfInterest[index].name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 5)
                                Text(pointOfInterest[index].description)
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
                                focusOnAnnotation(pointOfInterest[index]) // 更新地图位置
                            }
                            .animation(.spring(), value: selectedIndex)
                            .id(index)// 設置唯一 ID
                        }
                    }
                    .padding(.horizontal)
                    //.frame(maxWidth: .infinity)// 確保 HStack 占滿 ScrollView
                    //.contentShape(Rectangle()) // 為 HStack 添加手勢檢測
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
        
        .alert("Delete Annotation", isPresented: $showDeleteConfirmation, actions: {
            Button("View Details") {
                showDetailsSheet = true
            }
            Button("Edit") {
                    showEditSheet = true
                }
            Button("Cancel", role: .cancel, action: {})
            Button("Delete", role: .destructive, action: {
                if let annotation = selectedAnnotation {
                    removeAnnotation(item: annotation)
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
            if let selectedAnnotationIndex = pointOfInterest.firstIndex(where: { $0.id == selectedAnnotation?.id }) {
                EditAnnotationView(annotation: $pointOfInterest[selectedAnnotationIndex]) {
                    showEditSheet = false
                }
            }
        }
    }
    
    
    /// 處理卡片滑動
    private func handleCardSwipe(value: DragGesture.Value, proxy: ScrollViewProxy) {
        if value.translation.width < -50 && (selectedIndex ?? 0) < pointOfInterest.count - 1 {
            selectedIndex = (selectedIndex ?? 0) + 1
        } else if value.translation.width > 50 && (selectedIndex ?? 0) > 0 {
            selectedIndex = (selectedIndex ?? 0) - 1
        }
        // 滾動到所選的卡片
        withAnimation {
            if let selectedIndex = selectedIndex {
                proxy.scrollTo(selectedIndex, anchor: .center)
                focusOnAnnotation(pointOfInterest[selectedIndex])
            }
        }
    }

    
    /// 聚焦到指定標記
    private func focusOnAnnotation(_ annotation: AnnotatedItem) {
        //selectedAnnotation = annotation
        
        // 强制触发 region 更新，通过微调经纬度确保值发生变化
        let adjustedCenter = CLLocationCoordinate2D(
            latitude: annotation.coordinate.latitude + 0.000001,
            longitude: annotation.coordinate.longitude + 0.000001
        )
        
        DispatchQueue.main.async {
            region = MKCoordinateRegion(
                center: adjustedCenter,
                //center: annotation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // 放大地图
            )
        }
        if let currentLocation = locationManager.currentLocation {
            drawRoute(from: currentLocation, to: annotation.coordinate)
        }
    }
    
    //繪製路線 draw Route
    private func drawRoute(from start: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile // 設置交通方式為駕車
            
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Failed to calculate route: \(error.localizedDescription)")
                return
            }
            guard let route = response?.routes.first else {
                print("Failed to calculate route: \(error?.localizedDescription ?? "Unknown error")")
                    return
            }
                
            DispatchQueue.main.async {
                // 清理舊路線
                routeOverlay = nil
                // 添加新路線
                routeOverlay = route.polyline
                showRoute = true
            }
        }
    }
    
    //開始導航 Start Navigation
    private func startNavigation(to destination: CLLocationCoordinate2D) {
        guard let currentLocation = locationManager.currentLocation else { return }
            
        let source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation))
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            destination.name = "Destination"
            
        MKMapItem.openMaps(with: [source, destination], launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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
    
    
    
    
    
    /// 根據輸入框中的值添加標記
    func addAnnotationFromInput() {
        if let lat = Double(latStr), let lng = Double(lngStr) {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let annotation = AnnotatedItem(name: nameStr,
                                           description: "Default description", // 添加默認描述
                                           imageName: "default.image",         // 添加默認圖片名稱
                                           coordinate: coord)
            
            // 添加標記
            pointOfInterest.append(annotation)
            
            // 將地圖中心移動到新標記
            region.center = coord
            
            // 清空輸入框
            nameStr = "New Point"
            latStr = ""
            lngStr = ""
        } else {
            print("Invalid latitude or longitude")
        }
    }
    /// 根據標記 id 刪除標記
    func removeAnnotation(item: AnnotatedItem) {
        if let index = pointOfInterest.firstIndex(where: { $0.id == item.id }) {
               pointOfInterest.remove(at: index)
        }
    }
    func updateAnnotation(_ updatedAnnotation: AnnotatedItem) {
        if let index = pointOfInterest.firstIndex(where: { $0.id == updatedAnnotation.id }) {
            pointOfInterest[index] = updatedAnnotation
        }
    }
}

/// 自定義 UIViewRepresentable，用於封裝 MKMapView
struct MapViewWrapper: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var pointOfInterest: [AnnotatedItem]
    @Binding var nameStr: String
    @Binding var latStr: String
    @Binding var lngStr: String
    @Binding var selectedAnnotation: AnnotatedItem?
    @Binding var showDeleteConfirmation: Bool
    @Binding var showEditSheet: Bool
    var locationManager: LocationManager
    @Binding var routeOverlay: MKPolyline?
    
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        
        init(parent: MapViewWrapper) {
            self.parent = parent
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
            guard let matchedAnnotation = parent.pointOfInterest.first(where: {
                    $0.coordinate.latitude == annotation.coordinate.latitude &&
                    $0.coordinate.longitude == annotation.coordinate.longitude
            }) else { return }
            // 彈出選項（編輯或刪除）
            parent.selectedAnnotation = matchedAnnotation
            parent.showDeleteConfirmation = true
            //parent.showEditSheet = true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        //return
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true //顯示藍色當前位置標記
        // 設置初始區域
        //mapView.setRegion(region, animated: false)
        mapView.setRegion(region, animated: true)
        
        // 禁用 3D 地图和地形渲染
        //mapView.showsBuildings = false
        //mapView.showsCompass = false
        //mapView.showsScale = false
        //mapView.isRotateEnabled = false
        //mapView.isPitchEnabled = false
        
        mapView.mapType = .standard // 可尝试切换为 .satellite 或 .hybrid

        
        // 添加點擊手勢
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 打印调试信息，确保 region 正常更新
        print("Current MKMapView region: center = (\(uiView.region.center.latitude), \(uiView.region.center.longitude)), span = (\(uiView.region.span.latitudeDelta), \(uiView.region.span.longitudeDelta))")
        print("Target region: center = (\(region.center.latitude), \(region.center.longitude)), span = (\(region.span.latitudeDelta), \(region.span.longitudeDelta))")

        if uiView.region.center.latitude != region.center.latitude ||
            uiView.region.center.longitude != region.center.longitude ||
            uiView.region.span.latitudeDelta != region.span.latitudeDelta ||
            uiView.region.span.longitudeDelta != region.span.longitudeDelta {
            uiView.setRegion(region, animated: true)
            uiView.setCenter(region.center, animated: true) // 补充中心点更新
        }
        // 设置地图中心和缩放级别
        uiView.setCenter(region.center, animated: true)
           
        _ = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        // _ = MKCoordinateRegion(center: region.center, span: span)
        // 更新地圖的區域，确保动画生效
        uiView.setRegion(region, animated: true)
        
        // 清理舊標記並添加新標記
        uiView.removeAnnotations(uiView.annotations)
        let annotations = pointOfInterest.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = item.name
            annotation.coordinate = item.coordinate
            return annotation
        }
        uiView.addAnnotations(annotations)
        
        // 顯示當前位置
        /*
        if let currentLocation = locationManager.currentLocation {
            let userAnnotation = MKPointAnnotation()
            userAnnotation.title = "Current Location"
            userAnnotation.coordinate = currentLocation
            // 移除舊的當前位置標記，避免重複
            uiView.annotations.forEach { annotation in
                if annotation.title == "Current Location" {
                    uiView.removeAnnotation(annotation)
                }
            }
            uiView.setCenter(currentLocation, animated: true)
            uiView.addAnnotation(userAnnotation)
        }*/
        
        // 清理舊的路徑
        if let existingOverlay = routeOverlay {
            uiView.removeOverlay(existingOverlay)
        }
        // 添加新的路徑
        if let routeOverlay = routeOverlay {
            uiView.addOverlay(routeOverlay)
        }
    }
}

/// 編輯標記的視圖
/// Edit Annotation View
struct EditAnnotationView: View {
    //@State var annotation: AnnotatedItem
    @Binding var annotation: AnnotatedItem
    var onSave: () -> Void // 不需要傳遞數據，因為 `@Binding` 已經是雙向綁定
    
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
                    Button("Cancel", role: .cancel) {}
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
