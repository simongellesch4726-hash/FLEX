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
        NSInteger siblingIndex = candidate.superview
            ? [candidate.superview.subviews indexOfObjectIdenticalTo:candidate]
            : 0;
        NSString *accessibility = candidate.accessibilityIdentifier.length
            ? candidate.accessibilityIdentifier
            : @"-";
        [components addObject:[NSString stringWithFormat:@"%@[%ld](%@)",
            NSStringFromClass(candidate.class), (long)siblingIndex, accessibility]];
    }

    [components addObject:target.length ? target : @"default"];
    return [components componentsJoinedByString:@"/"];
}

- (void)setColor:(UIColor *)color forView:(UIView *)view target:(NSString *)target {
    if (!view || !color) return;

    UIColor *resolved = color;
    if (@available(iOS 13.0, *)) {
        resolved = [color resolvedColorWithTraitCollection:view.traitCollection];
    }

    CGFloat r = 0, g = 0, b = 0, a = 1, w = 0;
    BOOL rgb = [resolved getRed:&r green:&g blue:&b alpha:&a];
    if (!rgb) {
        BOOL white = [resolved getWhite:&w alpha:&a];
        if (!white) return;
        r = g = b = w;
    }

    NSString *identifier = [self identifierForView:view target:target];
    self.entries[identifier] = @{
        @"r": @(r),
        @"g": @(g),
        @"b": @(b),
        @"a": @(a)
    };
    [[NSUserDefaults standardUserDefaults] setObject:self.entries forKey:kFLEXColorStoreDefaultsKey];
}

- (UIColor *)colorForView:(UIView *)view target:(NSString *)target {
    NSDictionary *entry = self.entries[[self identifierForView:view target:target]];
    if (!entry) return nil;

    NSNumber *r = entry[@"r"];
    NSNumber *g = entry[@"g"];
    NSNumber *b = entry[@"b"];
    NSNumber *a = entry[@"a"];
    if (![r isKindOfClass:NSNumber.class] ||
        ![g isKindOfClass:NSNumber.class] ||
        ![b isKindOfClass:NSNumber.class] ||
        ![a isKindOfClass:NSNumber.class]) {
        return nil;
    }

    return [UIColor colorWithRed:r.doubleValue
                           green:g.doubleValue
                            blue:b.doubleValue
                           alpha:a.doubleValue];
}

- (void)resetColors {
    [self.entries removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFLEXColorStoreDefaultsKey];
}

@end
