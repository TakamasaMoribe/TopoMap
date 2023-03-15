//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/09.
//  2022/07/18
//  2023/02/22〜　03/15 住所検索と山名検索もできた。線を引いたときにheadingUpにする
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
    
    // CLLocationManagerは非同期処理を行うため、強参照のプロパティとしてアプリ内で保管させる
    // ロケーションマネージャーのインスタンスを生成する
        var locManager: CLLocationManager!
    // 地図上に立てるピンを生成する
        let myPin: MKPointAnnotation = MKPointAnnotation()
    
    // 現在地の初期値を設定しておく。
        var myLatitude:Double = 35.67476581424778 // 自宅の緯度
        var myLongitude:Double = 139.80606060262522 // 自宅の経度
    // 検索地点の初期値を設定しておく。
        var selectedPlace:String = "" // 検索の結果を入れる。初期値はなしにしておく
        var selectedAddress:String = ""
        var selectedLatitude:Double = 0.00
        var selectedLongitude:Double = 0.00
        var targetLatitude:Double = 35.6743169  // 木場公園の緯度　0.00にすると線が引けない
        var targetLongitude:Double = 39.8086198 // 木場公園の経度

//----------------------------------------------------------------------------------------
    // 地理院地図　表示の濃淡を決めるスライダーの設定　標準地図と陰影起伏図を同時に変更する
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
    
