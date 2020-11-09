//
//  TKPolylineDecoderTest.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 15/07/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import XCTest

@testable import TripKit

class TKPolylineDecoderTest: XCTestCase {

  func testDecodeAdelaide()
  {
    let encoded = "boctEi`_mYF?UaKZCxEe@???Tt@ExAEr@ChCGCY@g@F]FQV[NGLCREpAGbBGtGUjCIj@I???DPA|AGhHSbCQ???BrCGrLe@??MBLA`GOfAS???Nz@AlCEd@BpDY???JdHSrAKjAqC??FFxCsF~AyC\\\\m@p@}@\\\\k@d@{A??HF~C}Fr@sB??HHbDiGrEuJ??HH~@eBjAaChAkC??FDZo@tAaCrAeC|BG~@U???LvFQ~C]???NnEOzCKrA[???RfDKlE[???JtAEnHW~DW???FlBGnKi@???FLAdIW`EW???FtJ[xBS???FvBG|BGta@mApCW???J|AGrFQnCU???HdBGjEU???H`GOn@D`@TZ\\\\\\\\zA`@|A??IBDRNpAR~@bErE??IHNPd@~@FvAHfBLlA??I?DrBHbGeEb@???Qa@@Q@wBL]XMj@PlA??K?JlFEf@NnE??G?HrGRrA"
    
    let decoded = CLLocationCoordinate2D.decodePolyline(encoded)
    XCTAssertFalse(decoded.isEmpty)
  }
  
  func testDecodeSydCycling()
  {
    let encoded = "rx}mEaq}y[??sDzC????AAE?CCCBC?????ADAD@D?D????WP]NyBp@????}@RUL_BpA????qAjAIXIdA??????ENIHM?????yDe@UCWC????M@????MB????ARCP??????Ot@????a@bG????Q`C????Y|C????IfAKjA????@d@D\\\\JVT\\\\\\\\R??????PF????ARIFSt@Qx@g@vE????m@bBEJ????EHKF????_@b@CDCR????Af@????G`@????AP??????QpCDX??????@ZKnA??????WF????{ItB????OB??????CS????MD????Ic@????g@J????{B\\\\WBYD????iB\\\\????{Bd@????AHCFE?????E?GK????eG~@?????FCFG@????E?EK??????}E~@????mH_A????Gn@W~DOfB??????oC[??????UxC????]E]EeAM????kC[yDYaEo@??????Kl@MN??????i@K????[?}@F??????]zD????IbA????E\\\\????Af@????Gf@????Eb@????QxBGb@??????]EoAD????E?????u@@????wA@????gBF????cAB????kA@????sAD????gGR??????UF??????@Z@\\\\????FpDB`E????HnG??????wE??";
    
    let decoded = CLLocationCoordinate2D.decodePolyline(encoded)
    XCTAssertFalse(decoded.isEmpty)
  }
  
  func testDecodeSydDrive()
  {
    let encoded = "l`bmEipcz[??JQVkA????NOZkATw@??????FZR\\\\FFTJX@P?RKTONWFOA]Ca@Qg@q@qBo@cBKsAL_Bv@yC????VcAj@gC????DSHs@CgA[s@oAa@????Of@}@hC_@`Ag@xA_@bB]|BKhC????EAmAMoAQ????EHE?E???????C`@u@xG????CJ????St@aFpG????w@t@????o@\\\\????u@XeAXq@Rs@VqAr@{CzA????gAj@????mAX????oBh@????[uCQi@]_@c@O{@U{A]k@AaDNmAF[FWZQ^OdDErB????UH????_@LSNM`@If@IdA????C|@????In@G\\\\????BHBLAFAHGDGB????E?GAGECG????[D{@?oH_A????QI?????FCFEDE@G?EA??????E`@????YnEKbAITIFQF??????Dl@Bv@BjBEnBO|B????eArP????w@bF????[tD????CV????OlB????YvC????SjB????UdC????UpC????_@`FUdDE`AE~@Ct@????Bl@Dv@JrAL`AXhAXn@f@~@nA|A????\\\\Z|@x@n@l@^h@????jB`Dd@v@????nAvB????LV????nDbG\\\\l@\\\\b@XXXR????`Aj@????hAl@|@`@pD`B????jGpC????zBjA????l@`@n@t@h@|@l@lBNp@P`B????BD????AdA?r@????It@StA????eAdE????]`B????[~AStAE~@C`A?rB????DhE@zA????NhBZ~A????n@`Bt@lAd@h@b@d@r@b@fCbB????fCjB????nGfE????\\\\RdBjAxCnBhAj@|@Pr@Fp@Cj@GnAa@dAo@|AcArA{@v@]p@Od@Iz@Ex@B|ANfATnA`@l@Rj@\\\\d@X????`@X`@Zf@\\\\n@l@~@bAz@dAf@v@\\\\r@Xh@v@jBJ\\\\\\\\dAh@`Cz@~Ez@|Ed@dC????d@zBZpAn@lBjAzBlAtAn@h@p@\\\\??????ZRVLhAV`@Ht@@????hAGdASVM????JA????pFkB????JC????XElAIp@A????JB~@Hp@V|@\\\\x@j@????\\\\b@j@|@JZ??????^z@lA~F????`BtH????zB~K????vAtG????l@nCBj@????F\\\\????t@hD????Nt@@H????bBo@????h@OzBy@bA_@????vDsA????`DgA??????nBlH????\\\\xC????tCnL??????vAg@????bA]????^M????NEtAe@????nAc@????tAc@????PG????r@W????RGb@Od@Q????zAg@????jGwB????`Bk??";
    
    let decoded = CLLocationCoordinate2D.decodePolyline(encoded)
    XCTAssertFalse(decoded.isEmpty)
  }

}
