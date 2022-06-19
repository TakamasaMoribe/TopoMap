//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/09.
//  2022/06/15

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var mySlider: UISlider!
        
    // ツールバー中の検索ボタンをクリックしたとき、検索画面に遷移する
    @IBAction func seachButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Search") as! SearchController
        self.dismiss(animated: true) //画面表示を消去
        self.present(nextView, animated: true, completion: nil)
    }
        
    // 地理院地図　表示の濃淡を決めるスライダーの設定
    @IBAction func sliderDidChange(_ slider: UISlider) {
        if let renderer = mapView.renderer(for: gsiTileOverlay) { // 地理院地図
            renderer.alpha = CGFloat(slider.value) // 濃淡のプロパティ値＝スライダ値
        }
    }
    
    // 国土地理院が提供する色別標高図のURL。ここを変えると、様々な地図データを表示できる
    private let gsiTileOverlay = MKTileOverlay(urlTemplate:
    "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png") // 標準
      //"https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png") // 標準
      //"https://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png") //relief
    
    // 地図上に立てるピンを生成する
    let myPin: MKPointAnnotation = MKPointAnnotation()

    // ロケーションマネージャーのインスタンスを生成する
    var locManager: CLLocationManager!
    var myLatitude:Double = 35.6743169 // 検索地点の緯度の初期値　木場公園
    var myLongitude:Double = 139.8086198 // 検索地点の軽度の初期値　木場公園
    
    //======================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        // 保存した値を読み込む
        let selectedPlace = UserDefaults.standard.string(forKey: "targetPlace")
        myLatitude = UserDefaults.standard.double(forKey: "targetLatitude")
        myLongitude = UserDefaults.standard.double(forKey: "targetLongitude")

        // 表示する地図の中心位置＝検索地点＝Pinを置く位置
        let targetPlace = CLLocationCoordinate2D( latitude: myLatitude,longitude: myLongitude)
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let targetRegion = MKCoordinateRegion(center: targetPlace, span: span)
        // MapViewに中心点を設定
        mapView.setCenter(targetPlace, animated: true)
        mapView.setRegion(targetRegion, animated:true)
        
        // ピンの座標とタイトルを設定。画面の中央に表示される
        myPin.coordinate = targetPlace // 目的地の座標
        myPin.title = selectedPlace    // 選択した地名
        // myPin.subtitle = selectedAddress // 住所は引き継いでいない
        mapView.addAnnotation(myPin) // MapViewにピンを追加する
        
        mapView.addOverlay(gsiTileOverlay, level: .aboveLabels) // 地理院地図の表示
            if let renderer = mapView.renderer(for: gsiTileOverlay) {
                renderer.alpha = 0.1 // 地理院地図の透明度の初期値　　スライダーで可変
            }
        
                
//        // 現在地の取得　コメントアウトしてみた 0615
//        // ロケーションマネージャーのインスタンスを作成する
//        locManager = CLLocationManager()
//        locManager.delegate = self
//
//        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters//誤差100m程度の精度
//        //kCLLocationAccuracyNearestTenMeters    誤差10m程度の精度
//        //kCLLocationAccuracyBest    最高精度(デフォルト値)
//        locManager.distanceFilter = 5//精度は5ｍにしてみた
//
//        // 位置情報の使用の許可を得て、取得する
//        locManager.requestWhenInUseAuthorization()
//        locationManagerDidChangeAuthorization(locManager)

    }
    
    //======================================================

// 検索した場所を表示するために、一時的にコメントアウトしている ///////////////////////////////////////////////
//    // CLLocationManagerのdelegate：現在位置取得
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
//        //"mapView"に地図を表示する　よくある範囲設定をしてみた
//        var region:MKCoordinateRegion = mapView.region
//        region.span.latitudeDelta = 0.01
//        region.span.longitudeDelta = 0.01
//
//        mapView.userTrackingMode = .followWithHeading
//    }
    
//    //  位置情報の使用許可・・・初回起動時にだけ呼ばれる --------------------------------
//    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
//     let status = manager.authorizationStatus
//        switch status {
//        case .authorizedAlways, .authorizedWhenInUse:
//            locManager.startUpdatingLocation() // 取得を開始する
//            break
//        case .notDetermined, .denied, .restricted:
//            break
//        default:
//            break
//        }
//    } // -----------------------------------------------------------------------

}


// 地理院地図の表示 オーバーレイとして表示する
extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKTileOverlayRenderer(overlay: overlay)
    }
}

