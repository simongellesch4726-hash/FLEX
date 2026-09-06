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

@interface FLEXColorEditorViewController () <FLEXArgumentInputViewDelegate>
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
        target:self
        action:@selector(done)
    ];
    self.tableView.rowHeight = 56.0;
    [self buildTargets];
}

- (void)done {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)buildTargets {
    UIView *view = self.targetView;
    if (!view) {
        self.targets = @[];
        return;
    }

    NSMutableArray<FLEXColorTarget *> *targets = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    void (^addTarget)(NSString *, NSString *, UIColor *(^)(void), void (^)(UIColor *)) =
    ^(NSString *name, NSString *identifier, UIColor *(^read)(void), void (^write)(UIColor *)) {
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
        addTarget(@"Background", @"background", ^UIColor *{
            return button.backgroundColor;
        }, ^(UIColor *color) {
            button.backgroundColor = color;
        });
        addTarget(@"Tint", @"tint", ^UIColor *{
            return button.tintColor;
        }, ^(UIColor *color) {
            button.tintColor = color;
        });

        NSArray<NSNumber *> *states = @[
            @(UIControlStateNormal),
            @(UIControlStateHighlighted),
            @(UIControlStateSelected),
            @(UIControlStateDisabled)
        ];
        for (NSNumber *number in states) {
            UIControlState state = number.unsignedIntegerValue;
            NSString *name = state == UIControlStateNormal ? @"Title (Normal)" :
                state == UIControlStateHighlighted ? @"Title (Highlighted)" :
                state == UIControlStateSelected ? @"Title (Selected)" : @"Title (Disabled)";
            NSString *identifier = [NSString stringWithFormat:@"title.%lu", (unsigned long)state];
            addTarget(name, identifier, ^UIColor *{
                return [button titleColorForState:state];
            }, ^(UIColor *color) {
                [button setTitleColor:color forState:state];
            });
        }
    } else if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        addTarget(@"Text", @"text", ^UIColor *{
            return label.textColor;
        }, ^(UIColor *color) {
            label.textColor = color;
        });
        addTarget(@"Background", @"background", ^UIColor *{
            return label.backgroundColor;
        }, ^(UIColor *color) {
            label.backgroundColor = color;
        });
    } else if ([view isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)view;
        addTarget(@"Text", @"text", ^UIColor *{
            return field.textColor;
        }, ^(UIColor *color) {
            field.textColor = color;
        });
        addTarget(@"Tint", @"tint", ^UIColor *{
            return field.tintColor;
        }, ^(UIColor *color) {
            field.tintColor = color;
        });
        addTarget(@"Background", @"background", ^UIColor *{
            return field.backgroundColor;
        }, ^(UIColor *color) {
            field.backgroundColor = color;
        });
    } else if ([view isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)view;
        addTarget(@"Text", @"text", ^UIColor *{
            return textView.textColor;
        }, ^(UIColor *color) {
            textView.textColor = color;
        });
        addTarget(@"Tint", @"tint", ^UIColor *{
            return textView.tintColor;
        }, ^(UIColor *color) {
            textView.tintColor = color;
        });
        addTarget(@"Background", @"background", ^UIColor *{
            return textView.backgroundColor;
        }, ^(UIColor *color) {
            textView.backgroundColor = color;
        });
    } else if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        addTarget(@"Tint", @"tint", ^UIColor *{
            return imageView.tintColor;
        }, ^(UIColor *color) {
            imageView.tintColor = color;
        });
        addTarget(@"Background", @"background", ^UIColor *{
            return imageView.backgroundColor;
        }, ^(UIColor *color) {
            imageView.backgroundColor = color;
        });
    } else if ([view isKindOfClass:[UISwitch class]]) {
        UISwitch *control = (UISwitch *)view;
        addTarget(@"On Tint", @"onTint", ^UIColor *{
            return control.onTintColor;
        }, ^(UIColor *color) {
            control.onTintColor = color;
        });
        addTarget(@"Thumb Tint", @"thumbTint", ^UIColor *{
            return control.thumbTintColor;
        }, ^(UIColor *color) {
            control.thumbTintColor = color;
        });
        addTarget(@"Tint", @"tint", ^UIColor *{
            return control.tintColor;
        }, ^(UIColor *color) {
            control.tintColor = color;
        });
    } else if ([view isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)view;
        addTarget(@"Minimum Track", @"minimumTrack", ^UIColor *{
            return slider.minimumTrackTintColor;
        }, ^(UIColor *color) {
            slider.minimumTrackTintColor = color;
        });
        addTarget(@"Maximum Track", @"maximumTrack", ^UIColor *{
            return slider.maximumTrackTintColor;
        }, ^(UIColor *color) {
            slider.maximumTrackTintColor = color;
        });
        addTarget(@"Thumb", @"thumb", ^UIColor *{
            return slider.thumbTintColor;
        }, ^(UIColor *color) {
            slider.thumbTintColor = color;
        });
    }

    // Composite visual elements remain a single selected UIView. We do not walk
    // or recolor descendant views automatically.
    BOOL specialized = [view isKindOfClass:[UIButton class]] ||
                        [view isKindOfClass:[UILabel class]] ||
                        [view isKindOfClass:[UITextField class]] ||
                        [view isKindOfClass:[UITextView class]] ||
                        [view isKindOfClass:[UIImageView class]] ||
                        [view isKindOfClass:[UISwitch class]] ||
                        [view isKindOfClass:[UISlider class]];

    if (!specialized) {
        addTarget(@"Background", @"background", ^UIColor *{
            return view.backgroundColor;
        }, ^(UIColor *color) {
            view.backgroundColor = color;
        });
        addTarget(@"Tint", @"tint", ^UIColor *{
            return view.tintColor;
        }, ^(UIColor *color) {
            view.tintColor = color;
        });
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
    static NSString *reuseIdentifier = @"FLEXColorTargetCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                       reuseIdentifier:reuseIdentifier];
    }

    FLEXColorTarget *target = self.targets[indexPath.row];
    UIColor *color = target.readColor ? target.readColor() : UIColor.clearColor;
    color = [self resolvedEditableColor:color fallback:UIColor.clearColor];

    cell.textLabel.text = target.name;
    cell.detailTextLabel.text = [self hexStringForColor:color];
    cell.detailTextLabel.textColor = UIColor.labelColor;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FLEXColorTarget *target = self.targets[indexPath.row];
    [self presentColorPickerForTarget:target];
}

