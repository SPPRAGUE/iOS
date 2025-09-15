#import "PhotosViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "EmptyStateView.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UICollectionView+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "CameraUploadsTableViewController.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "UIViewController+MNZCategory.h"
#import "NSArray+MNZCategory.h"

#import "LocalizationHelper.h"
@import StoreKit;
@import Photos;
@import MEGAUIKit;

@interface PhotosViewController ()

@property (weak, nonatomic) IBOutlet UIView *photoContainerView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic) NSLayoutConstraint *stateViewHeightConstraint;
@end

@implementation PhotosViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureContextMenuManager];
    [self configPhotoContainerView];
    [self updateAppearance];
    [self setupBarButtons];
    [self updateNavigationTitleBar];
    [self configureImages];
}

- (void)setupBarButtons {
    self.editBarButtonItem = [self makeEditBarButton];
    self.cancelBarButtonItem = [self makeCancelBarButton];
    self.filterBarButtonItem = [self makeFilterActiveBarButton];
    self.cameraUploadStatusBarButtonItem = [self makeCameraUploadStatusBarButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.viewModel startMonitoringUpdates];
    
    [self.photoUpdatePublisher setupSubscriptions];
    
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self.viewModel loadAllPhotosWithSavedFilters];
    
    [self setupNavigationBarButtons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.viewModel cancelLoading];
    
    [self.photoUpdatePublisher cancelSubscriptions];
}

#pragma mark - config views
- (void)configPhotoContainerView {
    [self objcWrapper_configPhotoLibraryViewIn:self.photoContainerView];
}

- (PhotoSelectionAdapter *)selection {
    if (_selection == nil) {
        _selection = [[PhotoSelectionAdapter alloc] initWithSdk:MEGASdk.shared];
    }
    
    return _selection;
}

- (DefaultNodeAccessoryActionDelegate *)defaultNodeAccessoryActionDelegate {
    if (_defaultNodeAccessoryActionDelegate == nil) {
        _defaultNodeAccessoryActionDelegate = [DefaultNodeAccessoryActionDelegate new];
    }
    return _defaultNodeAccessoryActionDelegate;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)reloadPhotos {
    [self updateNavigationTitleBar];
    [self setupNavigationBarButtons];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self objcWrapper_updatePhotoLibrary];
        [self setupNavigationBarButtons];
    });
}

- (void)updateNavigationTitleBar {
    self.objcWrapper_parent.navigationItem.title = LocalizedString(@"photo.navigation.title", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
}

#pragma mark - IBAction

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self objcWrapper_configPhotoLibrarySelectAll];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self objcWrapper_enablePhotoLibraryEditMode:editing];
    
    if (editing) {
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar == nil) {
            return;
        }
        
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:0];
            [self.toolbar setAlpha:0.0];
            
            [self updateBarButtonItemsIn:self.toolbar];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor surface1Background]];
            
            NSLayoutAnchor *bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
    } else {
        [self updateNavigationTitleBar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
}

- (void)didSelectedPhotoCountChange:(NSInteger)count {
    [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:count];
    [self setToolbarActionsEnabledIn:self.toolbar isEnabled:count > 0];
}

@end
