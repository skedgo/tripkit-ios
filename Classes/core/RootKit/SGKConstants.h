//
//  SGKConstants.h
//  TripGo
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#ifndef TripGo_SGKConstants_h
#define TripGo_SGKConstants_h

// Strong and weak references
#define SGKWeakSelf weakSelf
#define SGKStrongSelf strongSelf
#define SGKPrepareWeakSelf() __weak typeof(self) SGKWeakSelf = self
#define SGKPrepareStrongSelf() __strong typeof(SGKWeakSelf) SGKStrongSelf = SGKWeakSelf; if (! SGKStrongSelf) return

#define TripGo_Color [UIColor colorWithRed:10/255.f green:30/255.f blue:50/255.f alpha:1];

#endif
