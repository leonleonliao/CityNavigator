//
//  ContentView.swift
//  Coursework
//
//  Created by Leon Liao on 10/1/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            LocationsView().tabItem ({
                Image(systemName: "mappin.circle.fill")
                Text("Locations")
            }).tag(0)
                
/*            SchoolView().tabItem ({
                Image(systemName: "graduationcap.fill")
                Text("Edit")
            }).tag(1)
        
            MyLocationView().tabItem({
                Image(systemName: "globe")
                Text("Navigation")
            }).tag(2)
 */
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
