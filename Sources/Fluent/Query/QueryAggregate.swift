import CodableKit
import Async

public struct QueryAggregate {
    public var field: QueryField?
    public var method: QueryAggregateMethod
}

/// Possible aggregation types.
public enum QueryAggregateMethod {
    case count
    case sum
    case average
    case min
    case max
    case custom(string: String)
}

extension QueryBuilder {
    /// Get the number of results for this query.
    /// Optionally specify a specific field to count.
    public func count() -> Future<Int> {
        let aggregate = QueryAggregate(field: nil, method: .count)
        return self.aggregate(aggregate)
    }

    /// Returns the sum of the supplied field
    public func sum<T>(_ field: KeyPath<Model, T>) -> Future<Double>
        where T: KeyStringDecodable
    {
        return aggregate(.sum, field: field)
    }

    /// Returns the average of the supplied field
    public func average<T>(_ field: KeyPath<Model, T>) -> Future<Double>
        where T: KeyStringDecodable
    {
        return aggregate(.average, field: field)
    }

    /// Returns the min of the supplied field
    public func min<T>(_ field: KeyPath<Model, T>) -> Future<Double>
        where T: KeyStringDecodable
    {
        return aggregate(.min, field: field)
    }

    /// Returns the max of the supplied field
    public func max<T>(_ field: KeyPath<Model, T>) -> Future<Double>
        where T: KeyStringDecodable
    {
        return aggregate(.max, field: field)
    }

    /// Perform an aggregate action on the supplied field
    /// on the supplied model.
    /// Decode as the supplied type.
    public func aggregate<D, T>(_ method: QueryAggregateMethod, field: KeyPath<Model, T>, as type: D.Type = D.self) -> Future<D>
        where D: Decodable, T: KeyStringDecodable
    {
        let aggregate = QueryAggregate(field: field.makeQueryField(), method: method)
        return self.aggregate(aggregate)
    }

    /// Performs the supplied aggregate struct.
    public func aggregate<D: Decodable>(
        _ aggregate: QueryAggregate,
        as type: D.Type = D.self
    ) -> Future<D> {
        let promise = Promise(D.self)

        query.action = .read
        query.aggregates.append(aggregate)
        
        var result: D? = nil

        let stream = run(decoding: AggregateResult<D>.self)

        stream.drain { res in
            result = res.fluentAggregate
        }.catch { err in
            promise.fail(err)
        }.finally {
            if let result = result {
                promise.complete(result)
            } else {
                promise.fail(FluentError(identifier: "aggregate", reason: "The driver closed successfully without a result", source: .capture()))
            }
        }

        return stream.prepare().flatMap(to: D.self) {
            return promise.future
        }
    }
}

/// Aggreagate result structure expected from DB.
internal struct AggregateResult<D: Decodable>: Decodable {
    var fluentAggregate: D
}
