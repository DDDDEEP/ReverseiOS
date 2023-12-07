# ReverseiOS

A Xcode project for building a custom framework with cocoapods, and injecting it into decrypting IPA.

## Usage

1. Put your decrypting .ipa into `app/` folder.
2. Execute `bunlde install` and `bundle exec pod install`.
3. Open .workspace, build and run.

(PS: The `tool/insert_dylib`, built from this [project](https://github.com/aik002/insert_dylib), is only compatible with Apple's silicon chips.)
