#import "FLEXColorStore.h"

static NSString * const kFLEXColorStoreDefaultsKey = @"FLEXColorizerColors";

@interface FLEXColorStore ()
@property (nonatomic) NSMutableDictionary<NSString *, NSDictionary *> *entries;
@end

@implementation FLEXColorStore

+ (instancetype)sharedStore {
    static FLEXColorStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [self new];
    });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kFLEXColorStoreDefaultsKey];
        _entries = saved.mutableCopy ?: [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)identifierForView:(UIView *)view target:(NSString *)target {
    NSMutableArray<NSString *> *components = [NSMutableArray array];
    UIWindow *window = view.window;
    if (window) {
        [components addObject:NSStringFromClass(window.class)];
    }

    NSMutableArray<UIView *> *ancestors = [NSMutableArray array];
    for (UIView *candidate = view; candidate; candidate = candidate.superview) {
        [ancestors insertObject:candidate atIndex:0];
    }

    for (UIView *candidate in ancestors) {
        NSInteger siblingIndex = [candidate.superview.subviews indexOfObjectIdenticalTo:candidate];
        NSString *accessibility = candidate.accessibilityIdentifier.length ? candidate.accessibilityIdentifier : @"-";
        [components addObject:[NSString stringWithFormat:@"%@[%ld](%@)", NSStringFromClass(candidate.class), (long)siblingIndex, accessibility]];
    }

    [components addObject:target ?: @"default"];
    return [components componentsJoinedByString:@"/"];
}

- (void)setColor:(UIColor *)color forView:(UIView *)view target:(NSString *)target {
    if (!view || !color) return;
    CGFloat r = 0, g = 0, b = 0, a = 0, w = 0;
    BOOL rgb = [color getRed:&r green:&g blue:&b alpha:&a];
    if (!rgb && [color getWhite:&w alpha:&a]) r = g = b = w;
    if (!rgb && a == 0 && ![color getWhite:&w alpha:&a]) return;

    NSString *identifier = [self identifierForView:view target:target];
    self.entries[identifier] = @{
        @"r": @(r), @"g": @(g), @"b": @(b), @"a": @(a)
    };
    [[NSUserDefaults standardUserDefaults] setObject:self.entries forKey:kFLEXColorStoreDefaultsKey];
}

- (UIColor *)colorForView:(UIView *)view target:(NSString *)target {
    NSDictionary *entry = self.entries[[self identifierForView:view target:target]];
    if (!entry) return nil;
    return [UIColor colorWithRed:[entry[@"r"] doubleValue]
                           green:[entry[@"g"] doubleValue]
                            blue:[entry[@"b"] doubleValue]
                           alpha:[entry[@"a"] doubleValue]];
}

- (void)resetColors {
    [self.entries removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFLEXColorStoreDefaultsKey];
}

@end
