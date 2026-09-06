#import <UIKit/UIKit.h>
#import "FLEXColorStore.h"

@interface FLEXBuildSmoke : NSObject
@end
@implementation FLEXBuildSmoke
+ (void)load {
    Class c = NSClassFromString(@"FLEXColorStore");
    if (!c) return;
    (void)[c sharedStore];
    (void)[UIColor labelColor];
}
@end
