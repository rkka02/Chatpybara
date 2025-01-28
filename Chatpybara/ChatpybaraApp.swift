//
//  ChatpybaraApp.swift
//  Chatpybara
//
//  Created by makisbea on 1/28/25.
//

import SwiftUI
import SwiftData

@main
struct ChatpybaraApp: App {
    // Create a container that knows about all your SwiftData models
    @State private var modelContainer = try! ModelContainer(for: ChatRoom.self, Message.self)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Make the container available to child views
                .modelContainer(modelContainer)
        }
    }
}
