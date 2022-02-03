import Base "mo:base/Buffer";

module {
    public class Buffer<T>(initCapacity : Nat) {
        private var base = Base.Buffer<T>(initCapacity);

        // Returns the wrapped mo:base/Buffer.
        public func buffer() : Base.Buffer<T> { base };

        // Expose base functionality.
        public func add(e : T) { base.add(e) };
        public func removeLast() : ?T { base.removeLast() };
        public func append(b : Buffer<T>) { base.append(b.buffer()) };
        public func size() : Nat { base.size() };
        public func clear() { base.clear() };
        public func vals() : { next : () -> ?T } { base.vals() };
        public func toArray() : [T] { base.toArray() };
        public func toVarArray() : [var T] { base.toVarArray() };
        public func get(i : Nat) : T { base.get(i) };
        public func getOpt(i : Nat) : ?T { base.getOpt(i) };
        public func put(i : Nat, e : T) { base.put(i, e) };

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

        public func filterSelf(
            f  : T -> Bool,
            // if (f(t)) g(t);
            g : (b : Bool, t : T) -> ()
        ) {
            let xs = Base.Buffer<T>(size());
            for (x in vals()) {
                let t = f(x);
                if (t) xs.add(x);
                g(t, x);
            };
            base := xs;
        };
    };
};
