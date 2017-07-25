//
//  SGKConstants.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#ifndef TripKit_SGKConstants_h
#define TripKit_SGKConstants_h

// Strong and weak references
#define SGKWeakSelf weakSelf
#define SGKStrongSelf strongSelf
#define SGKPrepareWeakSelf() __weak typeof(self) SGKWeakSelf = self
#define SGKPrepareStrongSelf() __strong typeof(SGKWeakSelf) SGKStrongSelf = SGKWeakSelf; if (! SGKStrongSelf) return

#endif
