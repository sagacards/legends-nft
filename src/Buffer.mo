import Base "mo:base/Buffer";

module {
    public class Buffer<T>(initCapacity : Nat) {
        private let base = Base.Buffer<T>(initCapacity);

        // Returns the wrapped mo:base/Buffer.
        public func buffer() : Base.Buffer<T> = base;

        // Expose base functionality.
        public let add : (e : T) -> () = base.add;
        public let removeLast : () -> ?T = base.removeLast;
        public func append(b : Buffer<T>) = base.append(b.buffer());
        public let size : () -> Nat = base.size;
        public let clear : () -> () = base.clear;
        public let vals : () -> { next : () -> ?T } = base.vals;
        public let toArray : () -> [T] = base.toArray;
        public let toVarArray : () -> [var T] = base.toVarArray;
        public let get : (i : Nat) -> T = base.get;
        public let getOpt : (i : Nat) -> ?T = base.getOpt;
        public let put : (i : Nat, e : T) -> () = base.put;

        public func find(f : T -> Bool) : ?T {
            for (x in vals()) {
                if (f(x)) return ?x;
            };
            return null;
        };

        public func filter(f : T -> Bool) : [T] {
            let xs = Buffer<T>(size());
            for (x in vals()) {
                if (f(x)) xs.add(x);
            };
            xs.toArray();
        };
    };
};
