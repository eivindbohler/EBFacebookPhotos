//
// Copyright (c) 2012 Eivind R. Bohler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//  EBImageView.m
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import "EBImageView.h"
#import "UIImageView+AFNetworking.h"
#import "EBAppDelegate.h"

@interface EBImageView ()

@property (copy, nonatomic, readonly) NSString *filePath;

@end

@implementation EBImageView

#pragma mark - NSObject

- (void)dealloc
{
    [self cancelImageRequestOperation];
}

#pragma mark - Public methods

- (BOOL)isImageWithURLNew:(NSString *)url
{
    if (!self.image) {
        return YES;
    }
    if ([[self cachedPNGFilePathForURL:url] isEqualToString:_filePath]) {
        return NO;
    }
    return YES;
}

- (void)setImageWithURL:(NSString *)url
       placeholderImage:(UIImage *)placeholderImage
                success:(void (^)(BOOL usedCachedImage))success
                failure:(void (^)(void))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _filePath = [self cachedPNGFilePathForURL:url];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
            UIImage *image = [UIImage imageWithContentsOfFile:_filePath];
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.image = image;
                if (self.image) {
                    success(YES);
                } else {
                    failure();
                }
            });
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.image = nil;
            });
            NSString *filePath = [_filePath copy];
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            [self setImageWithURLRequest:urlRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                self.image = image;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSError *error = nil;
                    [UIImagePNGRepresentation(image) writeToFile:filePath options:NSDataWritingAtomic error:&error];
                    if (error) {
                        NSLog(@"error: %@", error.localizedDescription);
                    }
                });
                success(NO);
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                failure();
            }];
        }
    });
}

#pragma mark - Private methods

- (NSString *)cachedPNGFilePathForURL:(NSString *)url
{
    NSString *fileName = [url lastPathComponent];
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *pathExtension = [fileName pathExtension];
    NSRange extensionRange = [fileName rangeOfString:pathExtension];
    NSString *newFileName = [fileName stringByReplacingCharactersInRange:extensionRange withString:@"png"];
    NSString *newFilePath = [cachePath stringByAppendingPathComponent:newFileName];
    return newFilePath;
}

@end
