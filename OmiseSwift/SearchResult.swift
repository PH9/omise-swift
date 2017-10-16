import Foundation

public struct SearchResult<Item: Searchable & OmiseObject>: OmiseLocatableObject {
    public static var resourceInfo: ResourceInfo {
        return ResourceInfo(path: "/search")
    }
    
    public let object: String
    public let location: String
    public let scope: String
    public let query: String
    public let page: Int
    public let totalPage: Int
    
    public let numberOfItemsPerPage: Int
    public let total: Int
    
    public let filters: Item.FilterParams
    public var data: [Item]
}


extension SearchResult {
    private enum CodingKeys: String, CodingKey {
        case object
        case location
        case scope
        case query
        case page
        case totalPage = "total_pages"
        case numberOfItemsPerPage = "per_page"
        case total
        case filters
        case data
    }
}

