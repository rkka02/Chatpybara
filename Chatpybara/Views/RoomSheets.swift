//
//  NameSheets.swift
//  Chatpybara
//
//  Created by makisbea on 1/29/25.
//
import SwiftUI
import SwiftData


struct CreateRoomSheet: View {
    @Binding var roomName: String
    @Binding var isPresented: Bool
    var onCreate: () -> Void
    @Binding var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Room Name")) {
                    TextField("Enter room name", text: $roomName)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("New Chat Room")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                    roomName = ""
                },
                trailing: Button("Create") {
                    onCreate()
                }
                .disabled(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}

struct RenameRoomSheet: View {
    @Binding var roomName: String
    @Binding var isPresented: Bool
    var onRename: () -> Void
    @Binding var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Room Name")) {
                    TextField("Enter new room name", text: $roomName)
                        .autocapitalization(.words)
                }
            }
            .navigationTitle("Rename Chat Room")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                    roomName = ""
                },
                trailing: Button("Rename") {
                    onRename()
                }
                .disabled(roomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
}
