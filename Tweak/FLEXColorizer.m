#import <UIKit/UIKit.h>
#import "../Classes/Manager/FLEXManager.h"
#import "../Classes/ExplorerInterface/FLEXExplorerViewController.h"
#import "../Classes/Toolbar/FLEXExplorerToolbar.h"
#import "../Classes/Toolbar/FLEXExplorerToolbarItem.h"
#import "FLEXColorEditorViewController.h"
#import <objc/runtime.h>

static const void *FLEXColorItemKey = &FLEXColorItemKey;

@interface FLEXExplorerToolbar (FLEXColorizerPrivate)
@property (nonatomic, readonly) FLEXExplorerToolbarItem *flex_colorItem;
- (void)flex_setColorItem:(FLEXExplorerToolbarItem *)item;
@end

@implementation FLEXExplorerToolbar (FLEXColorizerPrivate)
- (FLEXExplorerToolbarItem *)flex_colorItem {
    return objc_getAssociatedObject(self, FLEXColorItemKey);
}
- (void)flex_setColorItem:(FLEXExplorerToolbarItem *)item {
    objc_setAssociatedObject(self, FLEXColorItemKey, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation FLEXExplorerViewController (FLEXColorizer)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod(self, @selector(viewDidLoad));
        Method replacement = class_getInstanceMethod(self, @selector(flex_viewDidLoad_colorizer));
        if (original && replacement) method_exchangeImplementations(original, replacement);

        original = class_getInstanceMethod(self, @selector(updateButtonStates));
        replacement = class_getInstanceMethod(self, @selector(flex_updateButtonStates_colorizer));
        if (original && replacement) method_exchangeImplementations(original, replacement);
    });
}

- (void)flex_viewDidLoad_colorizer {
    [self flex_viewDidLoad_colorizer];

    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    if (toolbar.flex_colorItem) return;

    UIImage *image = nil;
    if (@available(iOS 13.0, *)) image = [UIImage systemImageNamed:@"paintpalette.fill"];
    if (!image) image = [UIImage systemImageNamed:@"paintbrush.fill"];

    FLEXExplorerToolbarItem *item = [FLEXExplorerToolbarItem itemWithTitle:@"color" image:image];
    item.enabled = NO;
    [item addTarget:self action:@selector(flex_colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [toolbar flex_setColorItem:item];
}

- (void)flex_updateButtonStates_colorizer {
    [self flex_updateButtonStates_colorizer];
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    FLEXExplorerToolbarItem *item = toolbar.flex_colorItem;
    if (item) item.enabled = ([self valueForKey:@"selectedView"] != nil);
}

- (void)flex_colorButtonTapped:(FLEXExplorerToolbarItem *)sender {
    UIView *view = [self valueForKey:@"selectedView"];
    if (!view) return;
    FLEXColorEditorViewController *editor = [[FLEXColorEditorViewController alloc] initWithView:view];
    [[FLEXManager sharedManager] presentEmbeddedTool:editor completion:nil];
}

@end
