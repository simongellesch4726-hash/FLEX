#import <UIKit/UIKit.h>
#import "../Classes/Manager/FLEXManager.h"

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

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        static BOOL observerInstalled = NO;
        FLEXGestureTarget *target = FLEXGestureTarget.sharedTarget;
        void (^install)(void) = ^{
            for (UIWindow *window in UIApplication.sharedApplication.windows) {
                if ([NSStringFromClass(window.class) hasPrefix:@"FLEX"]) continue;
                BOOL exists = NO;
                for (UIGestureRecognizer *recognizer in window.gestureRecognizers) {
                    if ([recognizer isKindOfClass:[UITapGestureRecognizer class]] && recognizer.numberOfTouchesRequired == 3 && recognizer.numberOfTapsRequired == 1) {
                        exists = YES;
                        break;
                    }
                }
                if (exists) continue;
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(handleThreeFinger:)];
                tap.numberOfTouchesRequired = 3;
                tap.numberOfTapsRequired = 1;
                tap.cancelsTouchesInView = NO;
                [window addGestureRecognizer:tap];
            }
        };
        install();
        if (!observerInstalled) {
            observerInstalled = YES;
            [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                install();
            }];
        }
    });
}
