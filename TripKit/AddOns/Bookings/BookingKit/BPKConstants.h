//
//  BPKConstants.h
//  TripKit
//
//  Created by Kuan Lun Huang on 2/02/2015.
//
//

#ifndef TripKit_BPKConstants_h
#define TripKit_BPKConstants_h

// ---------------- Booking JSON ----------------

static NSString *const kBPKForm               = @"form";
static NSString *const kBPKFormType           = @"type";

static NSString *const kBPKFormTitle          = @"title";
static NSString *const kBPKFormSubTitle       = @"subtitle";
static NSString *const kBPKFormFooter         = @"footer";
static NSString *const kBPKFormFields         = @"fields";

static NSString *const kBPKFormId             = @"id";
static NSString *const kBPKFormValue          = @"value";
static NSString *const kBPKFormLat            = @"lat";
static NSString *const kBPKFormLng            = @"lng";
static NSString *const kBPKFormAddress        = @"address";
static NSString *const kBPKFormName           = @"name";
static NSString *const kBPKFormMinValue       = @"minValue";
static NSString *const kBPKFormMaxValue       = @"maxValue";
static NSString *const kBPKFormAllValues      = @"allValues";
static NSString *const kBPKFormPlaceholder    = @"placeholder";
static NSString *const kBPKFormRequired       = @"required";
static NSString *const kBPKFormReadOnly       = @"readOnly";
static NSString *const kBPKFormRefreshable    = @"refresh";
static NSString *const kBPKFormHidden         = @"hidden";
static NSString *const kBPKFormKeyboardType   = @"keyboardType";

// Field types
static NSString *const kBPKFormTypeAddress      = @"ADDRESS";
static NSString *const kBPKFormTypeDatetime     = @"DATETIME";
static NSString *const kBPKFormTypeTime         = @"TIME";
static NSString *const kBPKFormTypeStepper      = @"STEPPER";
static NSString *const kBPKFormTypeOption       = @"OPTION";
static NSString *const kBPKFormTypeString       = @"STRING";
static NSString *const kBPKFormTypePassword     = @"PASSWORD";
static NSString *const kBPKFormTypeSwitch       = @"SWITCH";
static NSString *const kBPKFormTypeLink         = @"LINK";
static NSString *const kBPKFormTypeExternal     = @"EXTERNAL";
static NSString *const kBPKFormTypeText         = @"TEXT";
static NSString *const kBPKFormTypeBookingForm  = @"bookingForm";
static NSString *const kBPKFormTypePaymentForm  = @"paymentForm";

// Field ids
static NSString *const kBPKFormIdMessage        = @"message";
static NSString *const kBPKFormIdReminder       = @"reminder";
static NSString *const kBPKFormIdHeadway        = @"headway";
static NSString *const kBPKFormIdBookingStatus  = @"booking_status";
static NSString *const kBPKFormIdCancelBooking  = @"cancel_booking";
static NSString *const kBPKFormIdPayBooking     = @"pay_booking";
static NSString *const kBPKFormIdUpdateBooking  = @"update_status";

static NSString *const kBPKFormIdEmail        = @"email";
static NSString *const kBPKFormIdPassword     = @"password";
static NSString *const kBPKFormIdName         = @"name";
static NSString *const kBPKFormIdFirstName    = @"first_name";
static NSString *const kBPKFormIdLastName     = @"last_name";

static NSString *const kBPKFormIdCalendar     = @"calendar";

static NSString *const kBPKFormIdTCLink       = @"termsLink";
static NSString *const kBPKFormIdTC           = @"acceptTermsAndConditions";
static NSString *const kBPKFormIdInsuranceTC  = @"insuranceTermsAndConditions";

// Keyboard types
static NSString *const kBPKKeyboardTypeText   = @"TEXT";
static NSString *const kBPKKeyboardTypeEmail  = @"EMAIL";
static NSString *const kBPKKeyboardTypePhone  = @"PHONE";
static NSString *const kBPKKeyboardTypeNumber = @"NUMBER";
static NSString *const kBPKKeyboardTypeNumPun = @"NUMPUN"; // number and punctuation.

// Booking status
static NSString *const kBPKBookingStatusPending   = @"pending";
static NSString *const kBPKBookingStatusConfirmed = @"confirmed";
static NSString *const kBPKBookingStatusCancelled = @"cancelled";

// ---------------- Payment JSON ----------------

static NSString *const kBPKPayment            = @"payment";

static NSString *const kBPKPaymentCost        = @"price";

// Payment types
static NSString *const kBPKPaymentType        = @"paymentTypes";
static NSString *const kBPKPaymentTypeCC      = @"creditcard";
static NSString *const kBPKPaymentTypePaypal  = @"paypal";

#endif