//----------------------------------------------------------------------------------------
    // ツールバー内の検索ボタンをクリックしたとき、検索画面に遷移する
    @IBAction func seachButtonClicked(_ sender: UIBarButtonItem) {
        print("検索ボタンが押されて、検索画面に遷移します。")
        
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
// -------------------------------------------------------------------------------
    // ツールバー内の　＜現在地＞ボタン　をクリックした時、現在地の位置情報を、再度取得する
    // アプリが起動した時点で、現在地の取得は行っている。（青い●が表示されている）
    @IBAction func currentButtonClicked(_ sender: UIBarButtonItem) {
        print("現在地ボタンをクリックしました")
        // 現在地の取得 ロケーションマネージャーのインスタンスを作成する
        locManager = CLLocationManager()
        locManager.delegate = self // 現在地を取得して表示するために必要となる
        // 現在地の座標を取得する
        let myLatitude = locManager.location?.coordinate.latitude //緯度
        let myLongitude = locManager.location?.coordinate.longitude //経度
        let myLocation = CLLocationCoordinate2D(latitude: myLatitude!, longitude: myLongitude!) //座標
        // 現在地を画面の中央に表示する
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let myRegion = MKCoordinateRegion(center: myLocation, span: span)//現在地
        // MapViewに中心点を設定する
        mapView.setCenter(myLocation, animated: true)
        mapView.setRegion(myRegion, animated:true)
        // 現在地の更新をする
        mapView.userTrackingMode = .follow // 現在地の更新をする（青い●が表示されている）
        print("現在地ボタン 処理の出口です")
    }
// -------------------------------------------------------------------------------
    // ツールバー内の＜矢印＞アイコンをクリックした時、現在地を読み込んで目的地へ線を引く
    // アプリを起動した時点で、現在地を取得しているので、ここで取得する必要はない
    @IBAction func drawButtonClicked(_ sender: UIBarButtonItem) {
        print("矢印アイコンをクリックしました")
        // 現在地の座標を取得する
        let myLatitude = locManager.location?.coordinate.latitude //緯度
        let myLongitude = locManager.location?.coordinate.longitude //経度
        let myLocation = CLLocationCoordinate2D(latitude: myLatitude!, longitude: myLongitude!) //座標
     
        // 検索した目標地点の位置情報等は、Userdeaults.standard に保存してあるので読み込む
        let targetPlace = UserDefaults.standard.string(forKey:"targetPlace")! //場所
        let targetAddress = UserDefaults.standard.string(forKey:"targetAddress")! //住所
        let targetLatitude = UserDefaults.standard.double(forKey:"targetLatitude")
        let targetLongitude = UserDefaults.standard.double(forKey:"targetLongitude")
        let targetLocation = CLLocationCoordinate2D(latitude: targetLatitude, longitude: targetLongitude)//座標
        
        // 検索地を画面の中央に表示する
        var span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        var targetRegion = MKCoordinateRegion(center: targetLocation, span: span)//検索地
        // MapViewに中心点を設定する
        mapView.setCenter(targetLocation, animated: true)
        mapView.setRegion(targetRegion, animated:true)
        
        // 線を引くメソッドへ　現在地と目的地、２点の座標が引数として必要
        drawLine(current: myLocation, destination: targetLocation) // 線を引くメソッドへ
        
        // 線を引いたあとに、現在地を画面の中央に表示する
        span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        targetRegion = MKCoordinateRegion(center: myLocation, span: span)//現在地
        // MapViewに中心点を設定する
        mapView.setCenter(myLocation, animated: true)
        mapView.setRegion(targetRegion, animated:true)
        
    }
// -------------------------------------------------------------------------------
        
    //==============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        // CLLocationManagerがCLLocationManagerDelegateプロトコルの抽象メソッドの実行は、
        // CLLocationManagerDelegateプロトコルの実装クラスであるViewControllerに実行させる
        // 位置情報の取得 ロケーションマネージャーのインスタンスを作成する
        locManager = CLLocationManager()// これがないと、現在地の位置情報取得ができない
        locManager!.delegate = self //
        mapView.delegate = self //Mapの描画 これがないとオーバーレイが正しく表示されない
        
//-----------------------------------------------------------------
// 画面遷移のタイミングで、位置情報の受け渡しをしている。変数の引き継ぎはできている。
        let targetPlace = selectedPlace         // 選択した場所
        let targetAddress = selectedAddress     // 住所
        let targetLatitude = selectedLatitude   // 緯度
        let targetLongitude = selectedLongitude // 経度
        let targetLocation = CLLocationCoordinate2D(latitude: targetLatitude, longitude: targetLongitude)//座標

        // 検索地を画面の中央に表示する
        let span = MKCoordinateSpan (latitudeDelta: 0.01,longitudeDelta: 0.01)
        let targetRegion = MKCoordinateRegion(center: targetLocation, span: span)//検索地
        // MapViewに中心点を設定する
        mapView.setCenter(targetLocation, animated: true)
        mapView.setRegion(targetRegion, animated:true)
        
        // 検索地点があれば、.none にする　mapView.userTrackingMode が重要なポイント
        if (targetPlace == "") {
            mapView.userTrackingMode = .follow // 検索地点がなければ、現在地の更新をする。
        } else {
            mapView.userTrackingMode = .none // 検索地点があるので、現在地の更新をしない。
            //ピンの座標とタイトルを設定。ピンの位置が画面の中央になる。
            myPin.coordinate = targetLocation    // 選択した場所の座標
            self.myPin.title = targetPlace       //targetPlace      // 選択した場所
            self.myPin.subtitle = targetAddress  //targetAddress    // 選択した住所
            mapView.addAnnotation(myPin)         // MapViewにピンを追加表示する
        }
                
        //------------------------------------------------------------------
        // 地理院地図のオーバーレイ表示。２種類の地図タイルの透明度の初期値を設定する
        // Std:標準地図
        mapView.addOverlay(gsiTileOverlayStd, level: .aboveLabels)
            if let renderer = mapView.renderer(for: gsiTileOverlayStd) {
                renderer.alpha = 0.1 // 透明度の初期値　　スライダーで可変
            }
        // Hil陰影起伏図
        mapView.addOverlay(gsiTileOverlayHil, level: .aboveLabels)
            if let renderer = mapView.renderer(for: gsiTileOverlayHil) {
                renderer.alpha = 0.1 // 透明度の初期値　　スライダーで可変
            }
        // Relレリーフ地図
        // mapView.addOverlay(gsiTileOverlayRel, level: .aboveLabels)
        //     if let renderer = mapView.renderer(for: gsiTileOverlayRel) {
        //         renderer.alpha = 0.1 // 透明度の初期値　　スライダーで可変
        //     }
        
    } // end of override func viewDidLoad ・・・
    
    //==============================================================================

    // 現在位置取得関係 ----------------------------------------------------
    // CLLocationManagerのdelegate:現在位置取得
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        //locManager.requestLocation()
        //locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters//誤差100m程度の精度
        //                         kCLLocationAccuracyNearestTenMeters//誤差10m程度の精度
        //locManager.desiredAccuracy = kCLLocationAccuracyBest//最高精度(デフォルト値)
        //locManager.distanceFilter = 10//10ｍ移動したら、位置情報を更新する
    //更新スイッチの状態により、実行可否を判断する。線を引いたときに有効化する？？？？？？？？？？？
    // if updateSwitch .isOn {
    //    mapView.userTrackingMode = .followWithHeading // 現在地を更新して、HeadingUp表示
    //  } else {
    //    mapView.userTrackingMode = .none // 現在地の更新をしない
    //    //mapView.userTrackingMode = .follow // 現在地の更新をする
    //  }
    }
    
    // ２点を結ぶ線を引くメソッド
    func drawLine(current:CLLocationCoordinate2D,destination:CLLocationCoordinate2D)  {
        // 現在地と目的地、２点の座標を入れた配列をつくる
        let lineArray = [current,destination]
            // (緯度,経度)=(0,0)　未設定の時は線を引かない
            if (targetLatitude != 0) && (targetLongitude != 0) {
                let redLine = MKPolyline(coordinates: lineArray, count: 2)//lineArray配列の２点間
                mapView.addOverlays([redLine])// 地図上に線を描く
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
    
} // end of class ViewController ・・・


 //地理院地図の表示と線の表示　オーバーレイとして表示する。
 //拡張ということがよくわからないが、
 //MKPolylineRenderer(polyline:) と
 //MKTileOverlayRenderer(overlay:) の場合に分けて、処理をしている
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
