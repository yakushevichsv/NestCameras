import Foundation

//MARK: - NestError

enum NestError: Error {
    case notFound(itemId: String?,message: String?)
    case unknown(json: JSONDicType)
}


