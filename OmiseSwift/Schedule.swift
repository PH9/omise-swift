import Foundation
import EventKit


public struct Schedule<Data: Schedulable>: OmiseResourceObject, Equatable {
    public enum Status: Equatable {
        case active
        case expiring
        case expired
        case deleted
        case suspended
        case unknown(String)
    }
    
    public static var resourceInfo: ResourceInfo {
        return ResourceInfo(path: "/schedules")
    }
    
    public let object: String
    public let location: String
    
    public let id: String
    public let isLive: Bool
    public let createdDate: Date
    
    public let status: Status
    
    public let every: Int
    public let period: Period
    
    public let startDate: DateComponents
    public let endDate: DateComponents
    
    public let occurrences: ListProperty<Occurrence<Data>>
    public let nextOccurrenceDates: [DateComponents]
    
    public let parameter: Data.Parameter
}

extension Schedule {
    fileprivate enum CodingKeys: CodingKey {
        case object
        case location
        case id
        case isLive
        case createdDate
        
        case status
        case every
        case period
        case startDate
        case endDate
        case occurrences
        case nextOccurrenceDates
        case parameter(String)
        
        public var stringValue: String {
            switch self {
            case .object:
                return "object"
            case .location:
                return "location"
            case .id:
                return "id"
            case .isLive:
                return "livemode"
            case .createdDate:
                return "created"
                
            case .status:
                return "status"
            case .every:
                return "every"
            case .period:
                return "period"
            case .startDate:
                return "start_date"
            case .endDate:
                return "end_date"
            case .occurrences:
                return "occurrences"
            case .nextOccurrenceDates:
                return "next_occurrence_dates"
            case .parameter(let parameterKey):
                return parameterKey
            }
        }
        
        init?(stringValue: String) {
            switch stringValue {
            case "object":
                self = .object
            case "location":
                self = .location
            case "id":
                self = .id
            case "livemode":
                self = .isLive
            case "created":
                self = .createdDate
                
            case "status":
                self = .status
            case "every":
                self = .every
            case "period":
                self = .period
            case "start_date":
                self = .startDate
            case "end_date":
                self = .endDate
            case "occurrences":
                self = .occurrences
            case "next_occurrence_dates":
                self = .nextOccurrenceDates
            case let value where Data.isValidParameterKey(value):
                self = .parameter(value)
            default:
                return nil
            }
        }
        
        init?(intValue: Int) {
            return nil
        }
        
        public var intValue: Int? {
            return nil
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        object = try container.decode(String.self, forKey: .object)
        location = try container.decode(String.self, forKey: .location)
        id = try container.decode(String.self, forKey: .id)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        isLive = try container.decode(Bool.self, forKey: .isLive)
        
        status = try container.decode(Schedule.Status.self, forKey: .status)
        
        every = try container.decode(Int.self, forKey: .every)
        period = try Period.init(from: decoder)
        
        startDate = try container.decodeOmiseDateComponents(forKey: .startDate)
        endDate = try container.decodeOmiseDateComponents(forKey: .endDate)
        
        occurrences = try container.decode(ListProperty<Occurrence<Data>>.self, forKey: .occurrences)
        nextOccurrenceDates = try container.decodeOmiseDateComponentsArray(forKey: .nextOccurrenceDates)
        
        let parameterKey = container.allKeys.first(where: { (key) -> Bool in
            if case .parameter = key {
                return true
            } else {
                return false
            }
        })
        if let parameterKey = parameterKey {
            parameter = try container.decode(Data.Parameter.self, forKey: parameterKey)
        } else {
            throw DecodingError.keyNotFound(
                Schedule<Data>.CodingKeys.parameter("parameter"),
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "Missing scheduling parameter")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(object, forKey: .object)
        try container.encode(location, forKey: .location)
        try container.encode(id, forKey: .id)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(isLive, forKey: .isLive)
        try container.encode(status, forKey: .status)
        try container.encode(every, forKey: .every)
        
        try period.encode(to: encoder)
        
        try container.encodeOmiseDateComponents(startDate, forKey: .startDate)
        try container.encodeOmiseDateComponents(endDate, forKey: .endDate)
        try container.encode(occurrences, forKey: .occurrences)
        try container.encodeOmiseDateComponentsArray(nextOccurrenceDates, forKey: .nextOccurrenceDates)
        try container.encode(parameter, forKey: .parameter(Data.parameterKey))
    }
}

extension Calendar {
    public static var scheduleAPICalendar: Calendar {
        return Calendar(identifier: .gregorian)
    }
}

public protocol SchedulingParameter: Codable {}

public protocol Schedulable: OmiseIdentifiableObject, OmiseCreatableObject {
    associatedtype Parameter: SchedulingParameter
    static func isValidParameterKey(_ key: String) -> Bool
    static var parameterKey: String { get }
}

public protocol APISchedulable: Schedulable {
    associatedtype ScheduleDataParams: APIJSONQuery
}

extension Schedulable {
    public static var parameterKey: String {
        return String(describing: self).lowercased()
    }
    
    public static func isValidParameterKey(_ key: String) -> Bool {
        return parameterKey == key
    }
}


extension Schedule.Status: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let status = try container.decode(String.self)
        switch status {
        case "active":
            self = .active
        case "expiring":
            self = .expiring
        case "expired":
            self = .expired
        case "deleted":
            self = .deleted
        case "suspended":
            self = .suspended
        case let value:
            self = .unknown(value)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let status: String
        switch self {
        case .active:
            status = "active"
        case .expiring:
            status = "expiring"
        case .expired:
            status = "expired"
        case .deleted:
            status = "deleted"
        case .suspended:
            status = "suspended"
        case .unknown(let value):
            status = value
        }
        try container.encode(status)
    }
}


public struct AnySchedulable: Schedulable {
    public enum AnySchedulingParameter: SchedulingParameter {
        case charge(ChargeSchedulingParameter)
        case transfer(TransferSchedulingParameter)
        case other(json: [String: Any])
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if let chargeParameter = try? container.decode(ChargeSchedulingParameter.self) {
                self = .charge(chargeParameter)
            } else if let transferParameter = try? container.decode(TransferSchedulingParameter.self) {
                self = .transfer(transferParameter)
            } else {
                let json = try decoder.decodeJSONDictionary()
                self = .other(json: json)
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .charge(let parameter):
                try container.encode(parameter)
            case .transfer(let parameter):
                try container.encode(parameter)
            case .other(json: let parameter):
                try encoder.encodeJSONDictionary(parameter)
            }
        }
    }
    
