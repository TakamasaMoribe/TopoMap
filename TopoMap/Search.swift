//
//  Search.swift
//  TopoMap
//
//  Created by 森部高昌 on 2022/05/05
//  2022/06/08

import UIKit
import MapKit
import CoreLocation

class SearchController: UIViewController, UITextFieldDelegate,UISearchBarDelegate {
    
    // 検索地名入力用　サーチバー
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    // 検索結果を表示する tableView
    @IBOutlet weak var tableView: UITableView!
    
    // toolBarのBack ボタンを押したとき 画面遷移する
    @IBAction func backButtonClicked(_ sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
        self.present(nextView,animated: true, completion: { () in
        // nextView.inputLabel.text = self.textField.text // テキストも同時に引き継ぐ
        // self.dismiss(animated: true) //画面表示を消去
        })
    }

    private var searchCompleter = MKLocalSearchCompleter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //textField.delegate = self
        mySearchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchCompleter.delegate = self
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
        
        self.mySearchBar.endEditing(true)
    }
        

} // class SearchController:


//検索の結果は MKLocalSearchCompleter の results プロパティに入っています。 ここには先述の MKLocalSearchCompletion が配列で格納されているので、それをテーブルビューで表示するだけです。//
extension SearchController: UITableViewDelegate, UITableViewDataSource {
    // UITableViewDataSource と UITableViewDelegate のプロトコルを追加しています。
    // これに必然的に、以下の2つのメソッドを実装が必要になります。
    // セルの数の取得とセルの生成
    
    // UITableView に表示したいセルの数を取得する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count // 検索結果の個数
    }

    // セルの数だけ呼び出されて、得られた値を各セルに代入して生成(表示)する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let completion = searchCompleter.results[indexPath.row]//配列に入っている
                cell.textLabel?.text = completion.title // 場所の名前表示
                cell.detailTextLabel?.text = completion.subtitle // 住所など表示
        return cell
    }
    
    // didSelectRowAtがCellを触ったことを感知している
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("第\(indexPath.section)セクションの\(indexPath.row)番セル") // 確認用
        let cell: UITableViewCell = self.tableView(tableView, cellForRowAt: indexPath)
        if let selectedPlace = cell.textLabel?.text { // 選んだセルに地名があれば
            if let selectedAddress = cell.detailTextLabel?.text! { //選んだセルに住所があれば
                print("選択したセルの内容:\(selectedAddress)") // 確認用
                // 次を実行する　緯度経度を取得することができる
                //↓

                let searchPlace = selectedAddress
                //CLGeocoderインスタンスを取得
                let geocoder = CLGeocoder()//geocoder
                //入力された文字から位置情報を取得
                geocoder.geocodeAddressString(searchPlace, completionHandler: { (placemarks, error) in
                //位置情報が存在する場合（定数geocoderに値が入ってる場合)はunwrapPlacemarksに取り出す。

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
                           UserDefaults.standard.set(selectedAddress, forKey:"targetPlace")
                            UserDefaults.standard.set(targetLatitude, forKey:"targetLatitude")
                            UserDefaults.standard.set(targetLongitude, forKey:"targetLongitude")
                            UserDefaults.standard.synchronize()
    // 地図画面へ遷移する
       let storyboard: UIStoryboard = self.storyboard!
       let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
       self.present(nextView,animated: true, completion: { () in
           nextView.myPin.subtitle = selectedAddress //  pin をnextViewの変数にした
           nextView.myPin.title = selectedPlace //　引き継ぎが可能になった

    //           nextView.ido = selectedAddress // テキストも同時に引き継ぐか？
           
           print("selectedPlace:\(selectedPlace)")
           print("selectedAddress:\(selectedAddress)")
       // self.dismiss(animated: true) //画面表示を消去
       })
                           
                           
                           
                       } // if let location
                     } // if let firstPlacemark
                    } // if let unwrapPlacemark
                    else {
                    print("緯度経度のデータが見つかりません")//ここもOK
                    }
                })//geocoder.geocodeAddressString(searchPlace,
                
                
                //↑
            }
        }
       }
        
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

