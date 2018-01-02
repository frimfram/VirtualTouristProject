//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jean Ro on 12/30/17.
//  Copyright © 2017 Jean Ro. All rights reserved.
//

import Foundation

class FlickrClient {

    static let shared:FlickrClient = FlickrClient()
    
    func searchPhotos(_ longitude: Double, _ latitude: Double, _ pageNumber: Int = 1,
                      handler: @escaping (_ result: [String]?, _ pageNumber: Int?, _ error: NSError?) -> Void) {
        
        let methodParameters = [
            FlickrParameterKeys.Method: Methods.Search,
            FlickrParameterKeys.APIKey: Constants.APIKey,
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.SquareURL,
            FlickrParameterKeys.Format: FlickrParameterValues.Json,
            FlickrParameterKeys.NoJsonCallback: FlickrParameterValues.JsonCallBackValue,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPageValue,
            FlickrParameterKeys.Page: String(pageNumber),
            FlickrParameterKeys.Latitude: String(latitude),
            FlickrParameterKeys.Longitude: String(longitude)
        ]
        
        let request = URLRequest(url: parseURLFromParameters(methodParameters as [String : AnyObject]))
        
        let _ = performRequest(request: request as! NSMutableURLRequest) { (parsedResult, error) in
            
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                handler(nil, nil, NSError(domain: "searchPhotos", code: 1, userInfo: userInfo))
            }
            
            if let error = error {
                sendError("\(error)")
            } else {
                guard let photosDictionary = parsedResult?[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    sendError("Error: no parsed photos")
                    return
                }
                
                guard let pages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    sendError("Error: no parsed pages")
                    return
                }
                
                guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    sendError("Error: no parsed photo")
                    return
                }
                
                var urls = [String]()
                
                for photo in photosArray {
                    let photoDictionary = photo as [String:Any]
                    guard let imageUrl = photoDictionary[FlickrResponseKeys.SquareURL] as? String else {
                        sendError("Error: no url_q")
                        return
                    }
                    urls.append(imageUrl)
                }
                
                handler(urls, pages, nil)
            }
        }
        
    }
    
    func downloadImage(imageURL: String, completionHandler: @escaping(_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
        let url = URL(string: imageURL)
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request) {data, response, downloadError in
            guard downloadError == nil else {
                return
            }
            completionHandler(data, nil)
        }
        task.resume()
        return task
    }
    
    private func performRequest(request: NSMutableURLRequest, completion: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                
                func sendError(_ error: String) {
                    print(error)
                    let userInfo = [NSLocalizedDescriptionKey : error]
                    completion(nil, NSError(domain: "performRequest", code: 1, userInfo: userInfo))
                }
                
                guard error == nil else {
                    sendError("Error with your request: \(error!)")
                    return
                }

                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    let httpError = (response as? HTTPURLResponse)?.statusCode
                    sendError("Your request returned a status code : \(String(describing: httpError))")
                    return
                }

                guard let data = data else {
                    sendError("No data was returned by the request!")
                    return
                }
                self.parseData(data, completionHandler: completion)
            }
            
            task.resume()
            return task
    }

    private func parseData(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject?
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(nil, NSError(domain: "parseData", code: 1, userInfo: userInfo))
        }
        
        completionHandler(parsedResult, nil)
    }
    
    private func parseURLFromParameters(_ parameters: [String:AnyObject]?, withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem)
            }
        }
        
        print(components.url!.absoluteString)
        return components.url!
    }
}

// MARK: - Constants

extension FlickrClient {
    
    struct Constants {
        static let APIKey = "3d3f6aedbc968b8651be24122307d750"
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
    }
    
    struct Methods {
        static let Search = "flickr.photos.search"
    }
    
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let Longitude = "lon"
        static let Latitude = "lat"
        static let Format = "format"
        static let NoJsonCallback = "nojsoncallback"
        static let PerPage = "per_page"
        static let Page = "page"
    }
    
    struct FlickrParameterValues {
        static let MediumURL = "url_m"
        static let SquareURL = "url_q"
        static let UseSafeSearch = "1"
        static let Json = "json"
        static let JsonCallBackValue = "1"
        static let PerPageValue = "21"
    }
    
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let MediumURL = "url_m"
        static let SquareURL = "url_q"
        static let Pages = "pages"
        static let Total = "total"
        
    }
    
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
}
