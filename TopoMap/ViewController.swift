//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/09.
//  2022/07/18
//  2023/02/22、2023/02/26
//  初期値として、①前回の検索地点を表示する。 //②いつも同じ地点を表示する。
//　◯広い範囲を指定すれば、レリーフ地図も表示できる。レリーフ地図の縮尺の問題か？
//　◯現在地から検索地点へ線を引く機能を追加する予定　ツールバーに実行アイコンを置く cursor arrow にしてみた

import UIKit
import MapKit
import CoreLocation


//----------------------------------------------------------------------------------------

class ViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mySlider: UISlider!
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
            var myPlace:String = "木場公園"
            var myAddress:String = "〒135-0042,東京都江東区,木場４丁目"
            var myLatitude:Double = 35.6743169 // 木場公園の緯度
            var myLongitude:Double = 139.8086198 // 木場公園の経度

    
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
        locManager.delegate = self
        //locManager.requestLocation()
        //locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters//誤差100m程度の精度
        //                          kCLLocationAccuracyNearestTenMeters//誤差10m程度の精度
        //                          kCLLocationAccuracyBest//最高精度(デフォルト値)
        //locManager.distanceFilter = 10//10ｍ移動したら、位置情報を更新する
    }
    
    // ツールバー内の 矢印アイコン　をクリックした時　現在地から目的地へ線を引く
    @IBAction func drawButtonClicked(_ sender: UIBarButtonItem) {
        
        locManager = CLLocationManager()
        locManager.delegate = self
        
        // 目標地点として、前回の検索で保存しておいた値を読み込む
        myPlace = UserDefaults.standard.string(forKey: "targetPlace")!
        myAddress = UserDefaults.standard.string(forKey: "targetAddress")!
        myLatitude = UserDefaults.standard.double(forKey: "targetLatitude")
        myLongitude = UserDefaults.standard.double(forKey: "targetLongitude")

    }
    
    
    //==============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self

        // 目標地点として、前回の検索で保存しておいた値を読み込む
        myPlace = UserDefaults.standard.string(forKey: "targetPlace")!
        myAddress = UserDefaults.standard.string(forKey: "targetAddress")!
        myLatitude = UserDefaults.standard.double(forKey: "targetLatitude")
        myLongitude = UserDefaults.standard.double(forKey: "targetLongitude")

        // 表示する地図の中心位置＝検索地点＝Pinを置く位置

        //線を引く場合は、現在地を中心位置にするので、このあたりを変更する必要がある
        let targetPlace = CLLocationCoordinate2D( latitude: myLatitude,longitude: myLongitude)
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let targetRegion = MKCoordinateRegion(center: targetPlace, span: span)
        // MapViewに中心点を設定する
        mapView.setCenter(targetPlace, animated: true)
        mapView.setRegion(targetRegion, animated:true)

        // ピンの座標とタイトルを設定。ピンの位置が画面の中央になる
        myPin.coordinate = targetPlace   // 目的地の座標
        myPin.title = myPlace            // 選択した地名
        myPin.subtitle = myAddress       // 選択した住所
        mapView.addAnnotation(myPin)     // MapViewにピンを追加する
        
        // 地理院地図のオーバーレイ表示。下の２種類のタイルを同時にコントロールしている
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
        
        // 更新スイッチの状態により、実行可否を判断する
        if updateSwitch .isOn {
            mapView.userTrackingMode = .followWithHeading // 現在地を更新して、HeadingUp表示
        } else {
            mapView.userTrackingMode = .none // 現在地の更新をしない
            //mapView.userTrackingMode = .follow // 現在地の更新をする
        }
        
        //現在地の緯度経度を取得する ido,keido
        let location:CLLocation = locations[0]//locations[0]の意味
        let ido = location.coordinate.latitude //現在地の緯度
        let keido = location.coordinate.longitude //現在地の経度
        // 現在地の座標
        let locNow = CLLocationCoordinate2D(latitude: ido, longitude: keido)
        print("現在地の緯度\(ido)")
        print("現在地の経度\(keido)")
        // 検索地点の座標
        let locTarget = CLLocationCoordinate2D(latitude: myLatitude, longitude: myLongitude)
        print("検索地点の緯度\(myLatitude)")
        print("検索地点の経度\(myLongitude)")
        //"mapView"に地図を表示する　よくある範囲設定をしてみた・・・不要か？
          var region:MKCoordinateRegion = mapView.region
          region.span.latitudeDelta = 0.01
          region.span.longitudeDelta = 0.01

        // ここから線を引く部分。
        // 現在地と検索地点、２点の座標を入れた配列をつくる
        let arrayLine = [locNow,locTarget]

        // ２点を結ぶ線を引く。（緯度,経度）＝（０、０）　未設定の時は線を引かない
            if (myLatitude != 0) && (myLongitude != 0) {
                let redLine = MKPolyline(coordinates: arrayLine, count: 2)
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
