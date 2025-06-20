# DocC Migration Guide

This document outlines the migration from Jazzy to Swift's DocC documentation system for the TripKit iOS project.

## What Changed

### Before (Jazzy)
- Used `.jazzy.yaml` configuration file
- Generated HTML documentation using Ruby-based Jazzy tool
- Required external dependencies (Jazzy gem)
- Custom categories and styling through YAML configuration

### After (DocC)
- Uses `.docc` catalog directories within each module
- Native Swift documentation generation using `swift package generate-documentation`
- No external Ruby dependencies
- Documentation authored in Markdown with Swift-specific extensions

## New Structure

### DocC Catalogs
Each module now has its own DocC catalog:

```
Sources/
├── TripKit/
│   └── TripKit.docc/
│       └── TripKit.md
├── TripKitAPI/
│   └── TripKitAPI.docc/
│       └── TripKitAPI.md
├── TripKitUI/
│   └── TripKitUI.docc/
│       └── TripKitUI.md
└── TripKitInterApp/
    └── TripKitInterApp.docc/
        └── TripKitInterApp.md
```

### Generated Documentation
Documentation is now generated to:
- `Scripts/docs/source/TripKit/TripKitAPI/`
- `Scripts/docs/source/TripKit/TripKit/`
- `Scripts/docs/source/TripKit/TripKitUI/`
- `Scripts/docs/source/TripKit/TripKitInterApp/`

## Building Documentation

### Full Build
To build all documentation:
```bash
./Scripts/docs.sh
```

### Individual Module Build
To build documentation for a specific module:
```bash
./Scripts/build-docs-module.sh TripKit
./Scripts/build-docs-module.sh TripKitUI
./Scripts/build-docs-module.sh TripKitAPI
./Scripts/build-docs-module.sh TripKitInterApp
```

### Manual Build
For direct Swift Package Manager usage:
```bash
swift package generate-documentation --target TripKit --output-path Scripts/docs/source/TripKit/TripKit
```

## Benefits of DocC

### 1. Native Swift Integration
- No external dependencies
- Consistent with Apple's documentation ecosystem
- Better integration with Xcode and Swift tooling

### 2. Rich Markdown Support
- Standard Markdown with Swift-specific extensions
- Code syntax highlighting
- Symbol linking with double backticks
- Automatic API reference generation

### 3. Improved Developer Experience
- Documentation appears in Xcode's Quick Help
- Better autocomplete and navigation
- Integrated with Swift Package Manager

### 4. Modern Output Format
- Responsive web interface
- Better mobile experience
- Improved search functionality
- Dark mode support

## Writing Documentation

### Basic Syntax
Use standard Markdown with DocC extensions:

```markdown
# ``ModuleName``

Brief description of the module.

## Overview

Detailed overview of the module's functionality.

## Topics

### Category Name

Brief description of this category.

- ``SymbolName``
- ``AnotherSymbol``

### Another Category

- ``ThirdSymbol``
```

### Linking to Symbols
Use double backticks to link to symbols:
- `` `ClassName` `` - Link to a class
- `` `ClassName/methodName(_:)` `` - Link to a specific method
- `` `ClassName/propertyName` `` - Link to a property

### Code Examples
Include Swift code examples:

```swift
import TripKit

let router = TKRouter()
router.route(from: startLocation, to: endLocation) { result in
    // Handle routing results
}
```

## Adding New Documentation

### 1. Create New Articles
Add new `.md` files to the relevant `.docc` directory:

```
Sources/TripKit/TripKit.docc/
├── TripKit.md
├── GettingStarted.md
└── Advanced.md
```

### 2. Reference in Main Documentation
Add articles to the Topics section:

```markdown
## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:Advanced>
```

### 3. Add Resources
Include images and other resources:

```
Sources/TripKit/TripKit.docc/
├── TripKit.md
└── Resources/
    ├── image.png
    └── diagram.svg
```

## Troubleshooting

### Common Issues

#### Build Failures
If documentation generation fails:

1. Check Swift Package Manager setup:
   ```bash
   swift package resolve
   swift package clean
   ```

2. Verify DocC catalog structure:
   - Ensure each `.docc` directory has a main `.md` file
   - Check that symbol references use correct syntax

3. Validate Markdown syntax:
   - Use proper heading hierarchy
   - Ensure code blocks are properly formatted
   - Check symbol linking syntax

#### Missing Symbols
If symbols don't appear in documentation:

1. Ensure symbols are `public` or `open`
2. Add documentation comments to symbols:
   ```swift
   /// Brief description of the class.
   ///
   /// Detailed description with examples.
   public class MyClass {
       /// Description of the method.
       /// - Parameter value: Description of parameter
       /// - Returns: Description of return value
       public func myMethod(_ value: String) -> Bool {
           // Implementation
       }
   }
   ```

#### Output Directory Issues
If generated documentation doesn't appear:

1. Check output directory permissions
2. Verify the output path exists
3. Ensure the build script has correct paths

### Debugging Tips

1. **Verbose Output**: Add `--verbose` flag to see detailed build information:
   ```bash
   swift package generate-documentation --target TripKit --verbose
   ```

2. **Check Dependencies**: Ensure all dependencies are resolved:
   ```bash
   swift package show-dependencies
   ```

3. **Validate Structure**: Use tree command to verify structure:
   ```bash
   tree Sources/TripKit/TripKit.docc/
   ```

## Migration Checklist

- [x] Created DocC catalogs for each module
- [x] Migrated main documentation content
- [x] Updated build scripts
- [x] Updated mkdocs.yml configuration
- [x] Created helper scripts for individual module builds
- [ ] Migrate custom categories and styling (if needed)
- [ ] Add comprehensive symbol documentation
- [ ] Create tutorial content
- [ ] Set up CI/CD for documentation builds
- [ ] Remove Jazzy dependencies (.jazzy.yaml, Gemfile, etc.)

## Next Steps

1. **Enhanced Documentation**: Add more comprehensive documentation to each module
2. **Tutorials**: Create step-by-step tutorials using DocC's tutorial format
3. **CI Integration**: Set up automated documentation builds in CI/CD pipeline
4. **Cleanup**: Remove Jazzy-related files once migration is complete
5. **Testing**: Thoroughly test documentation generation and deployment

## Resources

- [DocC Documentation](https://developer.apple.com/documentation/docc)
- [Swift Package Manager Documentation](https://swift.org/package-manager/)
- [DocC Tutorial](https://developer.apple.com/tutorials/app-dev-training/documenting-your-code)