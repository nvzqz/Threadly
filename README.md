[![Threadly](https://github.com/nvzqz/Threadly/raw/assets/banner.png)](https://github.com/nvzqz/Threadly)

Threadly is a Swift µframework that allows for type-safe thread-local storage.

## What is Thread-Local Storage?

[Thread-local storage (TLS)](https://en.wikipedia.org/wiki/Thread-local_storage)
lets you define a single variable that each thread has its own separate copy of.
This is great for cases such as having a mutable global variable that can't be
safely accessed by multiple threads.

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

    pod 'Threadly', '~> 1.0.0'
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
