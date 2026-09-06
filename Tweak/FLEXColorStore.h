#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLEXColorStore : NSObject
+ (instancetype)sharedStore;
- (void)setColor:(UIColor *)color forView:(UIView *)view target:(NSString *)target;
- (nullable UIColor *)colorForView:(UIView *)view target:(NSString *)target;
- (void)resetColors;
@end

NS_ASSUME_NONNULL_END
