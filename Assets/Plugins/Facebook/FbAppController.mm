//#import <Foundation/Foundation.h>
#import "UnityAppController.h"
//#import "UI/UnityView.h"
//#import "UI/UnityViewControllerBase.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "SUCache.h"
//#import <UIKit/UIKit.h>


@interface FbAppController : UnityAppController
    
+ (void)Login;
    
@end

IMPL_APP_CONTROLLER_SUBCLASS (FbAppController)


@implementation FbAppController
    
    static id _s;
    
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    _s = self;
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:bundlePath];
    NSString *appID = [infoDict objectForKey:@"FacebookAppID"];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    [FBSDKSettings setAppID:appID];
    return YES;
    
}
    
    
    
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];
    [FBSDKAppEvents activateApp];
}
    
    
//- (BOOL)application:(UIApplication *)application
//            openURL:(NSURL *)url
//  sourceApplication:(NSString *)sourceApplication
//         annotation:(id)annotation {
//    return [[FBSDKApplicationDelegate sharedInstance] application:application
//                                                          openURL:url
//                                                sourceApplication:sourceApplication
//                                                       annotation:annotation];
//}
    
    
    //自定义login button的点击事件
+ (void) Login
    {
        //注册事件
        [[NSNotificationCenter defaultCenter] addObserver:_s
                                                 selector:@selector(_updateContent:)
                                                     name:FBSDKProfileDidChangeNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:_s
                                                 selector:@selector(_accessTokenChanged:)
                                                     name:FBSDKAccessTokenDidChangeNotification
                                                   object:nil];
        
        SUCacheItem *item = [SUCache itemForSlot:0];
        NSInteger s = 0;
        if (item.profile)
        {
            SUCacheItem *cacheItem = [SUCache itemForSlot:s];
            cacheItem.profile = item.profile;
            [SUCache saveItem:cacheItem slot:s];
            
        }
        
        NSInteger slot = 0;
        FBSDKAccessToken *token = [SUCache itemForSlot:slot].token;
        if (token)
        {
            [_s autoLoginWithToken:token];
        }
        else
        {
            [_s newLogin];
        }
    }
    
    
- (void)autoLoginWithToken:(FBSDKAccessToken *)token
    {
        [FBSDKAccessToken setCurrentAccessToken:token];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error)
         {
             //token过期，删除存储的token和profile
             if (error)
             {
                 NSLog(@"The user token is no longer valid.");
                 NSInteger slot = 0;
                 [SUCache deleteItemInSlot:slot];
                 [FBSDKAccessToken setCurrentAccessToken:nil];
                 [FBSDKProfile setCurrentProfile:nil];
                 
                 [self newLogin];
             }
             //做登录完成的操作
             else
             {
                 //NSString *jsonStr = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
                 // NSLog(@"json data:%s",[jsonStr UTF8String]);
                 //UnitySendMessage("SDKMgr","IOSGameFacebookVerifySuccess",[jsonStr UTF8String]);
                 
                 NSLog(@"Logged in");
                 [self mcType: @"0"
                    userToken: token.tokenString
                      usuerID: token.userID];
             }
         }];
    }
    
- (void)newLogin
    {
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
        [login
         logInWithReadPermissions: @[@"public_profile"]
         fromViewController:_rootController
         handler:^(FBSDKLoginManagerLoginResult *result, NSError *error)
         {
             NSLog(@"facebook login result.grantedPermissions = %@,error = %@",result.grantedPermissions,error);
             if (error)
             {
                 NSLog(@"Process error");
             }
             else if (result.isCancelled)
             {
                 NSLog(@"Cancelled");
             }
             else
             {
                 NSLog(@"Logged in");
                 [self mcType: @"0"
                    userToken: result.token.tokenString
                      usuerID: result.token.userID];
             }
         }];
    }
    
    
- (void)_updateContent:(NSNotification *)notification
    {
        FBSDKProfile *profile = notification.userInfo[FBSDKProfileChangeNewKey];
        
        NSInteger slot = 0;
        if (profile)
        {
            SUCacheItem *cacheItem = [SUCache itemForSlot:slot];
            cacheItem.profile = profile;
            [SUCache saveItem:cacheItem slot:slot];
            
        }
    }
    
- (void)_accessTokenChanged:(NSNotification *)notification
    {
        FBSDKAccessToken *token = notification.userInfo[FBSDKAccessTokenChangeNewKey];
        if (!token)
        {
            [FBSDKAccessToken setCurrentAccessToken:nil];
            [FBSDKProfile setCurrentProfile:nil];
        }
        else
        {
            NSInteger slot = 0;
            SUCacheItem *item = [SUCache itemForSlot:slot] ?: [[SUCacheItem alloc] init];
            if (![item.token isEqualToAccessToken:token])
            {
                item.token = token;
                [SUCache saveItem:item slot:slot];
            }
        }
    }
    
    
- (void)mcType: (NSString*) type
     userToken: (NSString*) token
       usuerID: (NSString*) id
    {
        NSString *result = [NSString stringWithFormat:@"%@|%@|%@",type,token,id];
        
        NSLog(@"Send back to Unity %@",result);
        
        UnitySendMessage("SDKMgr","LoginCallBack",[result UTF8String]);
    }
    
    
    
    extern "C"  void CallFromUnity_FacebookUserLogin()
    {
        NSLog(@"CallFromUnity_FacebookUserLogin.");
        [FbAppController Login];
    }
    
    @end
