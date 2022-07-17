//
//  Search.swift
//  TopoMap
//
//  Created by 森部高昌 on 2022/05/05
//  2022/07/17

import UIKit
import MapKit
import CoreLocation

class SearchController: UIViewController, UITextFieldDelegate,UISearchBarDelegate {
    
    // 検索地名入力用　サーチバー
    @IBOutlet weak var mySearchBar: UISearchBar!
    // 検索結果表示用　テーブルビュー
    @IBOutlet weak var tableView: UITableView!
    // 山名を検索するかどうか　スイッチ
    @IBOutlet weak var mountSearch: UISwitch! // 初期値はOFF
    
    // Back ボタンを押したとき、地図画面(起動画面)に遷移する
    @IBAction func backButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できる？
        self.present(nextView,animated: true, completion: { () in
        })
    }

    private var searchCompleter = MKLocalSearchCompleter() // SearchCompleter()のインスタンス生成
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mySearchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchCompleter.delegate = self
        mySearchBar.becomeFirstResponder() // サーチバーにフォーカスをあてる
    }

    
    // サーチバーに入力した文字を検索する
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchKey = mySearchBar.text {
            searchCompleter.queryFragment = searchKey // searchBarに入力した文字
            searchCompleter.resultTypes = .query //
            //searchCompleter.resultTypes = .pointOfInterest // 関連する場所
            //searchCompleter.resultTypes = .address         // 地図上の位置のみ
        }
        self.mySearchBar.endEditing(true) // 入力終了(EnterKey)で、キーボードをしまう
    }
} // end of class SearchController



extension SearchController: UITableViewDelegate, UITableViewDataSource {
  //検索の結果は MKLocalSearchCompleter の results プロパティに入る。
  //MKLocalSearchCompletion が配列で格納されているので、それをテーブルビューで表示する。
    // ２つのプロトコルを追加する。"セルの数の取得"と"セルの生成"のメソッドが必要になる。
    
    // セルの数の取得　numberOfRowsInSection　表示したいセルの数を取得する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count // 検索して得られた結果の個数を返す
    }

    // セルの生成　cellForRowAt　得られた値をセルに代入して生成(表示)する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let completion = searchCompleter.results[indexPath.row]  // 配列に入っている
                cell.textLabel?.text = completion.title          // 場所の名前表示
                cell.detailTextLabel?.text = completion.subtitle // 住所など表示
        return cell
    }
    
    // didSelectRowAt　Cellを選択した(触った)ことを感知している
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell: UITableViewCell = self.tableView(tableView, cellForRowAt: indexPath)
        if let selectedPlace = cell.textLabel?.text { // 選んだセルに地名があれば
            if let selectedAddress = cell.detailTextLabel?.text! { //さらに住所があれば
                //↓　緯度経度を取得する
                
                let searchPlace = selectedAddress // 選択したセルの住所
                let geocoder = CLGeocoder() // CLGeocoderインスタンスを生成する
                //入力された文字から位置情報を取得する
                geocoder.geocodeAddressString(searchPlace, completionHandler: { (placemarks, error) in
                //位置情報が存在する場合(geocoderに値がある時)はunwrapPlacemarksに取り出す。
                    if let unwrapPlacemarks = placemarks {
                        //1件目の情報を取り出す
                        if let firstPlacemark = unwrapPlacemarks.first {
                            //位置情報を取り出す
                            if let location = firstPlacemark.location {
                                //位置情報から緯度経度をtargetCoordinateに取り出す
                                let targetLatitude = location.coordinate.latitude
                                let targetLongitude = location.coordinate.longitude
                                //let subLocality = firstPlacemark.subLocality// 地名
                                //print("地名:\(subLocality)")
                           // Userdeaults.standard に保存する
                           UserDefaults.standard.set(selectedPlace, forKey:"targetPlace")
                            UserDefaults.standard.set(selectedAddress, forKey:"targetAddress")
                            UserDefaults.standard.set(targetLatitude, forKey:"targetLatitude")
                            UserDefaults.standard.set(targetLongitude, forKey:"targetLongitude")
                            UserDefaults.standard.synchronize()
    // 地図画面へ遷移する
       let storyboard: UIStoryboard = self.storyboard!
       let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できる？
       self.present(nextView,animated: true, completion: { () in
           nextView.myPin.title = selectedPlace      // 地名　pinをnextViewの変数にした
           nextView.myPin.subtitle = selectedAddress // 住所　引き継ぎが可能
           nextView.myLatitude = targetLatitude      // 緯度も同時に引き継ぐ?
           nextView.myLongitude = targetLongitude    // 経度も同時に引き継ぐ?
       })

                       } // if let location =
                     } // if let firstPlacemark =
                    } // if let unwrapPlacemark =
                    else {
                    print("緯度経度のデータが見つかりません")//ここもOK
                    }
                })//geocoder.geocodeAddressString(searchPlace,
                                
                //↑ 緯度経度の取得　終わり
            } // if let selectedAddress・・・
        } // if let selectedPlace・・・
    } // func tableView・・・
} // end of extension SearchController: UITableViewDelegate, ・・・



extension SearchController: MKLocalSearchCompleterDelegate {
    // 正常に検索結果が更新されたとき
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        tableView.reloadData() // テーブルのデータを書き直す
    }
    // 検索が失敗したとき
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // エラー処理
    }
}





//@objc private func mapDidTap(_ gesture: UITapGestureRecognizer) {
//    let coordinate = map.convert(gesture.location(in: map), toCoordinateFrom: map)
//    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
//    CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
//        guard
//            let placemark = placemarks?.first, error == nil,
//            let administrativeArea = placemark.administrativeArea, // 都道府県
//            let locality = placemark.locality, // 市区町村
//            let thoroughfare = placemark.thoroughfare, // 地名(丁目)
//            let subThoroughfare = placemark.subThoroughfare, // 番地
//            let postalCode = placemark.postalCode, // 郵便番号
//            let location = placemark.location // 緯度経度情報
//            else {
//                self.geocodeLabel.text = ""
//                return
//        }
//
//        self.geocodeLabel.text = """
//            〒\(postalCode)
//            \(administrativeArea)\(locality)\(thoroughfare)\(subThoroughfare)
//            \(location.coordinate.latitude), \(location.coordinate.longitude)
//        """
//    }
//}





