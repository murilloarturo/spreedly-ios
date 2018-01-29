//
//  SpreedlyAPIClient.swift
//  Spreedly
//
//  Created by David Santoso on 9/22/15.
//  Copyright © 2015 Spreedly Inc. All rights reserved.
//

import Foundation
import PassKit

open class SpreedlyAPIClient: NSObject {
    public typealias SpreedlyAPICompletionBlock = (_ paymentMethod: PaymentMethod?, _ error: NSError?) -> Void
    
    open var environmentKey: String
    open var apiUrl: String
    
    public init(environmentKey: String, apiUrl: String) {
        self.environmentKey = environmentKey
        self.apiUrl = apiUrl
    }
    
    convenience public init(environmentKey: String) {
        let apiUrl = "https://core.spreedly.com/v1/payment_methods.json"
        self.init(environmentKey: environmentKey, apiUrl: apiUrl)
    }
    
    open func createPaymentMethodTokenWithCreditCard(_ creditCard: CreditCard, completion: @escaping SpreedlyAPICompletionBlock) {
        let serializedRequest = RequestSerializer.serialize(creditCard)
        
        if serializedRequest.error == nil {
            if let data = serializedRequest.data {
                self.createPaymentMethodTokenWithData(data, completion: completion)
            }
        }
    }
    
    open func createPaymentMethodToken(with creditCard: CreditCard, usingEmail email: String, completion: @escaping SpreedlyAPICompletionBlock) {
        let serializedRequest = RequestSerializer.serialize(creditCard, usingEmail: email)
        
        if serializedRequest.error == nil {
            if let data = serializedRequest.data {
                self.createPaymentMethodTokenWithData(data, completion: completion)
            }
        }
    }
    
    open func createPaymentMethodTokenWithApplePay(_ payment: PKPayment, completion: @escaping SpreedlyAPICompletionBlock) {
        self.createPaymentMethodTokenWithData(RequestSerializer.serialize(payment.token.paymentData), completion: completion)
    }

    func createPaymentMethodTokenWithData(_ data: Data, completion: @escaping SpreedlyAPICompletionBlock) {
        let url = URL(string: apiUrl + "?environment_key=\(self.environmentKey)")

        var request = URLRequest(url: url!)
        let session = URLSession.shared

        request.httpBody = data
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("spreedly-ios-lib/0.1.0", forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if (error != nil) {
                DispatchQueue.main.async(execute: {
                    completion(nil, error as NSError?)
                })
            } else {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary {
                        if let transactionDict = json["transaction"] as? NSDictionary {
                            if let paymentMethodDict = transactionDict["payment_method"] as? [String: AnyObject] {
                                let paymentMethod = PaymentMethod(attributes: paymentMethodDict)
                                DispatchQueue.main.async(execute: {
                                    completion(paymentMethod, nil)
                                })
                            }
                        } else {
                            if let errors = json["errors"] as? NSArray {
                                let error = errors[0] as! NSDictionary
                                let userInfo = ["SpreedlyError": error["message"]!]
                                let apiError = NSError(domain: "com.spreedly.lib", code: 60, userInfo: userInfo)
                                DispatchQueue.main.async(execute: {
                                    completion(nil, apiError)
                                })
                            }
                        }
                    }
                } catch let parseError as NSError {
                    DispatchQueue.main.async(execute: {
                        completion(nil, parseError)
                    })
                }
            }
        }) 
        
        task.resume()
    }
}
