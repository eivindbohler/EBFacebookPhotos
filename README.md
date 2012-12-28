# EBFacebookPhotos
EBFacebookPhotos for iOS is designed to make it easy to fetch photo albums and photos through the Facebook SDK using as few HTTP requests as possible.

## How To Get Started
- [Download EBFacebookPhotos (zipped)](https://github.com/eivindbohler/EBFacebookPhotos/zipball/master) and try out the included iOS example app "PhotoFetcher"

## How To Use
- [Download EBFacebookPhotos (zipped)](https://github.com/eivindbohler/EBFacebookPhotos/zipball/master) or add it as a submodule to your git project:
```
git submodule add https://github.com/eivindbohler/EBFacebookPhotos.git
```
- Drag the folder "EBFacebookPhotos" into your Xcode project
- [Download the Facebook SDK (zipped)](https://github.com/facebook/facebook-ios-sdk/zipball/master) or add it as a submodule to your git project:
```
git submodule add https://github.com/facebook/facebook-ios-sdk.git
```
- [Read the documentation](https://developers.facebook.com/docs/getting-started/getting-started-with-the-ios-sdk) for Facebook SDK setup instructions
- Enjoy!

## Example
``` objective-c
[EBFacebookPhotos albumsForFriends:nil
                  matchingCriteria:@{@"location": @"London"}
                   albumProperties:@[@"cover_photo", @"name", @"photo_count", @"created"]
                   photoProperties:@[@"src"]
                           success:^(NSArray *albums) {
                               [albumsViewController setAlbums:albums];
                           } failure:^(NSError *error) {
                               NSLog(@"Error fetching albums: %@", error);
                           }];

```

## Contact
[Eivind Bohler](http://github.com/eivindbohler)
[@eivindbohler](https://twitter.com/eivindbohler)

## License
EBFacebookPhotos is available under the MIT license. See the LICENSE file for more info.