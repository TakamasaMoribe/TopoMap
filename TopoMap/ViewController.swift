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
  //

    @IBOutlet weak var mapView: MKMapView!
    
    // 検索用テキストフィールド
    @IBOutlet weak var inputText: UITextField!
    
    // 検索用サーチバー
    @IBOutlet weak var searchText: UISearchBar!
    
    @IBOutlet weak var idoLabel: UILabel! // 緯度
    @IBOutlet weak var keidoLabel: UILabel!//経度

    
    // ツールバー中の検索ボタンをクリックしたとき
    @IBAction func seachButtonClicked(_ sender: UIBarButtonItem) {
        
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Search") as! SearchController
        self.dismiss(animated: true) //画面表示を消去
        self.present(nextView, animated: true, completion: nil)
        
    }
    
//    // searchBarへの入力に対する処理
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        //キーボードを閉じる
//        view.endEditing(true)
//        if let searchWord = searchBar.text {
//            print("①検索地名:\(searchWord)") // キーボードからsearchBarに入力した地名の表示 ①
//        //入力されていたら、地名を検索する
//            searchPlace(keyword: searchWord)
//        }
//    }
//
//    // 地名の検索  searchPlaceメソッド 第一引数：keyword 検索したい語句
//    func searchPlace(keyword:String) {
//        // keyword をurlエンコードする
//        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            return
//        }
//        // keyword_encode を使って、リクエストurlを組み立てる
//        guard let req_url = URL(string: "https://geocode.csis.u-tokyo.ac.jp/cgi-bin/simple_geocode.cgi?addr=\(keyword_encode)") else {
//            return
//        }
        
//        feedUrl = req_url // パースするときに使っている
//        print("②feedUrl:\(feedUrl)")//入力されていたら、アドレスを表示する。
//        //feedUrlの中身をパースする
//            print("パース開始")
//            let parser: XMLParser! = XMLParser(contentsOf: feedUrl)
//            parser.delegate = self
//            parser.parse()
//        self.tableView.reloadData() //tableViewへ表示する
//    }
    
    
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
        
//       //テキストフィールドのデリゲート　キーボード関連
//        inputText.delegate = self
        
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
        
        //inputText.delegate = self
        mapView.delegate = self
        mapView.addOverlay(tileOverlay, level: .aboveLabels)
        
        let temp = UserDefaults.standard.string(forKey: "targetPlace")
        let ido = UserDefaults.standard.string(forKey: "targetLatitude")
        let keido = UserDefaults.standard.string(forKey: "targetLongitude")
//        inputText.text = temp
        idoLabel.text = ido
        keidoLabel.text = keido
        
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

        // コンパスは、自動的に表示されるようだ
//        let compass = MKCompassButton(mapView: mapView) // コンパスのインスタンス作成
//        compass.frame = CGRect(x:300,y:15,width:5,height:5) // 位置と大きさ
//        self.view.addSubview(compass)// コンパスを地図に表示する
        
        mapView.userTrackingMode = .followWithHeading // 現在地付近の地図
//        mapView.delegate = self
        
    }
}

// 地理院地図の表示
extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKTileOverlayRenderer(overlay: overlay)
    }
}

