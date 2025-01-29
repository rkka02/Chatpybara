//
//  ChatView.swift
//  Chatpybara
//
//  Created by makisbea on 1/28/25.
//
import SwiftUI
import SwiftData

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
            HStack {
                            DynamicHeightTextEditor(text: $newMessage)
                                .focused($isTextFieldFocused) // Ensure focus binding
                                .onTapGesture {
                                        isTextFieldFocused = true // Manually set focus
                                    }
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .padding(8)
                                    .foregroundColor(.white)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
        }
        .onTapGesture {
            isTextFieldFocused = false
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

struct DynamicHeightTextEditor: View {
    @Binding var text: String
    @State private var textHeight: CGFloat = 40 // Initial height
    private let placeholder: String
    @FocusState private var isTextFieldFocused: Bool // Bind focus state


    init(text: Binding<String>, placeholder: String = "Type a message...") {
        self._text = text
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Placeholder Text
            if text.isEmpty {
                Text(placeholder)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }

            // Background Text to measure size
            Text(text)
                .font(.body)
                .foregroundColor(.clear)
                .padding(10)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                textHeight = geometry.size.height
                            }
                            .onChange(of: text) { _ in
                                textHeight = geometry.size.height
                            }
                    }
                )

            // TextEditor for user input
            TextEditor(text: $text)
                .font(.body)
                .frame(height: max(30, textHeight)) // Minimum height of 30
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .focused($isTextFieldFocused) // Bind focus state here
        }
    }
}
