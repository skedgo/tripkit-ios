//
//  SGBPBookingViewController.m
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import "BPKBookingViewController.h"

@import KVNProgress;

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#import <TripKitBookings/TripKitBookings-Swift.h>
#endif


#import "BPKHelpers.h"
#import "BPKTextFieldHelper.h"

#import "BPKForm.h"
#import "BPKUser.h"
#import "BPKCost.h"
#import "BPKServerUtil.h"
#import "BPKManager.h"
#import "BPKFormBuilder.h"
#import "BPKSectionItem+Address.h"
#import "BPKActionOverlay.h"

#import "BPKOptionsViewController.h"

#import "BPKWebViewController.h"

#import "UIViewController+modalController.h"
#import "UIBarButtonItem+NavigationBar.h"

@interface BPKBookingViewController () <BPKOptionsViewControllerDelegate, BPKWebViewControllerDelegate>

@property (nonatomic, assign) BOOL isFormLoaded;
@property (nonatomic, assign) BOOL isAwaitingPayment;

@property (nonatomic, strong) BPKActionOverlay *actionOverlay;

// what we are currently displaying
@property (nonatomic, strong) NSURL *bookingURL;
@property (nonatomic, strong) BPKForm *form;

// what we will be showing next (for booking)
@property (nonatomic, strong) NSDictionary *postData;
@property (nonatomic, strong) NSURL *nextBookingURL;

// manage textfield used in the form
@property (nonatomic, strong) BPKTextFieldHelper *textFieldHelper;

@end

@implementation BPKBookingViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.allowTapAnywhereToDismissKeyboard = YES;
  
  // Configure HUD
  self.HUD.backgroundType = KVNProgressBackgroundTypeBlurred;
  self.HUD.minimumDisplayTime = 0.5f;
  self.HUD.allowUserInteraction = YES;
  
  // Set up manager
  if (! self.manager) {
    self.manager = [[BPKManager alloc] init];
  }
  
  self.navigationItem.leftBarButtonItem = self.isModal ? [UIBarButtonItem cancelButtonWithSelector:@selector(cancelButtonPressed:) forController:self] : nil;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  
  if (! self.isFormLoaded) {
    if (self.form != nil) {
      [self loadForm];
      self.isFormLoaded = YES;
    } else {
      [self requestForm:nil];
      self.isFormLoaded = YES;
    }
  } else {
    // Form has already been loaded, but we may need to refresh it, e.g.,
    // following payment.
    if (self.isAwaitingPayment) {
      NSString *urlString = [[self.form updateBookingItem] value];
      NSURL *url =[NSURL URLWithString:urlString];
      [self refreshFormWithURL:url];
    }
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidShow:)
                                               name:UIKeyboardDidShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardDidHide:)
                                               name:UIKeyboardWillHideNotification object:nil];
  
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [self dismissKeyboardOnTap:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public methods

- (instancetype)initWithForm:(BPKForm *)form
{
  self = [super init];
  
  if (self) {
    _form = form;
  }
  
  return self;
}

- (instancetype)initWithBookingURL:(NSURL *)bookingURL
{
  return [self initWithBookingURL:bookingURL postData:nil];
}

- (instancetype)initWithBookingURL:(NSURL *)bookingURL postData:(NSDictionary *)dictionary
{
  self = [super init];
  
  if (self) {
    _bookingURL = bookingURL;
    _postData = dictionary;
  }
  
  return self;
}

#pragma mark - Lazy accessors

- (BPKTextFieldHelper *)textFieldHelper
{
  if (! _textFieldHelper) {
    _textFieldHelper = [[BPKTextFieldHelper alloc] initWithForm:self];
  }
  
  return _textFieldHelper;
}

#pragma mark - Overrides

- (void)dismissKeyboardOnTap:(UITapGestureRecognizer *)sender
{
  // This is only enabled here.
  self.textFieldHelper.disableMoveToNextOnReturn = YES;
  
  // When dismiss by tapping anywehre on the screen (other than
  // table view), don't advnace to next textfield.
  self.textFieldHelper.willMoveToNext = NO;
  
  [super dismissKeyboardOnTap:sender];
}

- (void)configureLabelCell:(BPKLabelCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureLabelCell:cell atIndexPath:indexPath forItem:item];
  
  cell.didSelectHandler = [self didSelectLabelCellHanlder];
}

