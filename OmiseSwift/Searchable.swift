import Foundation

public protocol Searchable {
    static var scopeName: String { get }
    associatedtype FilterParams: OmiseFilterParams
}

extension Searchable {
    public static var scopeName: String {
        return String(describing: self).lowercased()
    }
}

public struct SearchParams<FilterParams: OmiseFilterParams>: APIJSONQuery {
    public var scope: String
    public var page: Int?
    public var query: String?
    public var order: Ordering?
    public var filter: FilterParams?
    
    private enum CodingKeys: String, CodingKey {
        case scope
        case page
        case query
        case order
        case filter = "filters"
    }
    
    public init(scope: String, page: Int? = nil, query: String? = nil, order: Ordering? = nil, filter: FilterParams? = nil) {
        self.scope = scope
        self.page = page
        self.query = query
        self.order = order
        self.filter = filter
    }
    
    public init<T: Searchable>(searhScopeType: T.Type,
                page: Int? = nil, query: String? = nil, order: Ordering? = nil, filter: FilterParams? = nil)
        where T.FilterParams == FilterParams {
            self.init(scope: T.scopeName, page: page, query: query, order: order, filter: filter)
    }
}

public protocol OmiseFilterParams: APIJSONQuery , Decodable {}


public extension Searchable where Self: OmiseResourceObject {
    public typealias SearchEndpoint = APIEndpoint<SearchResult<Self>>
    public typealias SearchRequest = APIRequest<SearchResult<Self>>
    
    public static func searchEndpointWithParams(params: SearchParams<FilterParams>?) -> SearchEndpoint {
        return SearchEndpoint(
            endpoint: .api,
            pathComponents: ["search"],
            parameter: .get(params)
        )
    }
    
    public static func search(using client: APIClient, parent: OmiseResourceObject? = nil, params: SearchParams<FilterParams>? = nil, callback: SearchRequest.Callback?) -> SearchRequest? {
        guard verifyParent(parent) else {
            return nil
        }
        
        let endpoint = self.searchEndpointWithParams(params: params)
        return client.requestToEndpoint(endpoint, callback: callback)
    }
    
    @discardableResult
    public static func search(using client: APIClient, searchParams: SearchParams<FilterParams>? = nil, callback: @escaping (Failable<Search<Self>>) -> Void) -> SearchRequest? {
        let endpoint = self.searchEndpointWithParams(params: searchParams)
        
        let requestCallback: SearchRequest.Callback = { result in
            let callbackResult = result.map({ Search(result: $0, order: searchParams?.order ?? .chronological) })
            callback(callbackResult)
        }
        
        return client.requestToEndpoint(endpoint, callback: requestCallback)
    }
    
    public static func makeLoadNextPageOperation(list: Search<Self>) -> SearchEndpoint {
        let listParams = SearchParams(scope: list.scope, page:  list.loadedPages.last?.advanced(by: 1) ?? 1, query: list.query, order: list.order, filter: list.filters)
        
        return SearchEndpoint(endpoint: .api, pathComponents: ["search"], parameter: .get(listParams))
    }
    
    @discardableResult
    static func loadNextPage(list: Search<Self>, using client: APIClient, callback: @escaping (Failable<[Self]>) -> Void) -> APIRequest<SearchEndpoint.Result>? {
        let operation = makeLoadNextPageOperation(list: list)
        
        let requestCallback: SearchRequest.Callback = { result in
            let callbackResult = result.map({ list.insert(from: $0) })
            callback(callbackResult)
        }
        
        return client.requestToEndpoint(operation, callback: requestCallback)
    }
    
    public static func makeLoadPreviousPageOperation(list: Search<Self>) -> SearchEndpoint {
        let listParams = SearchParams(scope: list.scope, page:  list.loadedPages.last?.advanced(by: -1) ?? 1, query: list.query, order: list.order, filter: list.filters)
        
        return SearchEndpoint(endpoint: .api, pathComponents: ["search"], parameter: .get(listParams))
    }
    
    @discardableResult
    static func loadPreviousPage(list: Search<Self>, using client: APIClient, callback: @escaping (Failable<[Self]>) -> Void) -> APIRequest<SearchEndpoint.Result>? {
        let operation = makeLoadNextPageOperation(list: list)
        
        let requestCallback: SearchRequest.Callback = { result in
            let callbackResult = result.map({ list.insert(from: $0) })
            callback(callbackResult)
        }
        
        return client.requestToEndpoint(operation, callback: requestCallback)
    }
}
