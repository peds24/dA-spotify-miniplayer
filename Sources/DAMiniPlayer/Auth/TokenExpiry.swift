import Foundation

enum TokenExpiry {
    static func isExpired(expiresAt: Date, now: Date = Date()) -> Bool {
        now >= expiresAt
    }
}