- (UIColor *)resolvedEditableColor:(UIColor *)color fallback:(UIColor *)fallback {
    if (!color) return fallback;

    if (@available(iOS 13.0, *)) {
        color = [color resolvedColorWithTraitCollection:self.targetView.traitCollection];
    }

    CGFloat r = 0, g = 0, b = 0, a = 1, w = 0;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    if ([color getWhite:&w alpha:&a]) {
        return [UIColor colorWithWhite:w alpha:a];
    }
    return fallback;
}

- (void)presentColorPickerForTarget:(FLEXColorTarget *)target {
    FLEXArgumentInputColorView *picker =
        [[FLEXArgumentInputColorView alloc] initWithArgumentTypeEncoding:@encode(UIColor *)];
    picker.targetSize = FLEXArgumentInputViewSizeLarge;
    picker.delegate = self;

    UIColor *current = target.readColor ? target.readColor() : UIColor.clearColor;
    picker.inputValue = [self resolvedEditableColor:current fallback:UIColor.clearColor];

    UIViewController *controller = [UIViewController new];
    controller.title = target.name;
    controller.view.backgroundColor = UIColor.systemBackgroundColor;
    controller.view.autoresizesSubviews = YES;

    [controller.view addSubview:picker];
    self->_activeTarget = target;
    self->_activePicker = picker;

    controller.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                       target:self
                                                       action:@selector(cancelPicker)];
    controller.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                       target:self
                                                       action:@selector(applyPicker)];

    picker.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [picker.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor constant:16.0],
        [picker.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor constant:-16.0],
        [picker.topAnchor constraintEqualToAnchor:controller.view.safeAreaLayoutGuide.topAnchor constant:16.0],
    ]];

    UINavigationController *navigationController =
        [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)cancelPicker {
    self->_activeTarget = nil;
    self->_activePicker = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)applyPicker {
    FLEXColorTarget *target = self->_activeTarget;
    FLEXArgumentInputColorView *picker = self->_activePicker;
    if (target && picker) {
        UIColor *newColor = [self resolvedEditableColor:picker.inputValue fallback:UIColor.clearColor];
        target.writeColor(newColor);
    }

    self->_activeTarget = nil;
    self->_activePicker = nil;
    [self dismissViewControllerAnimated:YES completion:^{
        [self.tableView reloadData];
    }];
}

- (void)argumentInputViewValueDidChange:(FLEXArgumentInputView *)argumentInputView {
    FLEXColorTarget *target = self->_activeTarget;
    FLEXArgumentInputColorView *picker = self->_activePicker;
    if (target && picker == argumentInputView) {
        UIColor *newColor = [self resolvedEditableColor:picker.inputValue fallback:UIColor.clearColor];
        target.writeColor(newColor);
    }
}

- (NSString *)hexStringForColor:(UIColor *)color {
    CGFloat r = 0, g = 0, b = 0, a = 1, w = 0;
    if (![color getRed:&r green:&g blue:&b alpha:&a] && [color getWhite:&w alpha:&a]) {
        r = g = b = w;
    }
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
        lround(r * 255.0), lround(g * 255.0), lround(b * 255.0)];
}

@end
