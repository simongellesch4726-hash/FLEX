#import <UIKit/UIKit.h>
#import "../Classes/FLEXManager.h"
#import "../Classes/ExplorerInterface/FLEXExplorerViewController.h"
#import "../Classes/Toolbar/FLEXExplorerToolbar.h"
#import "../Classes/Toolbar/FLEXExplorerToolbarItem.h"
#import "FLEXColorEditorViewController.h"
#import <objc/runtime.h>

static FLEXExplorerViewController *FLEXCurrentExplorer(void) {
    FLEXManager *manager = [FLEXManager sharedManager];
    id explorer = [manager valueForKey:@"explorerViewController"];
    return [explorer isKindOfClass:[FLEXExplorerViewController class]] ? explorer : nil;
}

static void FLEXInstallColorAction(FLEXExplorerViewController *explorer) {
    if (!explorer) return;
    FLEXExplorerToolbar *toolbar = explorer.explorerToolbar;
    if (![toolbar respondsToSelector:@selector(colorItem)]) return;
}

__attribute__((constructor)) static void FLEXColorizerInit(void) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class toolbarClass = [FLEXExplorerToolbar class];
            Class explorerClass = [FLEXExplorerViewController class];
            (void)toolbarClass;
            (void)explorerClass;
        });
    }
}
