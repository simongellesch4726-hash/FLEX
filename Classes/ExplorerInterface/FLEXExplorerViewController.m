//
//  FLEXExplorerViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXExplorerViewController.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"
#import "FLEXWindow.h"
#import "FLEXTabList.h"
#import "FLEXNavigationController.h"
#import "FLEXHierarchyViewController.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXTabsViewController.h"
#import "FLEXWindowManagerController.h"
#import "FLEXViewControllersViewController.h"
#import "NSUserDefaults+FLEX.h"
#import "FLEXColorEditorViewController.h"

typedef NS_ENUM(NSUInteger, FLEXExplorerMode) {
    FLEXExplorerModeDefault,
    FLEXExplorerModeSelect,
    FLEXExplorerModeMove
};

@interface FLEXExplorerViewController () <FLEXHierarchyDelegate, UIAdaptivePresentationControllerDelegate>
@property (nonatomic) FLEXExplorerMode currentMode;
@property (nonatomic) UIPanGestureRecognizer *movePanGR;
@property (nonatomic) UITapGestureRecognizer *detailsTapGR;
@property (nonatomic) CGRect selectedViewFrameBeforeDragging;
@property (nonatomic) CGRect toolbarFrameBeforeDragging;
@property (nonatomic) CGFloat selectedViewLastPanX;
@property (nonatomic) NSDictionary<NSValue *, UIView *> *outlineViewsForVisibleViews;
@property (nonatomic) NSArray<UIView *> *viewsAtTapPoint;
@property (nonatomic) CGPoint lastTapPoint;
@property (nonatomic) UIView *selectedView;
@property (nonatomic) UIView *tapIndicatorView;
@property (nonatomic) UIView *selectedViewOverlay;
@property (nonatomic, readonly) UISelectionFeedbackGenerator *selectionFBG API_AVAILABLE(ios(10.0));
@property (nonatomic, readonly) FLEXWindow *window;
@property (nonatomic) NSMutableSet<UIView *> *observedViews;
@property (nonatomic) NSArray<UIMenuItem *> *appMenuItems;
@end

@implementation FLEXExplorerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.observedViews = [NSMutableSet new];
    }
    return self;
}

- (void)dealloc {
    for (UIView *view in _observedViews) {
        [self stopObservingView:view];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _explorerToolbar = [FLEXExplorerToolbar new];
    CGFloat toolbarOriginY = NSUserDefaults.standardUserDefaults.flex_toolbarTopMargin;
    CGRect safeArea = [self viewSafeArea];
    CGSize toolbarSize = [self.explorerToolbar sizeThatFits:CGSizeMake(
        CGRectGetWidth(self.view.bounds), CGRectGetHeight(safeArea)
    )];
    [self updateToolbarPositionWithUnconstrainedFrame:CGRectMake(
        CGRectGetMinX(safeArea), toolbarOriginY, toolbarSize.width, toolbarSize.height
    )];
    self.explorerToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.explorerToolbar];
    [self setupToolbarActions];
    [self setupToolbarGestures];
    
    _tapIndicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    _tapIndicatorView.backgroundColor = [UIColor colorWithRed:0 green:0.5 blue:1 alpha:0.5];
    _tapIndicatorView.layer.cornerRadius = 10;
    _tapIndicatorView.userInteractionEnabled = NO;
    _tapIndicatorView.hidden = YES;
    [self.view addSubview:_tapIndicatorView];

    UITapGestureRecognizer *selectionTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleSelectionTap:)
    ];
    [self.view addGestureRecognizer:selectionTapGR];
    
    self.movePanGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
    self.movePanGR.enabled = self.currentMode == FLEXExplorerModeMove;
    [self.view addGestureRecognizer:self.movePanGR];
    
    if (@available(iOS 10.0, *)) {
        _selectionFBG = [UISelectionFeedbackGenerator new];
    }
    
    [NSNotificationCenter.defaultCenter
        addObserver:self
        selector:@selector(keyboardShown:)
        name:UIKeyboardWillShowNotification
        object:nil
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButtonStates];
}

#pragma mark - Rotation

