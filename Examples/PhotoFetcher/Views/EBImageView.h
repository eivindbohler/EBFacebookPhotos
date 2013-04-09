// Copyright (c) 2012 Eivind R. Bohler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//  EBImageView.h
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import <UIKit/UIKit.h>

@interface EBImageView : UIImageView

/**
 Set this property to YES if you want to NSLog HTTP requests
 */
@property (assign, nonatomic) BOOL logRequests;

/**
 Returns YES if this instance of EBImageView has already loaded (and cached)
 an image with this url.
 */
- (BOOL)isImageWithURLNew:(NSURL *)url;

/**
 Sets a placeholder image directly
 */
- (void)setPlaceholderImage:(UIImage *)placeholderImage;

/**
 Checks if an image with the provided url is already cached to disk and loads
 it directly if this is the case. If not, starts an async request via
 AFNetworking to fetch the image and if successful, caches and loads it.
 In any case, a callback is triggered indicating whether loading was successful
 or not, and if the load was from disk (cachedImage).
 */
- (void)setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
                success:(void (^)(BOOL cachedImage))success
                failure:(void (^)(void))failure;

@end
