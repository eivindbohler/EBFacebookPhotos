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
//  EBAppDelegate.m
//  EBFacebookPhotos/Examples/PhotoFetcher
//

#import "EBAppDelegate.h"
#import "EBTableViewController.h"
#import "EBLoginViewController.h"
#import "FacebookSDK.h"
#import "AFNetworkActivityIndicatorManager.h"

NSString *const kSessionStateChangedNotification = @"com.example.PhotoFetcher:SessionStateChangedNotification";
NSString *const kLoginViewControllerIdentifier = @"LoginViewController";
NSString *const kPushAlbumsTableViewControllerIdentifier = @"PushAlbumsTableViewController";
NSString *const kPushPhotosTableViewControllerIdentifier = @"PushPhotosTableViewController";
NSString *const kPushFriendsTableViewControllerIdentifier = @"PushFriendsTableViewController";

@implementation EBAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // If the app is going away, we close the session object; this is a good idea because
    // things may be hanging off the session, that need releasing (completion block, etc.) and
    // other components in the app may be awaiting close notification in order to do cleanup
    [FBSession.activeSession close];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBSession.activeSession handleDidBecomeActive];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    // We need to handle URLs by passing them to FBSession in order for SSO authentication to work.
    return [FBSession.activeSession handleOpenURL:url];
}

#pragma mark - Public methods

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
    NSArray *permissions = @[@"user_photos", @"friends_photos"];
    return [FBSession openActiveSessionWithReadPermissions:permissions
                                              allowLoginUI:allowLoginUI
                                         completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                             [self sessionStateChanged:session state:state error:error];
                                         }];
}

- (void)checkSession
{
    if (!FBSession.activeSession.isOpen) {
        if (![self openSessionWithAllowLoginUI:NO]) {
            // No? Display the login page.
            [self showLoginViewControllerAnimated:NO];
        }
    }
}

#pragma mark - Private methods

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState)state
                      error:(NSError *)error
{
    // FBSample logic
    // Any time the session is closed, we want to display the login controller (the user
    // cannot use the application unless they are logged in to Facebook). When the session
    // is opened successfully, hide the login controller and show the main UI.
    switch (state) {
        case FBSessionStateOpen: {
            if (_loginViewController != nil) {
                [_rootTableViewController dismissViewControllerAnimated:YES completion:nil];
                _loginViewController = nil;
            }

//            // FBSample logic
//            // Pre-fetch and cache the friends for the friend picker as soon as possible to improve
//            // responsiveness when the user tags their friends.
//            FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
//            [cacheDescriptor prefetchAndCacheForSession:session];
            break;
        }
        case FBSessionStateClosed: {
            // FBSample logic
            // Once the user has logged out, we want them to be looking at the root view.
            if (_loginViewController != nil) {
                [_rootTableViewController dismissViewControllerAnimated:YES completion:nil];
            }
            [_rootTableViewController.navigationController popToRootViewControllerAnimated:NO];

            [FBSession.activeSession closeAndClearTokenInformation];

            [self performSelector:@selector(showLoginViewControllerAnimated:)
                       withObject:self
                       afterDelay:0.5];
            break;
        }
        case FBSessionStateClosedLoginFailed: {
            // if the token goes invalid we want to switch right back to
            // the login view, however we do it with a slight delay in order to
            // account for a race between this and the login view dissappearing
            // a moment before
            [self performSelector:@selector(showLoginViewControllerAnimated:)
                       withObject:self
                       afterDelay:0.5];
            break;
        }
        default:
            break;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kSessionStateChangedNotification
                                                        object:session];

    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Error: %@",
                                                                     [EBAppDelegate FBErrorCodeDescription:error.code]]
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)showLoginViewControllerAnimated:(BOOL)animated
{
    if (_loginViewController == nil) {
        _loginViewController = [_rootTableViewController.storyboard instantiateViewControllerWithIdentifier:kLoginViewControllerIdentifier];
        [_rootTableViewController presentViewController:_loginViewController animated:animated completion:nil];

    }
}

+ (NSString *)FBErrorCodeDescription:(FBErrorCode)code
{
    switch (code) {
        case FBErrorInvalid:
            return @"FBErrorInvalid";
        case FBErrorOperationCancelled:
            return @"FBErrorOperationCancelled";
        case FBErrorLoginFailedOrCancelled:
            return @"FBErrorLoginFailedOrCancelled";
        case FBErrorRequestConnectionApi:
            return @"FBErrorRequestConnectionApi";
        case FBErrorProtocolMismatch:
            return @"FBErrorProtocolMismatch";
        case FBErrorHTTPError:
            return @"FBErrorHTTPError";
        case FBErrorNonTextMimeTypeReturned:
            return @"FBErrorNonTextMimeTypeReturned";
        case FBErrorNativeDialog:
            return @"FBErrorNativeDialog";
        default:
            return @"[Unknown]";
    }
}

@end
