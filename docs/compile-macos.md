# Compiling maestro on macOS

This project is written in Swift and uses the Swift Package Manager (SPM).
On macOS you can build it from the command line.

## Prerequisites
- Xcode 15 or later, which includes the Swift toolchain and SPM.
- Alternatively, install the [Swift toolchain](https://swift.org/download/#releases) and ensure `swift` is in your `PATH`.

## Building
Run the following from the repository root:

```bash
# Build debug binaries
swift build

# Or build an optimized release
swift build -c release
```

The compiled executable will be found under `.build/debug/maestro` for debug
or `.build/release/maestro` for release builds.

You can run the server directly using:

```bash
swift run maestro --baseurl http://homeassistant.local:8123/ --token YOUR_TOKEN
swift run maestro --simulate # Print light commands instead of sending them
swift run maestro --verbose  # Print commands while also sending them
```

This command works on macOS because the POSIX server implementation
uses the `Darwin` module.
