//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/09.
//

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate, UITextFieldDelegate {
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var inputText: UITextField! // 検索用テキストフィールド
    
    // 地形図表示の濃淡を決めるスライダー
    @IBAction func sliderDidChange(_ slider: UISlider) {
        if let renderer = mapView.renderer(for: tileOverlay) {
            renderer.alpha = CGFloat(slider.value)
        }
    }
    
    // 国土地理院が提供する色別標高図のURL
    // ここを変えるだけで、様々な地図データを表示できる！
    private let tileOverlay = MKTileOverlay(urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png")
    //https://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png

    // ロケーションマネージャーのインスタンスを作成する
    var locManager: CLLocationManager!
    

    //======================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locManager = CLLocationManager()
        locManager.delegate = self
 
        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters //誤差100m程度の精度
        //kCLLocationAccuracyNearestTenMeters    誤差10m程度の精度
        //kCLLocationAccuracyBest    最高精度(デフォルト値)
        locManager.distanceFilter = 5//精度は5ｍにしてみた

        // 位置情報の使用の許可を得て、取得する
        locManager.requestWhenInUseAuthorization()

        locationManagerDidChangeAuthorization(locManager)
            //authorizationStatus() がdeprecated になったため、上のメソッドで対応している
        
        inputText.delegate = self
        mapView.delegate = self
        mapView.addOverlay(tileOverlay, level: .aboveLabels)
        
        }
    
    
//--------------------------------------------------
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      //キーボードを閉じる。resignFirstResponderはdelegateメソッド
      textField.resignFirstResponder()
      //入力された文字を取り出す
        if let searchKey = textField.text {
         //入力された文字をデバッグエリアに表示
         print(searchKey)
        //CLGeocoderインスタンスを取得
        let geocoder = CLGeocoder()
        //入力された文字から位置情報を取得
        geocoder.geocodeAddressString(searchKey, completionHandler: { (placemarks, error) in
        //位置情報が存在する場合（定数geocoderに値が入ってる場合)はunwrapPlacemarksに取り出す。
            if let unwrapPlacemarks = placemarks {
              //1件目の情報を取り出す
             if let firstPlacemark = unwrapPlacemarks.first {
               //位置情報を取り出す
               if let location = firstPlacemark.location {
                 //位置情報から緯度経度をtargetCoordinateに取り出す
                  let targetCoordinate = location.coordinate
                  //緯度経度をデバッグエリアに表示
                  print(targetCoordinate)
                   
                   //MKPointAnnotationインスタンスを取得し、ピンを生成
                    let pin = MKPointAnnotation()
                   //ピンの置く場所に緯度経度を設定
                    pin.coordinate = targetCoordinate
                   //ピンのタイトルを設定
                    pin.title = searchKey
                   //ピンを地図に置く
                    //self.Map.addAnnotation(pin)
                   self.mapView.addAnnotation(pin)
                   
                   
                   //検索地点の緯度経度を中心に半径1000mの範囲を表示
                    self.mapView.region = MKCoordinateRegion(center: targetCoordinate, latitudinalMeters: 1000.0, longitudinalMeters: 1000.0)
               }
              }
            }
            })
        }
        //デフォルト動作を行うのでtureを返す。返り値型をBoolにしているため、この記述がないとエラーになる。
       return true
    }
    
    
    //======================================================
    //  位置情報の使用の許可・・・一回目の起動時にだけ呼ばれる
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
     let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locManager.startUpdatingLocation()// 取得を開始する
            break
        case .notDetermined, .denied, .restricted:
            break
        default:
            break
        }
    }
    
    // CLLocationManagerのdelegate：現在位置取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        
        //現在地の緯度経度取得 ido,keido
//        let location:CLLocation = locations[0]//locations[0]の意味
//        let ido = location.coordinate.latitude
//        let keido = location.coordinate.longitude

        //"mapView"に地図を表示する　よくある範囲設定をしてみた
        var region:MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
//        let compass = MKCompassButton(mapView: mapView) // コンパスのインスタンス作成
//        compass.frame = CGRect(x:300,y:15,width:5,height:5) // 位置と大きさ
//        self.view.addSubview(compass)// コンパスを地図に表示する
        
        mapView.userTrackingMode = .followWithHeading // 現在地付近の地図
//        mapView.delegate = self
        
    }
}


extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKTileOverlayRenderer(overlay: overlay)
    }
}

