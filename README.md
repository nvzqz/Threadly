[![Threadly](https://github.com/nvzqz/Threadly/raw/assets/banner.png)](https://github.com/nvzqz/Threadly)

<p align="center">
<img src="https://img.shields.io/badge/platform-ios%20%7C%20macos%20%7C%20watchos%20%7C%20tvos%20%7C%20linux-lightgrey.svg" alt="Platform">
<img src="https://img.shields.io/badge/language-swift-orange.svg" alt="Language: Swift">
<a href="https://cocoapods.org/pods/Threadly"><img src="https://img.shields.io/cocoapods/v/Threadly.svg" alt="CocoaPods - Threadly"></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage"></a>
<img src="https://img.shields.io/cocoapods/dt/Threadly.svg" alt="downloads">
<a href="https://codebeat.co/projects/github-com-nvzqz-threadly-master"><img src="https://codebeat.co/badges/5959731f-3832-4dbd-8c68-755a6071622b" alt="codebeat badge"></a>
<img src="https://img.shields.io/badge/license-MIT-000000.svg" alt="License">
</p>

Threadly is a Swift µframework that allows for type-safe thread-local storage.

## What is [Thread-Local Storage](https://en.wikipedia.org/wiki/Thread-local_storage)?

_Thread-local storage_ (TLS) lets you define a single variable that each thread
has its own separate copy of. This is great for cases such as having a mutable
global variable that can't be safely accessed by multiple threads.

One example of this is with random number generators. Each thread can have its
own seeded generator that's mutated on a per-thread basis. While this may
potentially use more memory, it's much faster than accessing a shared global
variable through a mutex.

## Installation

### Compatibility

- Platforms:
    - macOS 10.9+
    - iOS 8.0+
    - watchOS 2.0+
    - tvOS 9.0+
    - Linux
- Xcode 8.0+
- Swift 3.0+

### Install Using Swift Package Manager
The [Swift Package Manager](https://swift.org/package-manager/) is a
decentralized dependency manager for Swift.

1. Add the project to your `Package.swift`.

    ```swift
    import PackageDescription

    let package = Package(
        name: "MyAwesomeProject",
        dependencies: [
            .Package(url: "https://github.com/nvzqz/Threadly.git",
                     majorVersion: 1)
        ]
    )
    ```

2. Import the Threadly module.

    ```swift
    import Threadly
    ```

### Install Using CocoaPods
[CocoaPods](https://cocoapods.org/) is a centralized dependency manager for
Objective-C and Swift. Go [here](https://guides.cocoapods.org/using/index.html)
to learn more.

1. Add the project to your [Podfile](https://guides.cocoapods.org/using/the-podfile.html).

    ```ruby
    use_frameworks!

    pod 'Threadly', '~> 1.2.0'
    ```

    If you want to be on the bleeding edge, replace the last line with:

    ```ruby
    pod 'Threadly', :git => 'https://github.com/nvzqz/Threadly.git'
    ```

2. Run `pod install` and open the `.xcworkspace` file to launch Xcode.

3. Import the Threadly framework.

    ```swift
    import Threadly
    ```

### Install Using Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency
manager for Objective-C and Swift.

1. Add the project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

    ```
    github "nvzqz/Threadly"
    ```

2. Run `carthage update` and follow [the additional steps](https://github.com/Carthage/Carthage#getting-started)
   in order to add Threadly to your project.

3. Import the Threadly framework.

    ```swift
    import Threadly
    ```

### Install Manually

Simply add `ThreadLocal.swift` and `Box.swift` into your project.

## Usage

Try it out for yourself! Download the repo and open 'Threadly.playground'.

### Initialization

There are two ways to initialize a thread-local value. The value can be
initialized lazily when retrieved (`init(value:)` & `init(create:)`) or at the
call site (`init(capturing:)`).

Using `init(value:)` is an `@autoclosure` shorthand for `init(create:)`. This
means that the thread-local value is initialized once per thread.

```swift
import Foundation

let array = ThreadLocal(value: [1, 2, 3])

Thread.detachNewThread {
    // Allocates an array with 3 elements for this thread
    let arr = array.inner.value
    doStuff(with: arr)
}

// Allocates another array of 3 elements for the main thread
doStuff(with: array.inner.value)
```

When using `init(capturing:)`, the thread-local value is initialized at the call
site.

```swift
import Foundation

// The inner value gets allocated
let array = ThreadLocal(capturing: [1, 2, 3])

Thread.detachNewThread {
    // Retrieves a shallow copy of the initial value that can be used in this
    // thread. If the thread-local value gets mutated, a deep copy occurs to
    // retain value semantics.
    let arr = array.inner.value
    doStuff(with: arr)
}

// Same as the other thread, but now in the main thread
doStuff(with: array.inner.value)
```

### Exclusivity

Each thread has exclusive access to its own local variable.

```swift
import Foundation

let num = ThreadLocal(value: 42)

Thread.detachNewThread {
    withUnsafePointer(to: &num.inner.value) { ptr in
        print(ptr) // 0x00007fa6f86074a0
    }
}

withUnsafePointer(to: &num.inner.value) { ptr in
    print(ptr) // 0x00007fa6f844c920
}
```
