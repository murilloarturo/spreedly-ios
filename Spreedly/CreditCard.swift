//
//  CreditCard.swift
//  Spreedly
//
//  Created by David Santoso on 10/8/15.
//  Copyright © 2015 Spreedly Inc. All rights reserved.
//

import Foundation

open class CreditCard: NSObject {
    open var firstName, lastName, fullName, number, verificationValue, month, year: String?
    open var address1, address2, city, state, zip, country, phoneNumber: String?
    
    public override init() {}
}
