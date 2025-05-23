import Foundation

extension Data {
    var unsafeUInt16: UInt16 {
        // Array(self) prevents “misaligned raw pointer” errors
        Array(self).withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}
