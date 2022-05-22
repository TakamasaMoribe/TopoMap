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
    
    @IBOutlet weak var mySlider: UISlider!
    
    // 表示用ラベル
    @IBOutlet weak var inputLabel: UILabel! // 地名
    @IBOutlet weak var idoLabel: UILabel!   // 緯度
    @IBOutlet weak var keidoLabel: UILabel! // 経度
        
    // ツールバー中の検索ボタンをクリックしたとき、検索画面に遷移する
    @IBAction func seachButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Search") as! SearchController
        self.dismiss(animated: true) //画面表示を消去
        self.present(nextView, animated: true, completion: nil)
    }
        
    // 地形図表示の濃淡を決めるスライダーの設定
    @IBAction func sliderDidChange(_ slider: UISlider) {
        if let renderer = mapView.renderer(for: tileOverlay) {
            renderer.alpha = CGFloat(slider.value)
        }
    }
    
    // 国土地理院が提供する色別標高図のURL。ここを変えると、様々な地図データを表示できる
    private let tileOverlay = MKTileOverlay(urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png")
    //https://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png

    // ロケーションマネージャーのインスタンスを作成する
    var locManager: CLLocationManager!
    
    
    //======================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
//        mapView.addOverlay(tileOverlay, level: .aboveLabels) // 地理院地図
//
//        mySlider.value = 0.1 //スライダーの初期値
        
        let temp = UserDefaults.standard.string(forKey: "targetPlace")
        let ido = UserDefaults.standard.double(forKey: "targetLatitude")
        let keido = UserDefaults.standard.double(forKey: "targetLongitude")
        //inputLabel.text = temp
        
        // 保存した値を読み込む
        let targetPlace = CLLocationCoordinate2D( latitude: ido,longitude: keido)
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let targetRegion = MKCoordinateRegion(center: targetPlace, span: span)
        
        // MapViewに中心点を設定.
        mapView.setCenter(targetPlace, animated: true)
        mapView.setRegion(targetRegion, animated:true)

        // ピンを生成
        let myPin: MKPointAnnotation = MKPointAnnotation()
        // ピンの座標を設定
        myPin.coordinate = targetPlace
        // ピンのタイトルを設定
        myPin.title = temp //"検索地点"
        // ピンのタイトルを設定
        myPin.subtitle = String(ido)
        // MapViewにピンを追加.
        mapView.addAnnotation(myPin)
        
        mapView.addOverlay(tileOverlay, level: .aboveLabels) // 地理院地図の表示
        if let renderer = mapView.renderer(for: tileOverlay) {
            renderer.alpha = 0.1 // 地理院地図の透明度の初期値　スライダーで可変
        }
                
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
    
    //  位置情報の使用許可・・・初回起動時にだけ呼ばれる --------------------------------
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
     let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locManager.startUpdatingLocation() // 取得を開始する
            break
        case .notDetermined, .denied, .restricted:
            break
        default:
            break
        }
    } // -----------------------------------------------------------------------

}

// 地理院地図の表示 オーバーレイとして
extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKTileOverlayRenderer(overlay: overlay)
    }
}