- (void)configureStepperCell:(BPKStepperCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureStepperCell:cell atIndexPath:indexPath forItem:item];
  
  __weak typeof(self) weakSelf = self;
  cell.didChangeValueHandler = ^(id newValue) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    
    [item updateValue:newValue];
    if ([item isReminderHeadwayItem]) {
      DLog(@"setting reminder headway to %@", newValue);
      strongSelf.manager.reminderHeadway = [newValue integerValue];
    }
  };
}

- (void)configureSwitchCell:(BPKSwitchCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureSwitchCell:cell atIndexPath:indexPath forItem:item];
  
  __weak typeof(self) weakSelf = self;
  cell.didChangeValueHandler = ^(id newValue) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf || ! [item isSwitchItem]) return;
    
    [item updateValue:newValue];
    
    if ([item isReminderItem]) {
      strongSelf.manager.wantsReminder = [newValue boolValue];
      NSArray *sections = [BPKFormBuilder buildSectionsFromForm:strongSelf.form];
      NSArray *reminder = [BPKFormBuilder buildReminderSectionWithManager:strongSelf.manager];
      if (reminder) {
        sections = [sections arrayByAddingObjectsFromArray:reminder];
      }
      strongSelf.sections = sections;
      [strongSelf.tableView reloadData];
    }
  };
}

- (void)configureDatePickerCell:(BPKDatePickerCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureDatePickerCell:cell atIndexPath:indexPath forItem:item];
  
  __weak typeof(self) weakSelf = self;
  cell.didChangeValueHandler = ^(id newValue) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    
    if ([newValue isKindOfClass:[NSDate class]]) {
      NSDate *newDate = (NSDate *)newValue;
      NSTimeInterval since1970 = [newDate timeIntervalSince1970];
      [item updateValue:@(since1970)];
      NSIndexPath *dateTimeItemIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
      [strongSelf.tableView reloadRowsAtIndexPaths:@[dateTimeItemIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
  };
}

- (void)configureTextfieldCell:(BPKTextFieldCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureTextfieldCell:cell atIndexPath:indexPath forItem:item];
  
  if ([cell respondsToSelector:@selector(setTextFieldShouldReturnBlock:)]) {
    [cell setTextFieldShouldReturnBlock:[self.textFieldHelper shouldReturnBlockForIndexPath:indexPath]];
  }
  
  if ([cell respondsToSelector:@selector(setTextFieldDidEndEditingBlock:)]) {
    [cell setTextFieldDidEndEditingBlock:[self.textFieldHelper didEndEditingBlockForIndexPath:indexPath]];
  }
}

- (void)configureTextCell:(BPKTextCell *)cell atIndexPath:(NSIndexPath *)indexPath forItem:(BPKSectionItem *)item
{
  [super configureTextCell:cell atIndexPath:indexPath forItem:item];
}

#pragma mark - User interactions

- (void)cancelButtonPressed:(id)sender
{
#pragma unused (sender)
  [self.delegate bookingViewController:self didComplete:NO withManager:self.manager];
}

- (void)nextButtonPressed:(id)sender
{
#pragma unused (sender)
  [self performAction];
}


#pragma mark - Private: Modifying bookings

- (NSDictionary *)postDataToCancelBooking
{
  NSMutableDictionary *postData = [NSMutableDictionary dictionary];
  NSDictionary *emailFormField = [[BPKUser sharedUser] emailFormField];
  
  if (! emailFormField) {
    return postData;
  } else {
    NSArray *fields = [NSArray arrayWithObject:emailFormField];
    [postData setObject:fields forKey:@"input"];
    return postData;
  }
}

#pragma mark - Private: Notifications

