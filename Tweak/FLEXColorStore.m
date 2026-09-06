#import "FLEXColorStore.h"

static NSString * const kFLEXColorStoreDefaultsKey = @"FLEXColorizerColors";

@interface FLEXColorStore ()
@property (nonatomic) NSMutableDictionary<NSString *, NSDictionary *> *entries;
@end

@implementation FLEXColorStore

+ (instancetype)sharedStore {
    static FLEXColorStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ store = [self new]; });
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
    if (window) [components addObject:NSStringFromClass(window.class)];

    NSMutableArray<UIView *> *ancestors = [NSMutableArray array];
    for (UIView *candidate = view; candidate; candidate = candidate.superview) {
        [ancestors insertObject:candidate atIndex:0];
    }
    for (UIView *candidate in ancestors) {
        NSInteger siblingIndex = candidate.superview ? [candidate.superview.subviews indexOfObjectIdenticalTo:candidate] : 0;
        NSString *accessibility = candidate.accessibilityIdentifier.length ? candidate.accessibilityIdentifier : @"-";
        [components addObject:[NSString stringWithFormat:@"%@[%ld](%@)", NSStringFromClass(candidate.class), (long)siblingIndex, accessibility]];
    }
    [components addObject:target.length ? target : @"default"];
    return [components componentsJoinedByString:@"/"];
}

- (UIColor *)staticColorFromColor:(UIColor *)color forView:(UIView *)view {
    if (!color || !view) return nil;
    if (@available(iOS 13.0, *)) color = [color resolvedColorWithTraitCollection:view.traitCollection];
    CGFloat r = 0, g = 0, b = 0, a = 1, w = 0;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) return [UIColor colorWithRed:r green:g blue:b alpha:a];
    if ([color getWhite:&w alpha:&a]) return [UIColor colorWithWhite:w alpha:a];
    return nil;
}

- (void)setColor:(UIColor *)color forView:(UIView *)view target:(NSString *)target {
    if (!view) return;
    UIColor *resolved = [self staticColorFromColor:color forView:view];
    if (!resolved) return;
    CGFloat r = 0, g = 0, b = 0, a = 1;
    [resolved getRed:&r green:&g blue:&b alpha:&a];
    self.entries[[self identifierForView:view target:target]] = @{@"r":@(r), @"g":@(g), @"b":@(b), @"a":@(a)};
    [[NSUserDefaults standardUserDefaults] setObject:self.entries forKey:kFLEXColorStoreDefaultsKey];
}

- (UIColor *)colorForView:(UIView *)view target:(NSString *)target {
    if (!view) return nil;
    NSDictionary *entry = self.entries[[self identifierForView:view target:target]];
    NSNumber *r = entry[@"r"], *g = entry[@"g"], *b = entry[@"b"], *a = entry[@"a"];
    if (![r isKindOfClass:NSNumber.class] || ![g isKindOfClass:NSNumber.class] || ![b isKindOfClass:NSNumber.class] || ![a isKindOfClass:NSNumber.class]) return nil;
    return [UIColor colorWithRed:r.doubleValue green:g.doubleValue blue:b.doubleValue alpha:a.doubleValue];
}

- (void)applyStoredColorsToView:(UIView *)view {
    if (!view) return;
    UIColor *background = [self colorForView:view target:@"background"];
    if (background) view.backgroundColor = background;
    UIColor *tint = [self colorForView:view target:@"tint"];
    if (tint) view.tintColor = tint;

    if ([view isKindOfClass:[UILabel class]]) {
        UIColor *text = [self colorForView:view target:@"text"];
        if (text) ((UILabel *)view).textColor = text;
    } else if ([view isKindOfClass:[UITextField class]]) {
        UIColor *text = [self colorForView:view target:@"text"];
        if (text) ((UITextField *)view).textColor = text;
    } else if ([view isKindOfClass:[UITextView class]]) {
        UIColor *text = [self colorForView:view target:@"text"];
        if (text) ((UITextView *)view).textColor = text;
    } else if ([view isKindOfClass:[UISwitch class]]) {
        UISwitch *control = (UISwitch *)view;
        UIColor *onTint = [self colorForView:view target:@"onTint"];
        UIColor *thumbTint = [self colorForView:view target:@"thumbTint"];
        if (onTint) control.onTintColor = onTint;
        if (thumbTint) control.thumbTintColor = thumbTint;
    } else if ([view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)view;
        UIColor *minimum = [self colorForView:view target:@"minimumTrack"];
        UIColor *maximum = [self colorForView:view target:@"maximumTrack"];
        UIColor *thumb = [self colorForView:view target:@"thumb"];
        if (minimum) slider.minimumTrackTintColor = minimum;
        if (maximum) slider.maximumTrackTintColor = maximum;
        if (thumb) slider.thumbTintColor = thumb;
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIControlState states[] = { UIControlStateNormal, UIControlStateHighlighted, UIControlStateSelected, UIControlStateDisabled };
        for (NSUInteger i = 0; i < sizeof(states) / sizeof(states[0]); i++) {
            UIControlState state = states[i];
            UIColor *titleColor = [self colorForView:view target:[NSString stringWithFormat:@"title.%lu", (unsigned long)state]];
            if (titleColor) [button setTitleColor:titleColor forState:state];
        }
    }
}

- (void)applyStoredColorsToWindow:(UIWindow *)window {
    if (!window || [NSStringFromClass(window.class) hasPrefix:@"FLEX"]) return;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:window];
    while (stack.count) {
        UIView *view = stack.lastObject;
        [stack removeLastObject];
        [self applyStoredColorsToView:view];
        [stack addObjectsFromArray:view.subviews];
    }
}

- (void)resetColors {
    [self.entries removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kFLEXColorStoreDefaultsKey];
}

@end
