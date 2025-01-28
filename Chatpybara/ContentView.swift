//
//  ContentView.swift
//  Chatpybara
//
//  Created by makisbea on 1/28/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView() // Sidebar for chat room selection
        } detail: {
            Text("Select a chat room") // Placeholder for detail view
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
