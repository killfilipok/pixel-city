//
//  ViewController.swift
//  pixel-city
//
//  Created by Philip on 3/13/19.
//  Copyright © 2019 Philip. All rights reserved.
//


import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    //vars
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius : Double = 1000
    
    var spiner : UIActivityIndicatorView?
    var progressLbl : UILabel?
    
    var screenSize = UIScreen.main.bounds
    
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView : UICollectionView?
    
    var imgUrlArray = [String]()
    var imgArray = [UIImage]()
    
    //aoutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
        confogureLocationServices()
        addDoubleTap()
        addSwipe()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        pullUpView.addSubview(collectionView!)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
    }
    
    func addSwipe(){
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @objc func animateViewDown(){
        cancelAllSessions()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func addSpinner(){
        spiner = UIActivityIndicatorView()
        spiner?.center = CGPoint(x: (screenSize.width / 2) - ((spiner?.frame.size.width)! / 2), y: 150)
        spiner?.style = .whiteLarge
        spiner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spiner?.startAnimating()
        
        collectionView?.addSubview(spiner!)
    }
    
    func removeSpinner(){
        if spiner != nil {
            spiner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl(){
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl(){
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
    func animateViewUp(){
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    //actions
    @IBAction func mapBtnPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapToUserLocation()
        }
    }
    
}


extension MapVC: MKMapViewDelegate {
    
    func retriveUrls(forAnnotation annotation: DroppablePin,handler:@escaping (_ status: Bool) -> ()){
        Alamofire.request(flickrURL(forApiKey: apiKey, withAnnotation: annotation, andNumOfPhotos: 40))
            .responseJSON { (response) in
                guard let json = response.result.value as? Dictionary<String,AnyObject> else {return}
                
                let photoDict = json["photos"] as! Dictionary<String,AnyObject>
                let photosArray = photoDict["photo"] as! [Dictionary<String,AnyObject>]
                
                for photo in photosArray {
                    let photoUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    
                    self.imgUrlArray.append(photoUrl)
                }
                handler(true)
        }
    }
    
    func retriveImgs(handler : @escaping ((_ status: Bool) -> ())){
        for url in imgUrlArray {
            Alamofire.request(url).responseImage { (response) in
                guard let img = response.result.value else {return}
                
                self.imgArray.append(img)
                self.progressLbl?.text = "\(self.imgArray.count)/\(self.imgUrlArray.count) IMAGES DOWNLOADED"
                
                if self.imgArray.count == self.imgUrlArray.count {
                    handler(true)
                }
            }
        }
    }
    
    func cancelAllSessions(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    @objc func dropPin(sender:UIGestureRecognizer){
        cancelAllSessions()
        
        imgArray = []
        imgUrlArray = []
        
        collectionView?.reloadData()
        
        removePin()
        removeSpinner()
        removeProgressLbl()
        
        animateViewUp()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifire: "droppablePin")
        mapView.addAnnotation(annotation)
        
        retriveUrls(forAnnotation: annotation) { (success) in
            if success {
                self.retriveImgs(handler: { (success) in
                    if success {
                        self.removeSpinner()
                        self.removeProgressLbl()
                        self.collectionView?.reloadData()
                    }
                    print(success)
                })
            }
        }
        
        zoomTo(coordinate: touchCoordinate)
    }
    
    func removePin(){
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func centerMapToUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else {return}
        self.zoomTo(coordinate: coordinate)
    }
    
    func zoomTo(coordinate: CLLocationCoordinate2D){
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius * 2, longitudinalMeters: regionRadius * 2)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

extension MapVC: CLLocationManagerDelegate{
    func confogureLocationServices(){
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapToUserLocation()
    }
}


extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell
            else {return UICollectionViewCell()}
        let imageView = UIImageView(image: imgArray[indexPath.row])
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        
        popVC.initData(forImage: imgArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}


extension MapVC : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC? else {return nil}
        
        popVC?.initData(forImage: imgArray[indexPath.row])
        
        previewingContext.sourceRect = cell.frame
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