- (void)keyboardDidShow:(NSNotification *)notification
{
  // restore to the default behavior.
  self.textFieldHelper.disableMoveToNextOnReturn = NO;
  
  NSDictionary* info = [notification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardDidHide:(NSNotification *)notification
{
#pragma unused (notification)
  if (self.textFieldHelper.willMoveToNext) {
    return;
  }
  
  UIEdgeInsets contentInsets = self.actionOverlay ? UIEdgeInsetsMake(0, 0, self.actionOverlay.frame.size.height, 0) : UIEdgeInsetsZero;
  self.tableView.contentInset = contentInsets;
  self.tableView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - Private: Forms

- (void)requestForm:(void(^)(void))completion
{
  __weak typeof(self) weakSelf = self;
  
  [KVNProgress showWithStatus:self.progressText];
  
  [BPKServerUtil requestFormForBookingURL:self.bookingURL
                                 postData:self.postData
                               completion:
   ^(NSInteger status, NSDictionary<NSString *, id> *headers, NSDictionary *rawForm, NSData *data, NSError *error) {
#pragma unused(status, headers, data)
     __strong typeof(weakSelf) strongSelf = weakSelf;
     if (! strongSelf) return;
     
     [KVNProgress dismiss];
     
     if (error != nil) {
       // server error
       [self handle:error defaultDismissHandler:^(UIAlertAction * _Nonnull action) {
         [strongSelf.navigationController popViewControllerAnimated:YES];
       }];
//       [self handle:error];
       
     } else if (rawForm != nil) {
       if ([BPKForm canBuildFormFromRawObject:rawForm]) {
         BPKForm *form = [[BPKForm alloc] initWithJSON:rawForm];
         [strongSelf setForm:form];
         [strongSelf loadForm];
       } else {
         // user error.
         NSDictionary *userError = rawForm;
         NSString *message = [NSString stringWithFormat:@"%@, code: %@", userError[@"error"], userError[@"errorCode"]];
         [BPKHelpers presentAlertFromController:strongSelf withMessage:message];
       }
       
     } else {
       // No form and no error means we've reached the end
       [strongSelf.delegate bookingViewController:strongSelf didComplete:YES withManager:strongSelf.manager];
       
     }
     
     if (completion) {
       completion();
     }
   }];
}

- (void)loadForm
{
  ZAssert(self.form != nil, @"Cannot find a valid form");
  ZAssert(self.form.isClientSideOAuth == NO, @"Booking VC is not intended to work with client-side OAuth form");
  
  self.title = self.form.title;
  
  if (self.form.isBookingForm || self.form.isOAuthForm) {
    __block NSArray *sections = [BPKFormBuilder buildSectionsFromForm:self.form];
    
    if ([self.form isLast]) {
      NSURL *updatingURL = self.form.refreshURLForSourceObject;
      if (updatingURL != nil) {
        NSString *message = Loc.UpdatingTrip;
        [KVNProgress showWithStatus:message onView:self.view];
        
        [self.delegate bookingViewController:self
                 requestsDismissalWithUpdate:updatingURL];
        
      } else {
        [self loadConfirmationFormWithSections:sections];
      }
      
      return;
      
    } else {
      if ([self.form isRefreshable]) {
        NSURL *url = [self.form refreshURL];
        if (url != nil) {
          self.bookingURL = url;
          [self requestForm:nil];
          return;
        }
        
      } else if ([self.form shoudLoadExternalLinkAutomatically]) {
        BPKSectionItem *item = [self.form externalItem];
        if (! item) {
          ZAssert(false, @"External item should not be nil if we can load external link automatically");
          return;
        }
        
        [self processExternalItem:item];
        
        // Load sections anyways, as user might come back to it.
        [self setSections:sections];
        
      } else {
        BPKSectionItem *item = [[BPKSectionItem alloc] init];
        if ((sections.count == 1) && ([sections[0] visibleItems].count == 1)) {
            item = [sections[0] visibleItems][0];
        }
        if ([item.itemId isEqualToString:@"oauth"]) {
          // We need a booking URL. @Brian: Can you explain why?
          self.bookingURL = self.bookingURL ?: self.form.actionURL;
          
          BPKWebViewController *webCtr = [[BPKWebViewController alloc] initWithTitle:item.title URL:[NSURL URLWithString:item.value]];
          webCtr.isForOAuth = YES;
          webCtr.delegate = self;
          [self.navigationController pushViewController:webCtr animated:YES];
        }
        
        [self setSections:sections];
      }
    }
    
  } else if (self.form.isPaymentForm) {
    BPKCost *cost = [[BPKCost alloc] initWithJSON:[self.form paymentJSON]];
    [self setSections:[BPKFormBuilder buildSectionsFromCost:cost]];
  }
  
  [self.tableView reloadData];
  [self parseActionItemInForm:self.form];
}

- (void)refreshFormWithURL:(NSURL *)url
{
  self.bookingURL = url;
  self.postData = nil;
  [self requestForm:nil];
}

- (void)parseActionItemInForm:(BPKForm *)form
{
  if (! [form hasAction]) {
    return;
  }
  
  NSString *title = [form actionTitle];
  NSURL *url = [form actionURL];
  
  if ([form isLast]) {
    return;
  }
  
  if ([form isActionEnabled]) {
    self.nextBookingURL = url;
    
    __weak typeof(self) weakSelf = self;
    void (^actionBlock)(void) = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf) {
        [strongSelf nextButtonPressed:nil];
      }
    };
    
    BPKActionOverlay *actionOverlay = [[BPKActionOverlay alloc] initWithTitle:title actionBlock:actionBlock];
    [actionOverlay showInView:self.view completion:^(BOOL finished) {
      if (finished) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, actionOverlay.frame.size.height, 0);
      }
    }];
    self.actionOverlay = actionOverlay;
  }
}

