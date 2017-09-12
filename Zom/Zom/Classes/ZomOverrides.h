//
//  ZomOverrides.h
//  Zom
//
//  Created by N-Pex on 2016-05-17.
//
//

@import ChatSecureCore;

extern NSString *const kOTRXLFormShowAdvancedTag;

@interface OTRAppDelegate (ZomOverride)
@property (nonatomic, strong) OTRSplitViewCoordinator *splitViewCoordinator;
@property (nonatomic, strong) OTRSplitViewControllerDelegateObject *splitViewControllerDelegate;
@end

@interface OTRComposeViewController (ZomOverride)
@property (nonatomic, strong) OTRYapViewHandler *viewHandler;
@property (nonatomic, strong) OTRVerticalStackView *tableViewHeader;
- (void) updateInboxArchiveFilteringAndShowArchived:(BOOL)showArchived;
- (YapDatabaseViewFiltering *)getFilteringBlock:(BOOL)showArchived;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISegmentedControl *inboxArchiveControl;
- (void) groupButtonPressed:(id)sender;
- (void) groupSelectionCancelled:(OTRComposeGroupViewController *)composeViewController;
@end

@interface OTRNewBuddyViewController (ZomOverride)
- (void) updateReturnButtons:(UITextField *)textField;
- (void) qrButtonPressed:(id)sender;
- (IBAction) doneButtonPressed:(id)sender;
- (void) populateFromQRResult:(NSString *)result;
@end

@interface OTRAttachmentPicker (ZomOverride)
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType;
@end

@interface OTRMessagesViewController (ZomOverride)
- (void)refreshTitleView;
- (IBAction)didPressMigratedSwitch;
@property (nonatomic, strong) OTRYapViewHandler *viewHandler;
- (void)didSetupMappings:(OTRYapViewHandler *)handler;
- (void)didReceiveChanges:(OTRYapViewHandler *)handler sectionChanges:(NSArray<YapDatabaseViewSectionChange *> *)sectionChanges rowChanges:(NSArray<YapDatabaseViewRowChange *> *)rowChanges;
- (void)showJIDForwardingHeaderWithNewJID:(XMPPJID *)newJid;
- (BOOL)hasBubbleSizeForCellAtIndexPath:(NSIndexPath*)indexPath;
- (void)setupInfoButton;
@end

@interface OTRMessagesHoldTalkViewController (ZomOverride)
- (void)setupDefaultSendButton;
@end

@interface OTRInviteViewController (ZomOverride)
- (void)skipPressed:(id)sender;
- (void)qrButtonPressed:(id)sender;
- (void)linkShareButtonPressed:(id)sender;
@end

@interface OTRConversationViewController (ZomOverride)
- (void)settingsButtonPressed:(id)sender;
- (void)composeButtonPressed:(id)sender;
- (IBAction)didPressStartMigrationButton:(id)sender;
- (MigrationInfoHeaderView *)createMigrationHeaderView:(OTRXMPPAccount *)account;
- (void) updateInboxArchiveFilteringAndShowArchived:(BOOL)showArchived;
@property (nonatomic, strong) MigrationInfoHeaderView *migrationInfoHeaderView;
@property (nonatomic, strong) UISegmentedControl *inboxArchiveControl;
@end

@interface OTRBaseLoginViewController (ZomOverride)
+ (instancetype)loginViewControllerForAccount:(OTRAccount *)account;
- (IBAction)loginButtonPressed:(id)sender;
- (void)pushInviteViewController;
-(void)configureCell:(XLFormBaseCell*) cell;
@end

@interface OTRSettingsViewController (ZomOverride)
- (void)logoutAccount:(OTRAccount *)account sender:(id)sender;
@property (nonatomic, strong) UITableView *tableView;
@end

@interface OTRBuddy (ZomOverride)
@property (nonatomic, strong, readwrite, nonnull) NSString *displayName;
@end

@interface OTRAccountMigrator (ZomOverride)
- (BOOL) areBothAccountsAreOnline;
@end
