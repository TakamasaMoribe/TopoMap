//
//  Search.swift
//  TopoMap
//
//  Created by 森部高昌 on 2022/05/05
//  2022/06/11

import UIKit
import MapKit
import CoreLocation

class SearchController: UIViewController, UITextFieldDelegate,UISearchBarDelegate {
    
    // 検索地名入力用　サーチバー
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    // 検索結果を表示する tableView
    @IBOutlet weak var tableView: UITableView!
    
    // toolBarのBack ボタンを押したとき、地図画面(起動画面)に遷移する
    @IBAction func backButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
        self.present(nextView,animated: true, completion: { () in
        // nextView.inputLabel.text = self.textField.text // テキストも引き継ぐ
        // self.dismiss(animated: true) //画面表示を消去
        })
    }

    private var searchCompleter = MKLocalSearchCompleter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mySearchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchCompleter.delegate = self
        // サーチバーにフォーカスをあてる
        mySearchBar.becomeFirstResponder()
    }

    
    // サーチバーに入力した文字を検索する
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchKey = mySearchBar.text {
            searchCompleter.queryFragment = searchKey // searchBarに入力した文字
            searchCompleter.resultTypes = .query //
            //searchCompleter.resultTypes = .pointOfInterest // 関連する場所
            //searchCompleter.resultTypes = .address // 地図上の位置のみ
            print("searchKey:\(searchKey)") // 確認用
        }
        self.mySearchBar.endEditing(true) // 入力終了(EnterKey)で、キーボードをしまう
    }
        
} // class SearchController:



//検索の結果は MKLocalSearchCompleter の results プロパティに入る。
//MKLocalSearchCompletion が配列で格納されているので、それをテーブルビューで表示する。
extension SearchController: UITableViewDelegate, UITableViewDataSource {
    // ２つのプロトコルを追加している。以下２つのメソッドを実装が必要になる。
    // セルの数の取得と、セルの生成
    
    // セルの数の取得　numberOfRowsInSection　表示したいセルの数を取得する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count // 検索して得られた結果の個数
    }

    // セルの生成　cellForRowAt　得られた値をセルに代入して生成(表示)する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let completion = searchCompleter.results[indexPath.row]//配列に入っている
                cell.textLabel?.text = completion.title // 場所の名前表示
                cell.detailTextLabel?.text = completion.subtitle // 住所など表示
        return cell
    }
    
    // didSelectRowAt　Cellを選択した(触った)ことを感知している
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("第\(indexPath.section)セクションの\(indexPath.row)番セル") // 確認用
        let cell: UITableViewCell = self.tableView(tableView, cellForRowAt: indexPath)
        if let selectedPlace = cell.textLabel?.text { // 選んだセルに地名があれば
            if let selectedAddress = cell.detailTextLabel?.text! { //さらに住所があれば
                print("選択したセルの内容:\(selectedAddress)") // 確認用
                
                //↓　緯度経度を取得する
                let searchPlace = selectedAddress
                //CLGeocoderインスタンスを生成する
                let geocoder = CLGeocoder()//geocoder
                //入力された文字から位置情報を取得する
                geocoder.geocodeAddressString(searchPlace, completionHandler: { (placemarks, error) in
                //位置情報が存在する場合(geocoderに値がある時)はunwrapPlacemarksに取り出す。
                    if let unwrapPlacemarks = placemarks {
                        print("unwrapPlacemarks:\(unwrapPlacemarks)")
                        //1件目の情報を取り出す
                        if let firstPlacemark = unwrapPlacemarks.first {
                        print("firstPlacemark:\(firstPlacemark)")
                            //位置情報を取り出す
                            if let location = firstPlacemark.location {
                            print("location:\(location)")
                         //位置情報から緯度経度をtargetCoordinateに取り出す
                           let targetCoordinate = location.coordinate //確認用
                           let targetLatitude = location.coordinate.latitude
                           let targetLongitude = location.coordinate.longitude

                          print("位置情報:\(targetCoordinate)") //確認用
                           // Userdeaults.standard に保存する
                           UserDefaults.standard.set(selectedPlace, forKey:"targetPlace")
                            UserDefaults.standard.set(targetLatitude, forKey:"targetLatitude")
                            UserDefaults.standard.set(targetLongitude, forKey:"targetLongitude")
                            UserDefaults.standard.synchronize()
    // 地図画面へ遷移する
       let storyboard: UIStoryboard = self.storyboard!
       let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
       self.present(nextView,animated: true, completion: { () in
           nextView.myPin.title = selectedPlace // 地名　pinをnextViewの変数にした
           nextView.myPin.subtitle = selectedAddress // 住所　引き継ぎが可能
           // nextView.ido = selectedAddress // 緯度経度も同時に引き継ぐか？
           print("selectedPlace:\(selectedPlace)") //確認用
           print("selectedAddress:\(selectedAddress)") //確認用
           // self.dismiss(animated: true) //画面表示を消去
       })
                           
                       } // if let location =
                     } // if let firstPlacemark =
                    } // if let unwrapPlacemark =
                    else {
                    print("緯度経度のデータが見つかりません")//ここもOK
                    }
                })//geocoder.geocodeAddressString(searchPlace,
                                
                //↑ 緯度経度の取得　終わり
            } // if let selectedAddress =
        } // if let selectedPlace =
    } //func tableView(
} //extension SearchController: UITableViewDelegate, UITableViewDataSource {



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