- (UIViewController *)viewControllerForRotationAndOrientation {
    UIViewController *viewController = FLEXUtility.appKeyWindow.rootViewController;
    NSString *viewControllerSelectorString = [@[
        @"_vie", @"wContro", @"llerFor", @"Supported", @"Interface", @"Orientations"
    ] componentsJoinedByString:@""];
    SEL viewControllerSelector = NSSelectorFromString(viewControllerSelectorString);
    if ([viewController respondsToSelector:viewControllerSelector]) {
        viewController = [viewController valueForKey:viewControllerSelectorString];
    }
    return viewController;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    UIInterfaceOrientationMask supportedOrientations = FLEXUtility.infoPlistSupportedInterfaceOrientationsMask;
    if (viewControllerToAsk && ![NSStringFromClass([viewControllerToAsk class]) hasPrefix:@"FLEX"]) {
        supportedOrientations = [viewControllerToAsk supportedInterfaceOrientations];
    }
    if (supportedOrientations == 0) {
        supportedOrientations = UIInterfaceOrientationMaskAll;
    }
    return supportedOrientations;
}

- (BOOL)shouldAutorotate {
    UIViewController *viewControllerToAsk = [self viewControllerForRotationAndOrientation];
    BOOL shouldAutorotate = YES;
    if (viewControllerToAsk && viewControllerToAsk != self) {
        shouldAutorotate = [viewControllerToAsk shouldAutorotate];
    }
    return shouldAutorotate;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *outlineView in self.outlineViewsForVisibleViews.allValues) {
            outlineView.hidden = YES;
        }
        self.selectedViewOverlay.hidden = YES;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        for (UIView *view in self.viewsAtTapPoint) {
            NSValue *key = [NSValue valueWithNonretainedObject:view];
            UIView *outlineView = self.outlineViewsForVisibleViews[key];
            outlineView.frame = [self frameInLocalCoordinatesForView:view];
            if (self.currentMode == FLEXExplorerModeSelect) {
                outlineView.hidden = NO;
            }
        }
        if (self.selectedView) {
            self.selectedViewOverlay.frame = [self frameInLocalCoordinatesForView:self.selectedView];
            self.selectedViewOverlay.hidden = NO;
        }
    }];
}

#pragma mark - Setter Overrides

- (void)setSelectedView:(UIView *)selectedView {
    if (![_selectedView isEqual:selectedView]) {
        if (![self.viewsAtTapPoint containsObject:_selectedView]) {
            [self stopObservingView:_selectedView];
        }
        _selectedView = selectedView;
        [self beginObservingView:selectedView];
        self.explorerToolbar.selectedViewDescription = [FLEXUtility descriptionForView:selectedView includingFrame:YES];
        self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility consistentRandomColorForObject:selectedView];
        if (selectedView) {
            if (!self.selectedViewOverlay) {
                self.selectedViewOverlay = [UIView new];
                [self.view addSubview:self.selectedViewOverlay];
                self.selectedViewOverlay.layer.borderWidth = 1.0;
            }
            UIColor *outlineColor = [FLEXUtility consistentRandomColorForObject:selectedView];
            self.selectedViewOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
            self.selectedViewOverlay.layer.borderColor = outlineColor.CGColor;
            self.selectedViewOverlay.frame = [self.view convertRect:selectedView.bounds fromView:selectedView];
            [self.view bringSubviewToFront:self.selectedViewOverlay];
            [self.view bringSubviewToFront:self.explorerToolbar];
        } else {
            [self.selectedViewOverlay removeFromSuperview];
            self.selectedViewOverlay = nil;
        }
        [self updateButtonStates];
    }
}

- (void)setViewsAtTapPoint:(NSArray<UIView *> *)viewsAtTapPoint {
    if (![_viewsAtTapPoint isEqual:viewsAtTapPoint]) {
        for (UIView *view in _viewsAtTapPoint) {
            if (view != self.selectedView) {
                [self stopObservingView:view];
            }
        }
        _viewsAtTapPoint = viewsAtTapPoint;
        for (UIView *view in viewsAtTapPoint) {
            [self beginObservingView:view];
        }
    }
}

