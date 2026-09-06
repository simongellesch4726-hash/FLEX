#import <UIKit/UIKit.h>
#import "../Classes/Manager/FLEXManager.h"

static void FLEXInstallThreeFingerGesture(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        static BOOL installed = NO;
        if (installed) return;
        installed = YES;

        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if ([window isKindOfClass:NSClassFromString(@"FLEXWindow")]) continue;
            if ([window viewWithTag:0x464C4558]) continue;

            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[FLEXGestureTarget sharedTarget] action:@selector(handleThreeFinger:)];
            tap.numberOfTouchesRequired = 3;
            tap.numberOfTapsRequired = 1;
            tap.cancelsTouchesInView = NO;
            [window addGestureRecognizer:tap];
        }
    });
}

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
    if (gesture.state != UIGestureRecognizerStateRecognized) return;
    [[FLEXManager sharedManager] toggleExplorer];
}
@end

%ctor {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            FLEXInstallThreeFingerGesture();
            [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeVisibleNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                FLEXInstallThreeFingerGesture();
            }];
        });
    }
}
