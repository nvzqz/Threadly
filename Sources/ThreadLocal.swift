//
//  ThreadLocal.swift
//  ThreadLocal
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

/// A type that allows for storing a value that's unique to the current thread.
public final class ThreadLocal<Value> {

    fileprivate var _key: pthread_key_t

    private var _create: () -> Value

    /// Returns the inner boxed value for the current thread.
    public var inner: Box<Value> {
        let unmanaged: Unmanaged<Box<Value>>
        if let pointer = pthread_getspecific(_key) {
            unmanaged = Unmanaged.fromOpaque(pointer)
        } else {
            unmanaged = Unmanaged.passRetained(Box(_create()))
            pthread_setspecific(_key, unmanaged.toOpaque())
        }
        return unmanaged.takeRetainedValue()
    }

    /// Creates an instance that will use `value` for an initial value.
    public convenience init(value: @escaping @autoclosure () -> Value) {
        self.init(create: value)
    }

    /// Creates an instance that will use `create` to generate an initial value.
    public init(create: @escaping () -> Value) {
        _create = create
        _key = pthread_key_t()
        pthread_key_create(&_key) {
            // Cast required because argument is optional on some platforms (Linux) but not on others (macOS).
            guard let rawPointer = ($0 as UnsafeMutableRawPointer?) else {
                return
            }
            Unmanaged<AnyObject>.fromOpaque(rawPointer).release()
        }
    }

    deinit {
        pthread_key_delete(_key)
    }

}
