import Quick
import Spry

@testable import NRequest

public final
class FakeKeyedStorage<Value>: Storages.Keyed<Value>, Spryable {
    public enum ClassFunction: String, StringRepresentable {
        case empty
    }

    public enum Function: String, StringRepresentable {
        case value
        case remove = "remove()"
    }

    convenience init() {
        self.init(storage: FakeStorage().toAny(), key: "key")
    }

    public override var value: Value? {
        get {
            return stubbedValue()
        }
        set {
            recordCall(arguments: newValue)
        }
    }

    public override func remove() {
        return spryify()
    }
}