- (void)loadConfirmationFormWithSections:(NSArray *)sections
{
  self.sections = sections;
  [self.tableView reloadData];
  [self.navigationItem setHidesBackButton:[self.form isLast]];
  [self.navigationItem setLeftBarButtonItem:nil];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:Loc.Done
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(nextButtonPressed:)];
}

- (void)performAction {
  if ([self.form isLast]) {
    if ([self.form isCancelled]) {
      [self.delegate bookingViewControllerDidCancelBooking:self];
    } else {
      [self.delegate bookingViewController:self didComplete:YES withManager:self.manager];
    }
    
  } else if ([self.form requiresOAuth]) {
    ZAssert(false, @"Can't handle OAuth!");
    
  } else {
    NSDictionary *input = [BPKFormBuilder buildFormFromSections:self.sections];
    if (! input) {
      [self processInvalidItemsInSections:self.sections];
      
    } else {
      ZAssert(self.manager != nil, @"Cannot find a valid booking manager");
      
      if (self.form.isBookingForm) {
        NSArray *inputarray = input[@"input"];
        if (inputarray.count == 1 && [[inputarray[0] objectForKey:@"id"] isEqualToString:@"productId"]) {
          _bookingURL = self.nextBookingURL;
          _postData = input;
          [self requestForm:nil];
        } else {
          [self load:self.nextBookingURL data:input];
        }
      }
    }
  }
}

#pragma mark - Private: Form items

- (DidSelectLabelCellHandler)didSelectLabelCellHanlder
{
  __weak typeof(self) weakSelf = self;
  
  return ^(BPKSectionItem *anItem) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (! strongSelf) return;
    
    if ([anItem isAddressItem]) {
      [strongSelf processAddressItem:anItem];
      
    } else if (! anItem.isReadOnly) {
      if ([anItem isDateItem]) {
        [strongSelf insertOrDeleteExtraRow];
        
      } else if ([anItem isOptionItem]) {
        [strongSelf processOptionItem:anItem];
        
      } else if ([anItem isLinkItem]) {
        [strongSelf processLinkItem:anItem withDisregardURL:strongSelf.form.disregardURL];
        
      } else if ([anItem isExternalItem]) {
        [strongSelf processExternalItem:anItem];
        
      } else if ([anItem isFormItem]) {
        [strongSelf processFormItem:anItem];
      }
    }
  };
}

- (void)processAddressItem:(BPKSectionItem *)item
{
  if (! [item isAddressItem] || ! [item annotation]) {
    return;
  }
  
  SGKNamedCoordinate *annotation = [item annotation];
  BPKMapViewController *mapController = [[BPKMapViewController alloc] init];
  mapController.annotation = annotation;
  [self.navigationController pushViewController:mapController animated:YES];
}

- (void)processFormItem:(BPKSectionItem *)item
{
  if (! [item isFormItem] || ! [item.value isKindOfClass:[NSDictionary class]]) {
    return;
  }
  
  [self load:item.value];
}

- (void)processOptionItem:(BPKSectionItem *)item
{
  BPKOptionsViewController *optionCtr = [[BPKOptionsViewController alloc] initWithItem:item];
  optionCtr.delegate = self;
  [self.navigationController pushViewController:optionCtr animated:YES];
}

