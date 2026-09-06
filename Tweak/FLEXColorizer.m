#import <UIKit/UIKit.h>
#import "../Classes/Manager/FLEXManager.h"
#import "../Classes/ExplorerInterface/FLEXExplorerViewController.h"
#import "../Classes/Toolbar/FLEXExplorerToolbar.h"
#import "../Classes/Toolbar/FLEXExplorerToolbarItem.h"
#import "FLEXColorEditorViewController.h"

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

    FLEXExplorerToolbarItem *item = self.explorerToolbar.colorItem;
    if (!item) return;

    [item addTarget:self action:@selector(flex_colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    item.enabled = self.selectedView != nil;
}

- (void)flex_updateButtonStates_colorizer {
    [self flex_updateButtonStates_colorizer];

    FLEXExplorerToolbarItem *item = self.explorerToolbar.colorItem;
    if (item) item.enabled = self.selectedView != nil;
}

- (void)flex_colorButtonTapped:(FLEXExplorerToolbarItem *)sender {
    UIView *view = self.selectedView;
    if (!view) return;

    FLEXColorEditorViewController *editor = [[FLEXColorEditorViewController alloc] initWithView:view];
    [[FLEXManager sharedManager] presentEmbeddedTool:editor completion:nil];
}

@end
