//
//  LLMService.swift
//  Chatpybara
//
//  Created by makisbea on 1/29/25.
//

protocol LLMServiceProtocol {
    func generateResponse(from input: String) async throws -> String
}
