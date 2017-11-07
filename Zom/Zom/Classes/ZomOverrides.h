//
//  ZomOverrides.h
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

@import ChatSecureCore;

extern  NSString * _Nonnull const kOTRXLFormShowAdvancedTag;

@interface OTRAppDelegate (ZomOverride)
@property (nonatomic, strong) OTRSplitViewCoordinator * _Nonnull splitViewCoordinator;
@property (nonatomic, strong) OTRSplitViewControllerDelegateObject * _Nonnull splitViewControllerDelegate;
@end

@interface OTRComposeViewController (ZomOverride)
@property (nonatomic, strong) OTRYapViewHandler * _Nullable viewHandler;
@property (nonatomic, strong) OTRVerticalStackView * _Nonnull tableViewHeader;
- (void) updateInboxArchiveFilteringAndShowArchived:(BOOL)showArchived;
- (YapDatabaseViewFiltering * _Nonnull)getFilteringBlock:(BOOL)showArchived;
@property (nonatomic, strong) UITableView * _Nonnull tableView;
@property (nonatomic, strong) UISegmentedControl * _Nonnull inboxArchiveControl;
- (void) groupButtonPressed:(id _Nullable)sender;
- (void) groupSelectionCancelled:(OTRComposeGroupViewController * _Nullable)composeViewController;
@end

@interface OTRNewBuddyViewController (ZomOverride)
- (void) updateReturnButtons:(UITextField * _Nonnull)textField;
- (void) qrButtonPressed:(id _Nullable)sender;
- (IBAction) doneButtonPressed:(id _Nullable)sender;
- (void) populateFromQRResult:(NSString * _Nonnull)result;
@end

@interface OTRAttachmentPicker (ZomOverride)
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType;
@end

@interface OTRMessagesViewController (ZomOverride)
- (void)refreshTitleView;
- (IBAction)didPressMigratedSwitch;
@property (nonatomic, strong) OTRYapViewHandler * _Nonnull viewHandler;
- (void)didSetupMappings:(OTRYapViewHandler * _Nonnull)handler;
- (void)didReceiveChanges:(OTRYapViewHandler * _Nonnull)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> * _Nonnull)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> * _Nonnull)rowChanges;
- (void)showJIDForwardingHeaderWithNewJID:(XMPPJID * _Nonnull)newJid;
- (BOOL)hasBubbleSizeForCellAtIndexPath:(NSIndexPath* _Nonnull)indexPath;
- (void)setupInfoButton;
- (OTRAttachmentPicker * _Nonnull)attachmentPicker;
- (void)showImage:(OTRImageItem * _Nullable)imageItem fromCollectionView:(JSQMessagesCollectionView * _Nonnull)collectionView atIndexPath:(NSIndexPath * _Nonnull)indexPath;
@end

@interface OTRInviteViewController (ZomOverride)
- (void)skipPressed:(id _Nullable)sender;
- (void)qrButtonPressed:(id _Nullable)sender;
- (void)linkShareButtonPressed:(id _Nullable)sender;
@end

@interface OTRConversationViewController (ZomOverride)
- (void)settingsButtonPressed:(id _Nullable)sender;
- (void)composeButtonPressed:(id _Nullable)sender;
- (IBAction)didPressStartMigrationButton:(id _Nullable)sender;
- (MigrationInfoHeaderView * _Nonnull)createMigrationHeaderView:(OTRXMPPAccount * _Nonnull)account;
- (void) updateInboxArchiveFilteringAndShowArchived:(BOOL)showArchived;
@property (nonatomic, strong) MigrationInfoHeaderView * _Nullable migrationInfoHeaderView;
@property (nonatomic, strong) UISegmentedControl * _Nonnull inboxArchiveControl;
@end

@interface OTRBaseLoginViewController (ZomOverride)
+ (instancetype _Nonnull)loginViewControllerForAccount:(OTRAccount * _Nonnull)account;
- (IBAction)loginButtonPressed:(id _Nonnull)sender;
- (void)pushInviteViewController;
-(void)configureCell:(XLFormBaseCell* _Nonnull) cell;
@end

@interface OTRSettingsViewController (ZomOverride)
- (void)logoutAccount:(OTRAccount * _Nonnull)account sender:(id _Nullable)sender;
@property (nonatomic, strong) UITableView * _Nonnull tableView;
@end

@interface OTRBuddy (ZomOverride)
@property (nonatomic, strong, readwrite, nonnull) NSString *displayName;
@end

@interface OTRAccountMigrator (ZomOverride)
- (BOOL) areBothAccountsAreOnline;
@end
