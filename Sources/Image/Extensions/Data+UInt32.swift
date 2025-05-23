import Foundation

extension Data {
    var unsafeUInt32: UInt32 {
        Array(self).withUnsafeBytes { $0.load(as: UInt32.self) }
    }
}
