//
//  LLMService.swift
//  Chatpybara
//
//  Created by makisbea on 1/29/25.
//

// LLMService.swift (Mock implementation for testing)
class LLMService: LLMServiceProtocol {
    func generateResponse(from input: String) async throws -> String {
        // Replace with actual on-device LLM inference code
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
        return "This is a simulated response from the LLM."
    }
}
