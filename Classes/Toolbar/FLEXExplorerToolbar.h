//
//  FLEXExplorerToolbar.h
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLEXExplorerToolbarItem;

NS_ASSUME_NONNULL_BEGIN

/// Users of the toolbar can configure the enabled state
/// and event target/actions for each item.
@interface FLEXExplorerToolbar : UIView

/// The items to be displayed in the toolbar. Defaults to:
/// globalsItem, hierarchyItem, selectItem, moveItem, colorItem, closeItem
@property (nonatomic, copy) NSArray<FLEXExplorerToolbarItem *> *toolbarItems;

@property (nonatomic, readonly) FLEXExplorerToolbarItem *selectItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *hierarchyItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *moveItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *colorItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *recentItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *globalsItem;
@property (nonatomic, readonly) FLEXExplorerToolbarItem *closeItem;
@property (nonatomic, readonly) UIView *dragHandle;
@property (nonatomic) UIColor *selectedViewOverlayColor;
@property (nonatomic, copy) NSString *selectedViewDescription;
@property (nonatomic, readonly) UIView *selectedViewDescriptionContainer;

@end

NS_ASSUME_NONNULL_END
