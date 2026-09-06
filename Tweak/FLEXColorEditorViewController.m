#import "FLEXColorEditorViewController.h"
#import "FLEXColorStore.h"
#import "../Classes/Editing/ArgumentInputViews/FLEXArgumentInputColorView.h"

@interface FLEXColorTarget : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) UIColor *(^readColor)(void);
@property (nonatomic, copy) void (^writeColor)(UIColor *);
@end
@implementation FLEXColorTarget
@end

@interface FLEXColorEditorViewController ()
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic) NSArray<FLEXColorTarget *> *targets;
@end

@implementation FLEXColorEditorViewController

- (instancetype)initWithView:(UIView *)view {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _targetView = view;
        self.title = @"Color";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    self.tableView.rowHeight = 56.0;
    [self buildTargets];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIColor *)editableColorFromColor:(UIColor *)color fallback:(UIColor *)fallback {
    if (!color) return fallback;
    CGFloat r, g, b, a, w;
    if ([color getRed:&r green:&g blue:&b alpha:&a] || [color getWhite:&w alpha:&a]) return color;
    return fallback;
}

- (void)buildTargets {
    NSMutableArray<FLEXColorTarget *> *targets = [NSMutableArray array];
    UIView *view = self.targetView;
    if (!view) {
        self.targets = @[];
        return;
    }

    __weak typeof(self) weakSelf = self;
    void (^addTarget)(NSString *, NSString *, UIColor *(^)(void), void (^)(UIColor *)) = ^(NSString *name, NSString *identifier, UIColor *(^read)(void), void (^write)(UIColor *)) {
        FLEXColorTarget *target = [FLEXColorTarget new];
        target.name = name;
        target.identifier = identifier;
        target.readColor = read;
        target.writeColor = ^(UIColor *color) {
            write(color);
            [weakSelf persist:color identifier:identifier];
        };
        [targets addObject:target];
    };

    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        addTarget(@"Background", @"background", ^UIColor *{ return button.backgroundColor; }, ^(UIColor *c){ button.backgroundColor = c; });
        addTarget(@"Tint", @"tint", ^UIColor *{ return button.tintColor; }, ^(UIColor *c){ button.tintColor = c; });
        NSArray<NSNumber *> *states = @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected), @(UIControlStateDisabled)];
        for (NSNumber *n in states) {
            UIControlState state = n.unsignedIntegerValue;
            NSString *name = state == UIControlStateNormal ? @"Title (Normal)" :
                state == UIControlStateHighlighted ? @"Title (Highlighted)" :
                state == UIControlStateSelected ? @"Title (Selected)" : @"Title (Disabled)";
            NSString *key = [NSString stringWithFormat:@"title.%lu", (unsigned long)state];
            addTarget(name, key, ^UIColor *{ return [button titleColorForState:state]; }, ^(UIColor *c){ [button setTitleColor:c forState:state]; });
        }
    } else if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        addTarget(@"Text", @"text", ^UIColor *{ return label.textColor; }, ^(UIColor *c){ label.textColor = c; });
        addTarget(@"Background", @"background", ^UIColor *{ return label.backgroundColor; }, ^(UIColor *c){ label.backgroundColor = c; });
    } else if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        addTarget(@"Text", @"text", ^UIColor *{ return field.textColor; }, ^(UIColor *c){ field.textColor = c; });
        addTarget(@"Tint", @"tint", ^UIColor *{ return field.tintColor; }, ^(UIColor *c){ field.tintColor = c; });
        addTarget(@"Background", @"background", ^UIColor *{ return field.backgroundColor; }, ^(UIColor *c){ field.backgroundColor = c; });
    } else if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        addTarget(@"Text", @"text", ^UIColor *{ return textView.textColor; }, ^(UIColor *c){ textView.textColor = c; });
        addTarget(@"Tint", @"tint", ^UIColor *{ return textView.tintColor; }, ^(UIColor *c){ textView.tintColor = c; });
        addTarget(@"Background", @"background", ^UIColor *{ return textView.backgroundColor; }, ^(UIColor *c){ textView.backgroundColor = c; });
    } else if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        addTarget(@"Tint", @"tint", ^UIColor *{ return imageView.tintColor; }, ^(UIColor *c){ imageView.tintColor = c; });
        addTarget(@"Background", @"background", ^UIColor *{ return imageView.backgroundColor; }, ^(UIColor *c){ imageView.backgroundColor = c; });
    } else if ([view isKindOfClass:[UISwitch class]]) {
        UISwitch *control = (UISwitch *)view;
        addTarget(@"On Tint", @"onTint", ^UIColor *{ return control.onTintColor; }, ^(UIColor *c){ control.onTintColor = c; });
        addTarget(@"Thumb Tint", @"thumbTint", ^UIColor *{ return control.thumbTintColor; }, ^(UIColor *c){ control.thumbTintColor = c; });
        addTarget(@"Tint", @"tint", ^UIColor *{ return control.tintColor; }, ^(UIColor *c){ control.tintColor = c; });
    } else if ([view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)view;
        addTarget(@"Minimum Track", @"minimumTrack", ^UIColor *{ return slider.minimumTrackTintColor; }, ^(UIColor *c){ slider.minimumTrackTintColor = c; });
        addTarget(@"Maximum Track", @"maximumTrack", ^UIColor *{ return slider.maximumTrackTintColor; }, ^(UIColor *c){ slider.maximumTrackTintColor = c; });
        addTarget(@"Thumb", @"thumb", ^UIColor *{ return slider.thumbTintColor; }, ^(UIColor *c){ slider.thumbTintColor = c; });
    }

    // Generic UIView target. This intentionally colors the selected view itself,
    // not arbitrary descendants, so composite glyphs are treated as one element.
    if (targets.count == 0 || !view.backgroundColor) {
        addTarget(@"Background", @"background", ^UIColor *{ return view.backgroundColor; }, ^(UIColor *c){ view.backgroundColor = c; });
    } else if (![view isKindOfClass:[UIButton class]] && ![view isKindOfClass:[UILabel class]] && ![view isKindOfClass:[UITextField class]] && ![view isKindOfClass:[UITextView class]] && ![view isKindOfClass:[UIImageView class]] && ![view isKindOfClass:[UISwitch class]] && ![view isKindOfClass:[UISlider class]]) {
        addTarget(@"Background", @"background", ^UIColor *{ return view.backgroundColor; }, ^(UIColor *c){ view.backgroundColor = c; });
        addTarget(@"Tint", @"tint", ^UIColor *{ return view.tintColor; }, ^(UIColor *c){ view.tintColor = c; });
    }

    self.targets = targets;
}

