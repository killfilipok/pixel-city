//
//  Constants.swift
//  pixel-city
//
//  Created by Philip on 3/20/19.
//  Copyright © 2019 Philip. All rights reserved.
//

import Foundation

let apiKey = "bf8e55ff0b817a9184cbb7474edd307a"
let secret = "97d7af3940081139"

func flickrURL(forApiKey key :String, withAnnotation annotation: DroppablePin, andNumOfPhotos photosNum: Int) -> String{
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=ml&per_page=\(photosNum)&page=1&format=json&nojsoncallback=1"
    return url
}

