import Foundation

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class AuthService {
    static let shared = AuthService()
    
    private let baseURL = "https://echopathapi.ejvapps.online/api/auth/child-access/"
    
    private init() {}
    
    func login(shortId: String, dateOfBirth: Date) async throws -> LoginResponse {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: dateOfBirth)
        
        let requestBody = LoginRequest(shortId: shortId, dateOfBirth: dateString)
        
        guard let url = URL(string: baseURL) else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw AuthError.decodingError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AuthError.httpError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                return loginResponse
            } catch {
                throw AuthError.decodingError(error)
            }
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.networkError(error)
        }
    }
}