- (void)setCurrentMode:(FLEXExplorerMode)currentMode {
    if (_currentMode != currentMode) {
        _currentMode = currentMode;
        switch (currentMode) {
            case FLEXExplorerModeDefault:
                [self removeAndClearOutlineViews];
                self.viewsAtTapPoint = nil;
                self.selectedView = nil;
                break;
            case FLEXExplorerModeSelect:
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = NO;
                }
                break;
            case FLEXExplorerModeMove:
                for (NSValue *key in self.outlineViewsForVisibleViews) {
                    UIView *outlineView = self.outlineViewsForVisibleViews[key];
                    outlineView.hidden = YES;
                }
                break;
        }
        self.movePanGR.enabled = currentMode == FLEXExplorerModeMove;
        [self updateButtonStates];
    }
}

#pragma mark - View Tracking

- (void)beginObservingView:(UIView *)view {
    if (!view || [self.observedViews containsObject:view]) {
        return;
    }
    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view addObserver:self forKeyPath:keyPath options:0 context:NULL];
    }
    [self.observedViews addObject:view];
}

- (void)stopObservingView:(UIView *)view {
    if (!view) {
        return;
    }
    for (NSString *keyPath in self.viewKeyPathsToTrack) {
        [view removeObserver:self forKeyPath:keyPath];
    }
    [self.observedViews removeObject:view];
}

- (NSArray<NSString *> *)viewKeyPathsToTrack {
    static NSArray<NSString *> *trackedViewKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *frameKeyPath = NSStringFromSelector(@selector(frame));
        trackedViewKeyPaths = @[frameKeyPath];
    });
    return trackedViewKeyPaths;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSString *, id> *)change
                       context:(void *)context {
    [self updateOverlayAndDescriptionForObjectIfNeeded:object];
}

- (void)updateOverlayAndDescriptionForObjectIfNeeded:(id)object {
    NSUInteger indexOfView = [self.viewsAtTapPoint indexOfObject:object];
    if (indexOfView != NSNotFound) {
        UIView *view = self.viewsAtTapPoint[indexOfView];
        NSValue *key = [NSValue valueWithNonretainedObject:view];
        UIView *outline = self.outlineViewsForVisibleViews[key];
        if (outline) {
            outline.frame = [self frameInLocalCoordinatesForView:view];
        }
    }
    if (object == self.selectedView) {
        self.explorerToolbar.selectedViewDescription = [FLEXUtility descriptionForView:self.selectedView includingFrame:YES];
        CGRect selectedViewOutlineFrame = [self frameInLocalCoordinatesForView:self.selectedView];
        self.selectedViewOverlay.frame = selectedViewOutlineFrame;
    }
}

- (CGRect)frameInLocalCoordinatesForView:(UIView *)view {
    CGRect frameInWindow = [view convertRect:view.bounds toView:nil];
    return [self.view convertRect:frameInWindow fromView:nil];
}

- (void)keyboardShown:(NSNotification *)notif {
    CGRect keyboardFrame = [notif.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect toolbarFrame = self.explorerToolbar.frame;
    if (CGRectGetMinY(keyboardFrame) < CGRectGetMaxY(toolbarFrame)) {
        toolbarFrame.origin.y = keyboardFrame.origin.y - toolbarFrame.size.height;
        toolbarFrame.origin.y -= 50;
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self updateToolbarPositionWithUnconstrainedFrame:toolbarFrame];
        } completion:nil];
    }
}

#pragma mark - Toolbar Buttons

- (void)setupToolbarActions {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    NSDictionary<NSString *, FLEXExplorerToolbarItem *> *actionsToItems = @{
        NSStringFromSelector(@selector(selectButtonTapped:)):        toolbar.selectItem,
        NSStringFromSelector(@selector(hierarchyButtonTapped:)):     toolbar.hierarchyItem,
        NSStringFromSelector(@selector(recentButtonTapped:)):       toolbar.recentItem,
        NSStringFromSelector(@selector(moveButtonTapped:)):         toolbar.moveItem,
        NSStringFromSelector(@selector(colorButtonTapped:)):        toolbar.colorItem,
        NSStringFromSelector(@selector(globalsButtonTapped:)):      toolbar.globalsItem,
        NSStringFromSelector(@selector(closeButtonTapped:)):        toolbar.closeItem,
    };
    [actionsToItems enumerateKeysAndObjectsUsingBlock:^(NSString *sel, FLEXExplorerToolbarItem *item, BOOL *stop) {
        if (item) {
            [item addTarget:self action:NSSelectorFromString(sel) forControlEvents:UIControlEventTouchUpInside];
        }
    }];
}