- (void)processLinkItem:(BPKSectionItem *)item withDisregardURL:(NSURL *)disregardURL
{
  if (! [item isLinkItem] || ! [item.value isKindOfClass:[NSString class]]) {
    return;
  }
  
  NSURL *url = [NSURL URLWithString:item.value];
  
  if ([item isRefreshableItem]) {
    [self refreshFormWithURL:url];
    
  } else if ([item isCancelBookingItem]) {
    [self processCancellationItemWithURL:url];
    
  } else if ([item isPayBookingItem]) {
    ZAssert(false, @"Not implemented.");
    
  } else {
    BPKWebViewController *webCtr = [[BPKWebViewController alloc] initWithTitle:[item title] startURL:url trackURL:disregardURL];
    webCtr.delegate = self;
    [self.navigationController pushViewController:webCtr animated:YES];
    
    if ([item isPayBookingItem]) {
      self.isAwaitingPayment = YES;
    }
  }
}

- (void)processExternalItem:(BPKSectionItem *)item
{
  if (! [item isExternalItem] || ! [item externalURL]) {
    ZAssert(false, @"Item is not of `external` type or missing external URL");
    return;
  }
  
  BPKWebViewController *webCtr = [[BPKWebViewController alloc] initWithTitle:[item title] startURL:item.externalURL trackURL:item.disregardURL];
  webCtr.delegate = self;
  [self.navigationController pushViewController:webCtr animated:YES];
  
  self.nextBookingURL = item.nextURL;
  self.progressText = item.nextHUD;
}

- (void)processCancellationItemWithURL:(NSURL *)url
{
  self.bookingURL = url;
  self.postData = [self postDataToCancelBooking];
  self.lastSelectedIndexPath = nil;
  [self requestForm:nil];
}

- (void)processInvalidItemsInSections:(NSArray *)sections
{
  NSArray *indexPaths = [BPKFormBuilder indexPathsForInvalidItemsInSections:sections];
  
  BOOL missingValue = NO;
  BOOL missingTC = NO;
  BOOL missingInsuranceTC = NO;
  
  for (NSIndexPath *indexPath in indexPaths) {
    BPKSectionItem *item = [self itemForIndexPath:indexPath];
    BPKCell *cell = (BPKCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    // Note that, when cells are off screen, 'cell' will be nil and as such, we
    // must check whether an item requires a specific cell, rather than checking
    // if the cell is of particular class.
    if ([item requiresTextfieldCell]) {
      missingValue = YES;
      
      BPKTextFieldCell *textfieldCell = (BPKTextFieldCell *)cell;
      [textfieldCell highlightPlaceholder:YES];
      
    } else if ([item requiresSwitchCell]) {
      missingTC = [item isBookingTCItem];
      missingInsuranceTC = [item isInsuranceTCItem];
    }
  }
  
  if (missingValue) {
    [BPKHelpers presentAlertFromController:self withMessage:Loc.ValuesMissing];
    
  } else if (missingTC) {
    [BPKHelpers presentAlertFromController:self withMessage:Loc.YouNeedToAgreeToTheBookingTerms];
    
  } else if (missingInsuranceTC) {
    [BPKHelpers presentAlertFromController:self withMessage:Loc.YouNeedToAgreeToTheInsuranceTerms];

  }
}

#pragma mark - BPKOptionViewControllerDelegate

- (void)optionViewController:(BPKOptionsViewController *)ctr didSelectItemAtIndex:(NSInteger)index
{
#pragma unused (ctr)
  BPKSectionItem *item = [self itemForIndexPath:self.lastSelectedIndexPath];
  
  // The available values.
  NSArray *values = item.values;
  if ((unsigned)index < values.count) {
    id value = values[index];
    [item updateValue:value];
  }
  
  [self.tableView reloadRowsAtIndexPaths:@[ self.lastSelectedIndexPath ] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - BPKWebViewControllerDelegate

- (void)webControllerDidFinishOauthWithSuccess:(BOOL)success
{
  if (success) {
    [self.navigationController popToViewController:self animated:YES];
    [KVNProgress showWithStatus:@"Connecting to provider..."];
    [self requestForm:^{
      [KVNProgress dismiss];
    }];
  }
}

- (void)webViewController:(SGWebViewController *)ctr capturedTrackURL:(NSURL *)url
{
#pragma unused (url)
  if (self.navigationController.topViewController == ctr) {
    [self.navigationController popToViewController:self animated:NO];
  }
  [self performAction];
}

#pragma mark - Gesture recognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
#pragma unused(gestureRecognizer)
  if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]]) {
    return NO;
  } else {
    return YES;
  }
}

@end
