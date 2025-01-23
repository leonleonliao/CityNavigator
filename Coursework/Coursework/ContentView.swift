//
//  ContentView.swift
//  Coursework
//
//  Created by Leon Liao on 1/1/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationsManager = LocationsManager(username: "current_user") // 模擬當前登錄用戶
    
    var body: some View {
        TabView {
            
            // LocationsView 獲取共享的 LocationsManager
            LocationsView()
                .tabItem {
                    Image(systemName: "mappin.circle.fill")
                    Text("Locations")
                }
                .tag(0)
                .environmentObject(locationsManager) // 傳遞共享的數據模型

            // AccountView 獲取共享的 LocationsManager
            AccountView()
                .tabItem {
                    Image(systemName: "globe")
                    Text("Account")
                }
                .tag(1)
                .environmentObject(locationsManager) // 傳遞共享的數據模型
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
