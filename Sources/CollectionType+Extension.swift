extension Collection {
    func find(predicate: (Generator.Element) throws -> Bool) rethrows -> Generator.Element? {
        return try self.index(where: predicate).flatMap { self[$0] }
    }
}

extension Collection where Indices.Iterator.Element == Index {
    subscript(safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
