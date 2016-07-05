//
//  YelpBusiness.swift
//  typps
//
//  Created by Monte with Pillow on 7/5/16.
//  Copyright © 2016 Monte Thakkar. All rights reserved.
//

import UIKit

class YelpBusiness: NSObject {
    let name: String?
    let address: String?
    let imageURL: NSURL?
    let categories: String?
    let distance: String?
    let ratingImageURL: NSURL?
    let reviewCount: NSNumber?
    let id: String?
    let offset: NSNumber?
    let limit: NSNumber?
    let latitude: NSNumber?
    let longitude: NSNumber?
    
    init(dictionary: NSDictionary) {
        name = dictionary["name"] as? String
        
        id = dictionary["id"] as? String
        
        let imageURLString = dictionary["image_url"] as? String
        if imageURLString != nil {
            imageURL = NSURL(string: imageURLString!)!
        } else {
            imageURL = nil
        }
        
        let location = dictionary["location"] as? NSDictionary
        var address = ""
        var latitude : NSNumber?
        var longitude : NSNumber?
        if location != nil {
            let addressArray = location!["address"] as? NSArray
            if addressArray != nil && addressArray!.count > 0 {
                address = addressArray![0] as! String
            }
            
            let coordinates = location!["coordinate"] as? NSDictionary
            latitude = coordinates!["latitude"] as? NSNumber
            longitude = coordinates!["longitude"] as? NSNumber
            
            let neighborhoods = location!["neighborhoods"] as? NSArray
            if neighborhoods != nil && neighborhoods!.count > 0 {
                if !address.isEmpty {
                    address += ", "
                }
                address += neighborhoods![0] as! String
            }
        }
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        
        let categoriesArray = dictionary["categories"] as? [[String]]
        if categoriesArray != nil {
            var categoryNames = [String]()
            for category in categoriesArray! {
                let categoryName = category[0]
                categoryNames.append(categoryName)
            }
            categories = categoryNames.joinWithSeparator(", ")
        } else {
            categories = nil
        }
        
        let distanceMeters = dictionary["distance"] as? NSNumber
        if distanceMeters != nil {
            let milesPerMeter = 0.000621371
            distance = String(format: "%.2f mi", milesPerMeter * distanceMeters!.doubleValue)
        } else {
            distance = nil
        }
        
        let ratingImageURLString = dictionary["rating_img_url_large"] as? String
        if ratingImageURLString != nil {
            ratingImageURL = NSURL(string: ratingImageURLString!)
        } else {
            ratingImageURL = nil
        }
        
        reviewCount = dictionary["review_count"] as? NSNumber
        
        offset = dictionary["offset"] as? NSNumber
        
        limit = dictionary["limit"] as? NSNumber
    }
    
    class func businesses(array array: [NSDictionary]) -> [YelpBusiness] {
        var businesses = [YelpBusiness]()
        for dictionary in array {
            let business = YelpBusiness(dictionary: dictionary)
            businesses.append(business)
        }
        return businesses
    }
    
    class func searchWithTerm(term: String, completion: ([YelpBusiness]!, NSError!) -> Void) {
        YelpClient.sharedInstance.searchWithTerm(term, completion: completion)
    }
    
    class func searchWithTerm(term: String, latitude: NSNumber?, longitude: NSNumber?,  sort: YelpSortMode?, categories: [String]?, deals: Bool?, offset: Int?, limit: Int?, completion: ([YelpBusiness]!, error: NSError!) -> Void) -> Void {
        YelpClient.sharedInstance.searchWithTerm(term, latitude: latitude, longitude: longitude, sort: sort, categories: categories, deals: deals, offset: offset, limit: limit, completion: completion)
    }

}
