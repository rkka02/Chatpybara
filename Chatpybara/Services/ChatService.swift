//
//  ChatService.swift
//  Chatpybara
//
//  Created by makisbea on 1/29/25.
//

// ChatService.swift
import SwiftUI
import SwiftData

class ChatService {
    private let context: ModelContext
    private let llmService: LLMServiceProtocol
    
    init(context: ModelContext, llmService: LLMServiceProtocol = LLMService()) {
        self.context = context
        self.llmService = llmService
    }

    /// Async version of sendMessage with LLM integration
    func sendMessage(to room: ChatRoom, text: String, isSender: Bool = true) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Create and save user message
        let userMessage = Message(text: text, isSender: isSender)
        await persistMessage(userMessage, to: room)
        
        // Get LLM response
        do {
            let responseText = try await llmService.generateResponse(from: text)
            let botMessage = Message(text: responseText, isSender: false)
            await persistMessage(botMessage, to: room)
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func persistMessage(_ message: Message, to room: ChatRoom) {
        room.messages.append(message)
        // 2) Update the room’s lastMessageDate
        room.lastMessageDate = message.date
        
        do {
            try context.save()
        } catch {
            print("Error saving message: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        // Add proper error handling (e.g., show error message in UI)
        print("LLM Error: \(error.localizedDescription)")
    }
}
