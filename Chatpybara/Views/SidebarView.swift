//
//  SidebarView.swift
//  Chatpybara
//
//  Created by makisbea on 1/29/25.
//
import SwiftUI
import SwiftData

@Model
class ChatRoom {
    @Attribute(.unique) var id: UUID
    var name: String
    var messages: [Message]
    var thumbnailName: String
    
    // 1) New property to keep track of latest message
    var lastMessageDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        thumbnailName: String = "apple", // default
        messages: [Message] = [],
        lastMessageDate: Date = .now
    ) {
        self.id = id
        self.name = name
        self.thumbnailName = thumbnailName
        self.messages = messages
        self.lastMessageDate = lastMessageDate
    }
}

struct SidebarView: View {
    @Environment(\.modelContext) private var context  // <-- an instance of ModelContext
        
    // This property fetches all ChatRooms from SwiftData automatically
    @Query(sort: \ChatRoom.lastMessageDate, order: .reverse) var rooms: [ChatRoom]

    // State variables to manage the presentation of the create room sheet and input
    @State private var isShowingCreateRoomSheet = false
    @State private var newRoomName = ""
    @State private var errorMessage: String?
    
    @State private var selectedRoom: ChatRoom?
    @State private var isShowingRenameSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // --- Custom Toolbar / Header ---
            HStack {
                Text("Chatpybara")
                    .font(.system(size: 24, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    isShowingCreateRoomSheet = true
                }) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 24, weight: .bold))
                        .imageScale(.large)
                        .padding(12)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider() // optional, helps visually separate header from list
            
            // --- Your List of Rooms ---
            List {
                ForEach(rooms) { room in
                    NavigationLink {
                        ChatRoomView(room: room)
                    } label: {
                        RoomRowView(room: room)
                    }
                    .contextMenu {
                        Button("Rename") {
                            selectedRoom = room
                            newRoomName = room.name
                            isShowingRenameSheet = true
                        }
                        Button("Delete", role: .destructive) {
                            deleteRoom(room)
                        }
                    }
                }
                .onDelete(perform: deleteRooms)
            }
            .listStyle(.plain)
        }
        // Attach sheets & alerts to the VStack
        .sheet(isPresented: $isShowingCreateRoomSheet) {
            CreateRoomSheet(
                roomName: $newRoomName,
                isPresented: $isShowingCreateRoomSheet,
                onCreate: createRoom,
                errorMessage: $errorMessage
            )
        }
        .sheet(isPresented: $isShowingRenameSheet) {
            RenameRoomSheet(
                roomName: $newRoomName,
                isPresented: $isShowingRenameSheet,
                onRename: renameRoom,
                errorMessage: $errorMessage
            )
        }
        .alert(isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func createRoom() {
            let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                errorMessage = "Room name cannot be empty."
                return
            }
            
            // Optionally, check for unique room names
            if rooms.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
                errorMessage = "A room with this name already exists."
                return
            }
            
            // Insert new room into the SwiftData model context
            let newRoom = ChatRoom(name: trimmedName)
            context.insert(newRoom)
            
            // Reset the input and dismiss the sheet
            newRoomName = ""
            isShowingCreateRoomSheet = false
        }
    
    private func renameRoom() {
        // Optional: Trim whitespace, validate uniqueness, etc.
        let trimmedName = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Room name cannot be empty."
            return
        }

        // If you want to ensure uniqueness:
        if rooms.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "A room with this name already exists."
            return
        }

        // Update the selected room's name
        selectedRoom?.name = trimmedName
        
        // Dismiss the sheet
        isShowingRenameSheet = false
        newRoomName = ""
    }

    private func deleteRooms(at offsets: IndexSet) {
        for index in offsets {
                    let room = rooms[index]
                    context.delete(room)
                }
    }
    
    private func deleteRoom(_ room: ChatRoom) {
        if let index = rooms.firstIndex(where: { $0.id == room.id }) {
            context.delete(rooms[index])
        }
    }

}

struct RoomRowView: View {
    let room: ChatRoom
    
    var body: some View {
        HStack(spacing: 15) {
            // --- Thumbnail on the left ---
            
            Image(room.thumbnailName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)       // Make it bigger here
                .clipShape(Circle())               // Optional circle shape
                .shadow(radius: 2)                 // Minor drop shadow

            // --- Text / Room Name ---
            Text(room.name)
                .font(.system(size: 18, weight: .semibold)) // Increase font size
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 8)  // Add vertical padding to make the cell taller
    }
}
