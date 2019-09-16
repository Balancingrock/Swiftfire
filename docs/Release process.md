# Release process

The following steps should be followed to release a new version of Swiftfire.

1. Consolidate the source code changes in the git _master_ branch
1. Clean build products, check flawless build in Xcode and on the command line
1. Update documentation & swiftfire.nl
1. Update the version number in Swiftfire.Core.ServerTelemetry
1. If changes were made in _sfadmin_, then build that site again
1. Run the `sf-jazzy.sh` script, check that the Custom, Functions and Service have 100% coverage
1. Update the readme file
1. Add & Commit & Merge all changes in the git _master_ branch
1. Add the new git tag
1. Push the repository to github
1. Build the swiftfire.nl website
1. rsync the swiftfire.nl website
1. Test clone the githib project, it should build flawless
