import Foundation

// MARK: - Login Models

public struct LoginRequest: Encodable {
    public let username: String
    public let password: String
    public let loginType: String

    public init(username: String = "sjqa-divya", password: String = "ff@123", loginType: String = "fmcg") {
        self.username = username
        self.password = password
        self.loginType = loginType
    }
}

public struct LoginResponse: Decodable {
    public let success: Bool
    public let message: String?
    public let response: LoginPayload?

    public struct LoginPayload: Decodable {
        public let status_code: String?
        public let Message: String?
        public let Username: String?
        public let Jwt_Token: String?
        public let SenderId: String?
        public let BaseUrl: String?
        public let ServerPath: String?
    }
}

// MARK: - Master Sync Generic Wrapper

public struct MasterSyncResponse<T: Decodable>: Decodable {
    public let success: Bool
    public let message: String?
    public let dataCount: Int?
    public let masterName: String?
    public let response: [T]
}

// MARK: - Products Master DTO

public struct ProductDTO: Decodable, Identifiable {
    public let id: String
    public let name: String
    public let Code: String?
    public let Product_Description: String?
    public let product_unit: String?
    public let Division_Code: Int?

    public init(id: String, name: String, Code: String? = nil, Product_Description: String? = nil, product_unit: String? = nil, Division_Code: Int? = nil) {
        self.id = id
        self.name = name
        self.Code = Code
        self.Product_Description = Product_Description
        self.product_unit = product_unit
        self.Division_Code = Division_Code
    }
}

// MARK: - StateRate DTO

public struct StateRateDTO: Decodable {
    public let State_Code: Int?
    public let Division_Code: Int?
    public let Product_Detail_Code: String
    public let Retailor_Price: String?
    public let MRP_Price: String?
    public let Min_price: String?

    public init(Product_Detail_Code: String, Retailor_Price: String?, State_Code: Int? = nil, Division_Code: Int? = nil, MRP_Price: String? = nil, Min_price: String? = nil) {
        self.Product_Detail_Code = Product_Detail_Code
        self.Retailor_Price = Retailor_Price
        self.State_Code = State_Code
        self.Division_Code = Division_Code
        self.MRP_Price = MRP_Price
        self.Min_price = Min_price
    }

    /// Converts string price to Double safely
    public var parsedRate: Double {
        guard let priceStr = Retailor_Price?.trimmingCharacters(in: .whitespacesAndNewlines),
              let val = Double(priceStr) else {
            return 0.0
        }
        return val
    }
}

// MARK: - Save Sample Order Models

public struct SaveOrderPayload: Encodable {
    public let userName: String
    public let createdDate: String
    public let totalItems: String
    public let totalQty: String
    public let totalAmount: Double
    public let remarks: String
    public let productDetails: [SaveProductDetail]

    public init(userName: String, createdDate: String, totalItems: String, totalQty: String, totalAmount: Double, remarks: String, productDetails: [SaveProductDetail]) {
        self.userName = userName
        self.createdDate = createdDate
        self.totalItems = totalItems
        self.totalQty = totalQty
        self.totalAmount = totalAmount
        self.remarks = remarks
        self.productDetails = productDetails
    }

    public struct SaveProductDetail: Encodable {
        public let product_Code: String
        public let product_Name: String
        public let qty: String
        public let value: String

        public init(product_Code: String, product_Name: String, qty: String, value: String) {
            self.product_Code = product_Code
            self.product_Name = product_Name
            self.qty = qty
            self.value = value
        }
    }
}

public struct SaveOrderResponse: Decodable {
    public let status: Bool?
    public let message: String?
}
