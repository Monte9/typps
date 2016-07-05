//
//  YelpClient.swift
//  typps
//
//  Created by Monte with Pillow on 7/5/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit

import AFNetworking
import BDBOAuth1Manager

// Yelp API keys
let yelpConsumerKey = "lQBp5PeOpzJKakjpEp8L-A"
let yelpConsumerSecret = "pSSWbg0VQrXSYKZlE8eMx1PRQw4"
let yelpToken = "HKa04knsXYfaS3WG6DufekH5PCAQwpm6"
let yelpTokenSecret = "OahlVq-pIHcPz9ia069scW4AZCY"

enum YelpSortMode: Int {
    case BestMatched = 0, Distance, HighestRated
}

class YelpClient: BDBOAuth1RequestOperationManager {
    var accessToken: String!
    var accessSecret: String!
    
    class var sharedInstance : YelpClient {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : YelpClient? = nil
        }
        
        dispatch_once(&Static.token) {
            Static.instance = YelpClient(consumerKey: yelpConsumerKey, consumerSecret: yelpConsumerSecret, accessToken: yelpToken, accessSecret: yelpTokenSecret)
        }
        return Static.instance!
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(consumerKey key: String!, consumerSecret secret: String!, accessToken: String!, accessSecret: String!) {
        self.accessToken = accessToken
        self.accessSecret = accessSecret
        let baseUrl = NSURL(string: "https://api.yelp.com/v2/")
        super.init(baseURL: baseUrl, consumerKey: key, consumerSecret: secret);
        
        let token = BDBOAuth1Credential(token: accessToken, secret: accessSecret, expiration: nil)
        self.requestSerializer.saveAccessToken(token)
    }
    
    func searchWithTerm(term: String, completion: ([YelpBusiness]!, NSError!) -> Void) -> AFHTTPRequestOperation {
        return searchWithTerm(term, latitude: nil, longitude: nil,sort: nil, categories: nil, deals: nil, offset: nil, limit: nil, completion: completion)
    }
    
    func searchWithTerm(term: String, latitude: NSNumber?, longitude: NSNumber?, sort: YelpSortMode?, categories: [String]?, deals: Bool?, offset: Int?, limit: Int?, completion: ([YelpBusiness]!, NSError!) -> Void) -> AFHTTPRequestOperation {
        // For additional parameters, see http://www.yelp.com/developers/documentation/v2/search_api
        
        // Default the location to San Francisco
        var parameters: [String : AnyObject] = ["term": term, "ll": "\(latitude as! Double!),\(longitude as! Double!)"]
        //  print(parameters)
        
        if sort != nil {
            parameters["sort"] = sort!.rawValue
        }
        
        if limit != nil {
            parameters["limit"] = limit!
        }
        
        if categories != nil && categories!.count > 0 {
            parameters["category_filter"] = (categories!).joinWithSeparator(",")
        }
        
        if offset != nil {
            parameters["offset"] = offset!
        }
        
        if deals != nil {
            parameters["deals_filter"] = deals!
        }
        
        print(parameters)
        
        return self.GET("search", parameters: parameters, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
            let dictionaries = response["businesses"] as? [NSDictionary]
            if dictionaries != nil {
                completion(YelpBusiness.businesses(array: dictionaries!), nil)
            }
            }, failure: { (operation: AFHTTPRequestOperation?, error: NSError!) -> Void in
                completion(nil, error)
        })!
    }
    
}
