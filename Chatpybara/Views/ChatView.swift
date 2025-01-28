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
                Button(action: createRoom) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationTitle("Chat Rooms")
    }
    
    private func createRoom() {
        // Insert new room into the SwiftData model context
        let newRoom = ChatRoom(name: "Room \(rooms.count + 1)")
        // Insert using the context instance
        context.insert(newRoom)
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
    @Bindable var room: ChatRoom   // SwiftData’s “binding” to track changes
    @Environment(\.modelContext) private var context  // Access the ModelContext
        
    @State private var newMessage = ""
    private var messageService: MessageService
    
    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack {
                        ForEach(room.messages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    // Optional scrolling logic ...
                }
            }
            
            messageInputView
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var messageInputView: some View {
        HStack {
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(.roundedBorder)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let message = Message(text: newMessage, isSender: true)
        room.messages.append(message)
        
        newMessage = ""
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
