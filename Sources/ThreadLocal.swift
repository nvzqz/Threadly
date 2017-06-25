//
//  ThreadLocal.swift
//  Threadly
//
//  The MIT License (MIT)
//
//  Copyright (c) 2017 Nikolai Vazquez
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

private func _create_key() -> pthread_key_t {
    var key = pthread_key_t()
    pthread_key_create(&key) {
        // Cast required because argument is optional on some platforms (Linux) but not on others (macOS).
        guard let rawPointer = ($0 as UnsafeMutableRawPointer?) else {
            return
        }
        Unmanaged<AnyObject>.fromOpaque(rawPointer).release()
    }
    return key
}

private func _boxed<T>(for key: pthread_key_t, create: () throws -> T) rethrows -> Box<T> {
    let unmanaged: Unmanaged<Box<T>>
    if let pointer = pthread_getspecific(key) {
        unmanaged = Unmanaged.fromOpaque(pointer)
    } else {
        unmanaged = Unmanaged.passRetained(Box(try create()))
        pthread_setspecific(key, unmanaged.toOpaque())
    }
    return unmanaged.takeUnretainedValue()
}

/// A type that takes an initializer to create and then store a value that's
/// unique to the current thread. The initializer is called the first time
/// the thread-local is accessed, either through `inner` or `withValue(_:)`.
///
/// - note: If the initial value isn't known until retrieval, use `DeferredThreadLocal`.
public final class ThreadLocal<Value>: Hashable {

    fileprivate var _key: pthread_key_t

    private var _create: () -> Value

    /// The hash value.
    public var hashValue: Int {
        return _key.hashValue
    }

    /// Returns the inner boxed value for the current thread.
    public var inner: Box<Value> {
        return _boxed(for: _key, create: _create)
    }

    /// Creates an instance that will use `value` captured in its current
    /// state for an initial value.
    ///
    /// Sometimes this is what you want such as in cases where `value` is
    /// the result of an expensive operation or a copy-on-write type like
    /// `Array` or `Dictionary`.
    public convenience init(capturing value: Value) {
        self.init { [value] in
            value
        }
    }

    /// Creates an instance that will use `value` for an initial value.
    public convenience init(value: @escaping @autoclosure () -> Value) {
        self.init(create: value)
    }

    /// Creates an instance that will use `create` to generate an initial value.
    public init(create: @escaping () -> Value) {
        _create = create
        _key = _create_key()
    }

    deinit {
        pthread_key_delete(_key)
    }

    /// Returns the result of the closure performed on the value of `self`.
    public func withValue<T>(_ body: (inout Value) throws -> T) rethrows -> T {
        return try body(&inner.value)
    }

}

/// A type that stores a value unique to the current thread. An initial value
/// isn't provided until the inner thread-local value is accessed.
///
/// - note: If the initial value is known at the time of initialization of the
///         enclosing type, consider using `ThreadLocal` instead.
public final class DeferredThreadLocal<Value>: Hashable {

    fileprivate var _key: pthread_key_t

    /// The hash value.
    public var hashValue: Int {
        return _key.hashValue
    }

    /// Returns the inner boxed value for the current thread if it's been
    /// created, or `nil` otherwise.
    public var inner: Box<Value>? {
        guard let pointer = pthread_getspecific(_key) else {
            return nil
        }
        return Unmanaged<Box<Value>>.fromOpaque(pointer).takeUnretainedValue()
    }

    /// Creates an instance.
    public init() {
        _key = _create_key()
    }

    deinit {
        pthread_key_delete(_key)
    }

    /// Returns the inner boxed value for the current thread,
    /// created with `create` if not previously initialized.
    public func inner(createdWith create: () throws -> Value) rethrows -> Box<Value> {
        return try _boxed(for: _key, create: create)
    }

    /// Returns the result of the closure performed on the inner thread-local
    /// value of `self`, or `nil` if uninitialized.
    public func withValue<T>(_ body: (inout Value) throws -> T) rethrows -> T? {
        return try inner.map { try body(&$0.value) }
    }

    /// Returns the result of the closure performed on the inner thread-local
    /// value of `self`, created with `create` if not previously initialized.
    public func withValue<T>(createdWith create: () throws -> Value, _ body: (inout Value) throws -> T) rethrows -> T {
        return try body(&inner(createdWith: create).value)
    }

}

/// A type that has a static thread-local instance.
public protocol ThreadLocalRetrievable {
    /// The thread-local instance of `Self`.
    static var threadLocal: ThreadLocal<Self> { get }
}

extension ThreadLocalRetrievable {
    /// Returns the result of performing the closure on the thread-local instance of `Self`.
    public static func withThreadLocal<T>(_ body: (inout Self) throws -> T) rethrows -> T {
        return try body(&threadLocal.inner.value)
    }
}

/// Returns a Boolean value that indicates whether the two arguments have equal values.
public func ==<T>(lhs: ThreadLocal<T>, rhs: ThreadLocal<T>) -> Bool {
    return lhs._key == rhs._key
}

/// Returns a Boolean value that indicates whether the two arguments have equal values.
public func ==<T>(lhs: DeferredThreadLocal<T>, rhs: DeferredThreadLocal<T>) -> Bool {
    return lhs._key == rhs._key
}
