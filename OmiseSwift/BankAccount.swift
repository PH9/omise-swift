import Foundation

public struct BankAccount: OmiseObject {
    public let object: String
    
    public let bank: Bank
    public let accountNumber: String?
    public let lastDigits: LastDigits
    public let name: String
}

extension BankAccount {
    private enum CodingKeys: String, CodingKey {
        case object
        case bankCode = "bank_code"
        case bankBrand = "brand"
        case branchCode = "branch_code"
        case accountNumber = "number"
        case lastDigits = "last_digits"
        case name
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        object = try container.decode(String.self, forKey: .object)
        name = try container.decode(String.self, forKey: .name)
        lastDigits = try container.decode(LastDigits.self, forKey: .lastDigits)
        accountNumber = try container.decodeIfPresent(String.self, forKey: .object)
        
        let bankID = try container.decodeIfPresent(String.self, forKey: .bankBrand) ??
         container.decode(String.self, forKey: .bankCode)
        let branchCode = try container.decodeIfPresent(String.self, forKey: .branchCode)
        let bank = Bank(bankID: bankID, branchCode: branchCode)
        self.bank = bank
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object, forKey: .object)
        try container.encode(name, forKey: .name)
        try container.encode(lastDigits, forKey: .lastDigits)
        try container.encodeIfPresent(accountNumber, forKey: .accountNumber)
        
        try container.encodeIfPresent(bank.bankID, forKey: .bankBrand)
        try container.encodeIfPresent(bank.branchCode, forKey: .branchCode)
    }
}

public struct BankAccountParams: APIJSONQuery {
    public var brand: String?
    public var accountNumber: String?
    public var name: String?
    
    private enum CodingKeys: String, CodingKey {
        case brand
        case accountNumber = "number"
        case name
    }
    
    public init(brand: String? = nil, accountNumber: String? = nil, name: String? = nil) {
        self.brand = brand
        self.accountNumber = accountNumber
        self.name = name
    }
}


extension BankAccountParams {
    public init(createNewBankAccountWithBrand brand: String, accountNumber: String, name: String) {
        self.brand = brand
        self.name = name
        self.accountNumber = accountNumber
    }
}

