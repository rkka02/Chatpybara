//
//  ChatView.swift
//  Chatpybara
//
//  Created by makisbea on 1/28/25.
//
import SwiftUI
import SwiftData

@Model
class ChatRoom {
    @Attribute(.unique) var id: UUID
    var name: String
    var messages: [Message]
    
    init(id: UUID = UUID(), name: String, messages: [Message] = []) {
        self.id = id
        self.name = name
        self.messages = messages
    }
}

@Model
class Message {
    @Attribute(.unique) var id: UUID
    var text: String
    var isSender: Bool
    var date: Date
    
    init(id: UUID = UUID(), text: String, isSender: Bool, date: Date = Date()) {
        self.id = id
        self.text = text
        self.isSender = isSender
        self.date = date
    }
}

struct SidebarView: View {
    @Environment(\.modelContext) private var context  // <-- an instance of ModelContext
        
    // This property fetches all ChatRooms from SwiftData automatically
    @Query(sort: \ChatRoom.name) var rooms: [ChatRoom]
    
    // State variables to manage the presentation of the create room sheet and input
    @State private var isShowingCreateRoomSheet = false
    @State private var newRoomName = ""
    @State private var errorMessage: String?
    
    var body: some View {
        List {
            ForEach(rooms) { room in
                NavigationLink {
                    ChatRoomView(room: room)
                } label: {
                    Text(room.name)
                }
            }
            .onDelete(perform: deleteRooms)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    isShowingCreateRoomSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationTitle("Chat Rooms")
        .sheet(isPresented: $isShowingCreateRoomSheet) {
                    CreateRoomSheet(
                        roomName: $newRoomName,
                        isPresented: $isShowingCreateRoomSheet,
                        onCreate: createRoom,
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
    
    private func deleteRooms(at offsets: IndexSet) {
        for index in offsets {
                    let room = rooms[index]
                    context.delete(room)
                }
    }
}

// MARK: - Chat Room View
struct ChatRoomView: View {
    @Bindable var room: ChatRoom
    @Environment(\.modelContext) private var context

    @State private var newMessage = ""
    @State private var errorMessage: String? // For error handling
    
    // FocusState to manage keyboard focus
    @FocusState private var isTextFieldFocused: Bool
    
    // Instantiate ChatService using the environment's ModelContext
    private var chatService: ChatService {
        ChatService(context: context)
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack {
                        ForEach(room.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    // Optional: Add scrolling logic if needed
                    .onChange(of: room.messages.count) { _ in
                                            if let lastMessage = room.messages.last {
                                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                            }
                    }
                }
            }

            messageInputView
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
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
        .onTapGesture {
            isTextFieldFocused = false
        }
    }

    private var messageInputView: some View {
        HStack {
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)

            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) // Disable if input is empty
        }
        .padding()
    }

    private func sendMessage() {
        // Capture the current message text
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Clear the TextField immediately
        newMessage = ""
        
        // Proceed only if the message is not empty after trimming
        guard !messageText.isEmpty else { return }
        
        // Perform the asynchronous send operation
        Task {
            do {
                try await chatService.sendMessage(to: room, text: messageText)
                // Optionally, you can add scrolling to the bottom here
            } catch {
                // Handle the error by updating the errorMessage state
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = room.messages.last else { return }
        proxy.scrollTo(lastMessage.id, anchor: .bottom)
    }
}
// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isSender {
                Spacer()
            }
            
            Text(message.text)
                .padding(10)
                .foregroundColor(message.isSender ? .white : .black)
                .background(message.isSender ? Color.blue : Color.gray.opacity(0.2))
                .cornerRadius(15)
            
            if !message.isSender {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
    }
}

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
