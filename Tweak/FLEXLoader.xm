#import <UIKit/UIKit.h>
#import "../Classes/Manager/FLEXManager.h"
#import "FLEXColorStore.h"

@interface FLEXGestureTarget : NSObject
+ (instancetype)sharedTarget;
- (void)handleThreeFinger:(UITapGestureRecognizer *)gesture;
@end

@implementation FLEXGestureTarget

+ (instancetype)sharedTarget {
    static FLEXGestureTarget *target;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ target = [self new]; });
    return target;
}

- (void)handleThreeFinger:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        [[FLEXManager sharedManager] toggleExplorer];
    }
}

@end

static NSArray<UIWindow *> *FLEXApplicationWindows(void) {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState == UISceneActivationStateUnattached) continue;
            [windows addObjectsFromArray:windowScene.windows];
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [windows addObjectsFromArray:UIApplication.sharedApplication.windows];
#pragma clang diagnostic pop
    }
    return windows.copy;
}

static void FLEXApplyStoredColors(void) {
    FLEXColorStore *store = [FLEXColorStore sharedStore];
    for (UIWindow *window in FLEXApplicationWindows()) {
        if ([NSStringFromClass(window.class) hasPrefix:@"FLEX"]) continue;
        [store applyStoredColorsToWindow:window];
    }
}

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        static BOOL observerInstalled = NO;
        FLEXGestureTarget *target = FLEXGestureTarget.sharedTarget;
        void (^install)(void) = ^{
            for (UIWindow *window in FLEXApplicationWindows()) {
                if ([NSStringFromClass(window.class) hasPrefix:@"FLEX"]) continue;
                BOOL exists = NO;
                for (UIGestureRecognizer *recognizer in window.gestureRecognizers) {
                    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]] &&
                        recognizer.numberOfTouchesRequired == 3 &&
                        recognizer.numberOfTapsRequired == 1) {
                        exists = YES;
                        break;
                    }
                }
                if (!exists) {
                    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(handleThreeFinger:)];
                    tap.numberOfTouchesRequired = 3;
                    tap.numberOfTapsRequired = 1;
                    tap.cancelsTouchesInView = NO;
                    [window addGestureRecognizer:tap];
                }
                [[FLEXColorStore sharedStore] applyStoredColorsToWindow:window];
            }
        };

        install();

        if (!observerInstalled) {
            observerInstalled = YES;
            NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
            [center addObserverForName:UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                UIWindow *window = note.object;
                if ([window isKindOfClass:[UIWindow class]] && ![NSStringFromClass(window.class) hasPrefix:@"FLEX"]) {
                    [FLEXColorStore.sharedStore applyStoredColorsToWindow:window];
                    install();
                }
            }];
            [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                install();
                FLEXApplyStoredColors();
            }];
        }
    });
}