    public typealias Parameter = AnySchedulingParameter
    public let id: String
    public let createdDate: Date
    public let object: String
    
    public let json: [String: Any]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case createdDate = "created"
        case object
    }
    
    public init(from decoder: Decoder) throws {
        let json = try decoder.decodeJSONDictionary()
        
        guard let object = json["object"] as? String else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing object value in Schedule")
            throw DecodingError.keyNotFound(CodingKeys.object, context)
        }
        
        guard let id = json["id"] as? String else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing object value in Schedule")
            throw DecodingError.keyNotFound(CodingKeys.id, context)
        }
        guard let createdDate = json["createdDate"] as? Date else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing object value in Schedule")
            throw DecodingError.keyNotFound(CodingKeys.createdDate, context)
        }
        
        (self.object, self.id, self.createdDate) = (object, id, createdDate)
        self.json = json
    }
    
    public static func isValidParameterKey(_ key: String) -> Bool {
        return key == Charge.parameterKey || key == Transfer.parameterKey
    }
}


extension Schedule: Listable {}
extension Schedule: Retrievable {}


public struct ScheduleParams<Data: APISchedulable>: APIJSONQuery {
    public let every: Int
    public let period: Period
    public let endDate: DateComponents
    public let startDate: DateComponents?
    
    public let scheduleData: Data.ScheduleDataParams
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Schedule<Data>.CodingKeys.self)
        
        try container.encode(every, forKey: .every)
        try container.encodeOmiseDateComponents(endDate, forKey: .endDate)
        try container.encodeOmiseDateComponentsIfPresent(startDate, forKey: .startDate)
        
        try period.encode(to: encoder)
        
        try container.encode(scheduleData, forKey: .parameter(Data.parameterKey))
    }
}

extension Schedule : Creatable where Data : Creatable & APISchedulable {
    public typealias CreateParams = ScheduleParams<Data>
}