- (void)persist:(UIColor *)color identifier:(NSString *)identifier {
    [[FLEXColorStore sharedStore] setColor:color forView:self.targetView target:identifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.targets.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuse = @"ColorTarget";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuse];
    FLEXColorTarget *target = self.targets[indexPath.row];
    cell.textLabel.text = target.name;
    UIColor *color = target.readColor ? target.readColor() : UIColor.clearColor;
    color = [self editableColorFromColor:color fallback:UIColor.clearColor];
    cell.detailTextLabel.text = [self hexStringForColor:color];
    cell.detailTextLabel.textColor = color;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FLEXColorTarget *target = self.targets[indexPath.row];
    [self presentColorPickerForTarget:target];
}

- (void)presentColorPickerForTarget:(FLEXColorTarget *)target {
    FLEXArgumentInputColorView *picker = [[FLEXArgumentInputColorView alloc] initWithArgumentTypeEncoding:@encode(UIColor *)];
    UIColor *current = target.readColor ? target.readColor() : UIColor.clearColor;
    picker.inputValue = current ?: UIColor.clearColor;

    UIViewController *vc = [UIViewController new];
    vc.title = target.name;
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    picker.frame = CGRectMake(16, 24, vc.view.bounds.size.width - 32, 0);
    picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    CGSize fit = [picker sizeThatFits:CGSizeMake(vc.view.bounds.size.width - 32, CGFLOAT_MAX)];
    picker.frame = CGRectMake(16, 24, vc.view.bounds.size.width - 32, fit.height);
    [vc.view addSubview:picker];
    __weak typeof(self) weakSelf = self;
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:nil];
    done.primaryAction = [UIBarButtonItem systemItem:UIBarButtonSystemItemDone primaryAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
        UIColor *newColor = picker.inputValue;
        target.writeColor(newColor);
        [weakSelf dismissViewControllerAnimated:YES completion:^{ [weakSelf.tableView reloadData]; }];
    }]];
    vc.navigationItem.rightBarButtonItem = done;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
}

- (NSString *)hexStringForColor:(UIColor *)color {
    CGFloat r = 0, g = 0, b = 0, a = 0, w = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        [color getWhite:&w alpha:&a]; r = g = b = w;
    }
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lround(r * 255), lround(g * 255), lround(b * 255)];
}

@end