- (void)selectButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleSelectTool];
}

- (void)hierarchyButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleViewsTool];
}

- (UIWindow *)statusWindow {
    if (!@available(iOS 16, *)) {
        NSString *statusBarString = [NSString stringWithFormat:@"%@arWindow", @"_statusB"];
        return [UIApplication.sharedApplication valueForKey:statusBarString];
    }
    return nil;
}

- (void)recentButtonTapped:(FLEXExplorerToolbarItem *)sender {
    NSAssert(FLEXTabList.sharedList.activeTab, @"Must have active tab");
    [self presentViewController:FLEXTabList.sharedList.activeTab animated:YES completion:nil];
}

- (void)moveButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMoveTool];
}

- (void)colorButtonTapped:(FLEXExplorerToolbarItem *)sender {
    if (!self.selectedView) {
        return;
    }
    FLEXColorEditorViewController *editor = [[FLEXColorEditorViewController alloc] initWithView:self.selectedView];
    [self presentViewController:editor animated:YES completion:nil];
}

- (void)globalsButtonTapped:(FLEXExplorerToolbarItem *)sender {
    [self toggleMenuTool];
}

- (void)closeButtonTapped:(FLEXExplorerToolbarItem *)sender {
    self.currentMode = FLEXExplorerModeDefault;
    [self.delegate explorerViewControllerDidFinish:self];
}

- (void)updateButtonStates {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    toolbar.selectItem.selected = self.currentMode == FLEXExplorerModeSelect;
    BOOL hasSelectedObject = self.selectedView != nil;
    toolbar.moveItem.enabled = hasSelectedObject;
    toolbar.moveItem.selected = self.currentMode == FLEXExplorerModeMove;
    toolbar.colorItem.enabled = hasSelectedObject;
    if (!self.presentedViewController) {
        toolbar.recentItem.enabled = FLEXTabList.sharedList.activeTab != nil;
    } else {
        toolbar.recentItem.enabled = NO;
    }
}

#pragma mark - Toolbar Dragging

- (void)setupToolbarGestures {
    FLEXExplorerToolbar *toolbar = self.explorerToolbar;
    [toolbar.dragHandle addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarPanGesture:)
    ]];
    [toolbar.dragHandle addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarHintTapGesture:)
    ]];
    self.detailsTapGR = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarDetailsTapGesture:)
    ];
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:self.detailsTapGR];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleChangeViewAtPointGesture:)
    ];
    [toolbar.selectedViewDescriptionContainer addGestureRecognizer:panGesture];
    [toolbar.globalsItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowTabsGesture:)
    ]];
    [toolbar.selectItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarWindowManagerGesture:)
    ]];
    [toolbar.hierarchyItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleToolbarShowViewControllersGesture:)
    ]];
}

- (void)handleToolbarPanGesture:(UIPanGestureRecognizer *)panGR {
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan:
            self.toolbarFrameBeforeDragging = self.explorerToolbar.frame;
            [self updateToolbarPositionWithDragGesture:panGR];
            break;
        case UIGestureRecognizerStateChanged:
        case UIGestureRecognizerStateEnded:
            [self updateToolbarPositionWithDragGesture:panGR];
            break;
        default:
            break;
    }
}

- (void)updateToolbarPositionWithDragGesture:(UIPanGestureRecognizer *)panGR {
    CGPoint translation = [panGR translationInView:self.view];
    CGRect newToolbarFrame = self.toolbarFrameBeforeDragging;
    newToolbarFrame.origin.y += translation.y;
    [self updateToolbarPositionWithUnconstrainedFrame:newToolbarFrame];
}

- (void)updateToolbarPositionWithUnconstrainedFrame:(CGRect)unconstrainedFrame {
    CGRect safeArea = [self viewSafeArea];
    unconstrainedFrame.origin.y = MAX(CGRectGetMinY(safeArea), unconstrainedFrame.origin.y);
    unconstrainedFrame.origin.y = MIN(CGRectGetMaxY(safeArea) - unconstrainedFrame.size.height, unconstrainedFrame.origin.y);
    self.explorerToolbar.frame = unconstrainedFrame;
}

@end
