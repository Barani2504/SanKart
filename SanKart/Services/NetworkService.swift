import Foundation

public protocol NetworkServiceProtocol {
    func login(request: LoginRequest) async throws -> String
    func fetchProducts() async throws -> [ProductDTO]
    func fetchRates() async throws -> [StateRateDTO]
    func saveOrder(payload: SaveOrderPayload) async throws -> SaveOrderResponse
    nonisolated var currentUsername: String { get }
}

public actor NetworkService: NetworkServiceProtocol {
    public static let shared = NetworkService()

    private let baseURL = "http://sjapi.salesjump.in"
    private var jwtToken: String?
    public nonisolated(unsafe) private(set) var currentUsername: String = "SJQA-divya"

    public init() {}

    // MARK: - API 1: Generate Token (Login)
    @discardableResult
    public func login(request: LoginRequest = LoginRequest()) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/ioslogin") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        guard let token = loginResponse.response?.Jwt_Token, !token.isEmpty else {
            let message = loginResponse.message ?? "Authentication failed"
            throw NSError(domain: "NetworkService", code: 401, userInfo: [NSLocalizedDescriptionKey: message])
        }

        self.jwtToken = token
        if let username = loginResponse.response?.Username, !username.isEmpty {
            self.currentUsername = username
        }
        return token
    }

    // MARK: - Token Access Helper
    private func getValidToken() async throws -> String {
        if let token = self.jwtToken {
            return token
        }
        return try await login()
    }

    // MARK: - API 2: Product List (Master Sync)
    public func fetchProducts() async throws -> [ProductDTO] {
        return try await fetchWithRetryOnAuth { token in
            try await self.executeMasterSync(masterName: "Products", token: token, as: ProductDTO.self)
        }
    }

    // MARK: - API 3: Rate (Retailer Price by Product Code)
    public func fetchRates() async throws -> [StateRateDTO] {
        return try await fetchWithRetryOnAuth { token in
            try await self.executeMasterSync(masterName: "StateRate", token: token, as: StateRateDTO.self)
        }
    }

    // Generic Master Sync Call
    private func executeMasterSync<T: Decodable>(masterName: String, token: String, as type: T.Type) async throws -> [T] {
        var components = URLComponents(string: "\(baseURL)/api/qc/getmasterSync")
        components?.queryItems = [
            URLQueryItem(name: "Master_Name", value: masterName),
            URLQueryItem(name: "SF_Code", value: "sjqamgr0005"),
            URLQueryItem(name: "State_Code", value: "24"),
            URLQueryItem(name: "Division_Code", value: "258"),
            URLQueryItem(name: "HqSf_Code", value: "sjqamgr0005")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            throw URLError(.userAuthenticationRequired)
        }

        let decoded = try JSONDecoder().decode(MasterSyncResponse<T>.self, from: data)
        return decoded.response
    }

    // MARK: - API 4: Save Product List
    public func saveOrder(payload: SaveOrderPayload) async throws -> SaveOrderResponse {
        return try await fetchWithRetryOnAuth { token in
            guard let url = URL(string: "\(self.baseURL)/api/qc/SaveSampleIos") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                throw URLError(.userAuthenticationRequired)
            }

            let result = try JSONDecoder().decode(SaveOrderResponse.self, from: data)
            return result
        }
    }

    // Helper to automatically retry once after refreshing token if 401 occurs
    private func fetchWithRetryOnAuth<T>(_ operation: (String) async throws -> T) async throws -> T {
        var token = try await getValidToken()
        do {
            return try await operation(token)
        } catch let error as URLError where error.code == .userAuthenticationRequired {
            token = try await login()
            return try await operation(token)
        }
    }
}
