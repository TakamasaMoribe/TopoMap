//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/09.
//  2022/07/18
//  2023/02/22、2023/02/26、02/27
//  Map表示の初期値として、前回の検索地点を使用する。
//　◯広い範囲を指定すれば、レリーフ地図も表示できる。レリーフ地図の縮尺の問題か？
//　◯現在地から検索地点へ線を引く。ツールバーに実行アイコンを置く cursor arrow にしてみた

import UIKit
import MapKit
import CoreLocation


//----------------------------------------------------------------------------------------

class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySlider: UISlider! // 地理院地図の濃淡を決めるスライダー
    @IBOutlet weak var updateSwitch: UISwitch! //現在地表示更新の可否を決めるスイッチ
    
    // 国土地理院が提供するタイルのURL。ここを変えると、様々な地図データを表示できる
    private let gsiTileOverlayStd = MKTileOverlay(urlTemplate:
    "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png")    // Std:標準地図
                            //標準地図  std ズームレベル 5～18
    private let gsiTileOverlayHil = MKTileOverlay(urlTemplate:
    "https://cyberjapandata.gsi.go.jp/xyz/hillshademap/{z}/{x}/{y}.png") //Hil:陰影起伏図
                            //陰影起伏図 hillshademap ズームレベル 2～16
    //    private let gsiTileOverlayRel = MKTileOverlay(urlTemplate:
    //    "https://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png") // Rel:レリーフ地図
    //                            //色別標高図  relief ズームレベル 5～15
    
    // 地図上に立てるピンを生成する
    let myPin: MKPointAnnotation = MKPointAnnotation()
    // ロケーションマネージャーのインスタンスを生成する
    var locManager: CLLocationManager!
    
            // 検索地点の初期値を設定しておく。表示はされない。
            var selectedPlace:String = "木場公園"
            var selectedAddress:String = "〒135-0042,東京都江東区,木場４丁目"
            var targetLatitude:Double = 35.6743169 // 木場公園の緯度
            var targetLongitude:Double = 139.8086198 // 木場公園の経度

    
    // 地理院地図　表示の濃淡を決めるスライダーの設定 標準地図と陰影起伏図を同時に変更するスライダー
    @IBAction func sliderDidChange(_ slider: UISlider) {
        if let renderer = mapView.renderer(for: gsiTileOverlayStd) { // Std標準地図
            renderer.alpha = CGFloat(slider.value) // 濃淡のプロパティ値＝スライダ値
        }

        if let renderer = mapView.renderer(for: gsiTileOverlayHil) { // Hil陰影起伏図
            renderer.alpha = CGFloat(slider.value) * 0.5// スライダ値*0.5
        }
    //    if let renderer = mapView.renderer(for: gsiTileOverlayRel) { // Relレリーフ地図
    //        renderer.alpha = CGFloat(slider.value) * 0.3// スライダ値*0.3
    //    }
    }
        
    // ツールバー内の検索ボタンをクリックしたとき、検索画面に遷移する
    @IBAction func seachButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!        
        let nextView = storyboard.instantiateViewController(withIdentifier: "Search") as! SearchController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できる？
        self.present(nextView, animated: true, completion: nil)
    }
    
    // 住所ボタンをクリックしたとき、住所検索画面に遷移する
    @IBAction func addressButtonClecked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "SearchPlace") as! SearchPlaceController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できる？
        self.present(nextView, animated: true, completion: nil)
    }

    // 山名ボタンをクリックしたとき、山名検索画面に遷移する
    @IBAction func mountButtonclicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "SearchMount") as! SearchMountController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できる？
        self.present(nextView, animated: true, completion: nil)
    }

    // ツールバー内の「現在地」ボタンをクリックした時
    @IBAction func currentButtonClicked(_ sender: UIBarButtonItem) {
        // 現在地の取得 ロケーションマネージャーのインスタンスを作成する
        locManager = CLLocationManager()
        locManager.delegate = self // 現在地を取得して表示する？
        //locManager.requestLocation()
        //locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters//誤差100m程度の精度
        //                          kCLLocationAccuracyNearestTenMeters//誤差10m程度の精度
        //                          kCLLocationAccuracyBest//最高精度(デフォルト値)
        //locManager.distanceFilter = 10//10ｍ移動したら、位置情報を更新する
    }
    
    // ツールバー内の 矢印アイコン　をクリックした時　現在地から目的地へ線を引く
    @IBAction func drawButtonClicked(_ sender: UIBarButtonItem) {
        
        // ここに線を引くメソッドへのリンクを置く
        //locManager = CLLocationManager()
        //locManager.delegate = self // 現在地取得へ
        
    }
    
    
    //==============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //mapView.delegate = self //Mapの描画

        // 目標地点として、前回の検索で保存しておいた値を読み込む
        selectedPlace = UserDefaults.standard.string(forKey: "targetPlace")!
        selectedAddress = UserDefaults.standard.string(forKey: "targetAddress")!
        targetLatitude = UserDefaults.standard.double(forKey: "targetLatitude")
        targetLongitude = UserDefaults.standard.double(forKey: "targetLongitude")

        // 表示する地図の中心位置＝検索地点＝Pinを置く位置
        let targetPlace = CLLocationCoordinate2D( latitude: targetLatitude,longitude: targetLongitude)
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let targetRegion = MKCoordinateRegion(center: targetPlace, span: span)
        // MapViewに中心点を設定する
        mapView.setCenter(targetPlace, animated: true)
        mapView.setRegion(targetRegion, animated:true)

        // ピンの座標とタイトルを設定。検索地点＝ピンの位置が画面の中央になる
        myPin.coordinate = targetPlace   // 選択した場所の座標
        myPin.title = selectedPlace      // 選択した地名
        myPin.subtitle = selectedAddress // 選択した住所
        mapView.addAnnotation(myPin)     // MapViewにピンを追加表示する
        
        // 地理院地図のオーバーレイ表示。下の２種類のタイルを同時に表示している
        mapView.addOverlay(gsiTileOverlayStd, level: .aboveLabels) // Std:標準地図
            if let renderer = mapView.renderer(for: gsiTileOverlayStd) {
                renderer.alpha = 0.1 // 標準地図　透明度の初期値　　スライダーで可変
            }

        mapView.addOverlay(gsiTileOverlayHil, level: .aboveLabels) // Hil陰影起伏図
            if let renderer = mapView.renderer(for: gsiTileOverlayHil) {
                renderer.alpha = 0.1 // 陰影起伏図　透明度の初期値　　スライダーで可変
            }
        // mapView.addOverlay(gsiTileOverlayRel, level: .aboveLabels) // Relレリーフ地図
        //     if let renderer = mapView.renderer(for: gsiTileOverlayRel) {
        //         renderer.alpha = 0.1 // レリーフ地図　透明度の初期値　　スライダーで可変
        //     }

    } // end of override func viewDidLoad ・・・
    
    //==============================================================================

    // 現在位置取得関係 ----------------------------------------------------
    // CLLocationManagerのdelegate:現在位置取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        print("現在地の取得に入りました")
        // 更新スイッチの状態により、実行可否を判断する・・とりあえず使わないで考える。
        // if updateSwitch .isOn {
        //     mapView.userTrackingMode = .followWithHeading // 現在地を更新して、HeadingUp表示
        // } else {
        //   　mapView.userTrackingMode = .none // 現在地の更新をしない
        //   //mapView.userTrackingMode = .follow // 現在地の更新をする
        // }
        
        //現在地の緯度経度を取得する myLatitude,myLongitude
        let location:CLLocation = locations[0]//locations[0]の意味
        let myLatitude = location.coordinate.latitude //現在地の緯度
        let myLongitude = location.coordinate.longitude //現在地の経度
        // 現在地の座標
        let locNow = CLLocationCoordinate2D(latitude: myLatitude, longitude: myLongitude)
        print("現在地の緯度\(myLatitude)")
        print("現在地の経度\(myLongitude)")
        
        // ここから線を引く準備。
        // 検索地点の座標
        let locTarget = CLLocationCoordinate2D(latitude: targetLatitude, longitude: targetLongitude)
        print("検索地点 selectedPlace:\(selectedPlace)")
        print("検索地点の緯度\(targetLatitude)")
        print("検索地点の経度\(targetLongitude)")

        // 現在地と検索地点、２点の座標を入れた配列をつくる
        let lineArray = [locNow,locTarget]
        
        print("線を引きます")
        // ２点を結ぶ線を引く。（緯度,経度）＝（０、０）　未設定の時は線を引かない
        mapView.delegate = self //Mapの描画
            if (targetLatitude != 0) && (targetLongitude != 0) {
                let redLine = MKPolyline(coordinates: lineArray, count: 2)
                mapView.addOverlays([redLine])// 地図上に描く
            }
    }
   
    
    
    //  位置情報の使用許可を確認して、取得する。
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
     let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locManager.startUpdatingLocation() // 取得を開始する
            //locManager.stopUpdatingLocation()// 取得を終了する
            break
        case .notDetermined, .denied, .restricted:
            break
        default:
            break
        }
    }
    // -----------------------------------------------------------------------
} // end of class ViewController ・・・


 //地理院地図の表示と線の表示　オーバーレイとして表示する。
 //拡張ということがよくわからないが、
 //MKPolylineRenderer(polyline:) と　MKTileOverlayRenderer(overlay:)の場合に分けて、処理をしている

extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let arrowline = overlay as? MKPolyline { // 線のとき
            let renderer = MKPolylineRenderer(polyline: arrowline)
                    renderer.strokeColor = UIColor.red// 赤い線
                    renderer.lineWidth = 2.0
                    return renderer
                }

        return MKTileOverlayRenderer(overlay: overlay) //Tile のとき
    }
}
