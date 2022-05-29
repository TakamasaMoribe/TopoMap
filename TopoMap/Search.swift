//
//  Search.swift
//  TopoMap
//
//  Created by 森部高昌 on 2022/05/05
//  検索地名の受け渡しはできている
//  tableView に表示される候補から選択すれば、緯度経度も得られる


import UIKit
import MapKit
import CoreLocation

class SearchController: UIViewController, UITextFieldDelegate {

    // 検索地名入力用テキストフィールド
    @IBOutlet weak var textField: UITextField!
    
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
    
    @IBAction func textFieldEditingChanged(_ sender: Any) {
        // テキストフィールドに入力されたとき
        searchCompleter.queryFragment = textField.text!
    }

    
    private var searchCompleter = MKLocalSearchCompleter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchCompleter.delegate = self

        // 東京駅を中心にして検索する
        let tokyoStation = CLLocationCoordinate2DMake(35.6811673, 139.7670516) // 東京駅
        let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0) // ここは適当な値です
        let region = MKCoordinateRegion(center: tokyoStation, span: span)
        searchCompleter.region = region
        
//        searchCompleter.resultTypes = .pointOfInterest // 関連する場所
//        searchCompleter.resultTypes = .address //地図上の位置のみ検索する
//        searchCompleter.resultTypes = .query //
        
    }
    

    //--------------------------------------------------
    // tableView から選択したあとに、リターンボタンを押したときはうまくいく
    // tableView のセルを選択したあとに、地図画面に遷移するようにしたい
    
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
          //キーボードを閉じる。resignFirstResponderはdelegateメソッド
          textField.resignFirstResponder()
            
        // セルの内容を取り出してみる
        //入力された文字を取り出す
          if let searchKey = textField.text {
           //入力された文字をデバッグエリアに表示
           print("searchKey:\(searchKey)") // 確認用

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
                     print("location\(location)")
                     let targetCoordinate = location.coordinate //確認用
                     let targetLatitude = location.coordinate.latitude
                     let targetLongitude = location.coordinate.longitude

                    print("位置情報が見つかりました:\(targetCoordinate)") //確認用
                    // Userdeaults.standard に保存する
                     UserDefaults.standard.set(targetLatitude, forKey:"targetLatitude")
                     UserDefaults.standard.set(targetLongitude, forKey:"targetLongitude")
                     UserDefaults.standard.synchronize()
                     
                     // 地図画面へ遷移する 位置情報があれば、遷移する
                     let storyboard: UIStoryboard = self.storyboard!
                     let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
                     self.present(nextView,animated: true, completion: nil) //{ () in
                     // nextView.inputLabel.text = self.textField.text // テキストも同時に引き継ぐ
                     //self.dismiss(animated: true) //画面表示を消去
                     //})
                     
                 }
                }

              }
              else {
                  print("緯度経度のデータが見つかりません")//ここもOK
              }
              })
          }
            

            //デフォルト動作を行うのでtureを返す。返り値型をBoolにしているため、この記述がないとエラーになる。
           return true
        }
}


extension SearchController: UITableViewDelegate, UITableViewDataSource {
    // UITableViewDataSource と UITableViewDelegate のプロトコルを追加しています。
    // これに必然的に、以下の2つのメソッドを実装が必要になります。
    // セルの数の取得とセルの生成
    
    // UITableView に表示したいセルの数を取得する
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count // 検索結果の個数
    }

    // セルの数だけ呼び出されて、各セルに得られた値を代入して生成する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let completion = searchCompleter.results[indexPath.row]
                cell.textLabel?.text = completion.title // 場所の名前
                cell.detailTextLabel?.text = completion.subtitle // 住所など
        return cell
    }
    
    // didSelectRowAtがCellを触ったといことを感知している
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("第\(indexPath.section)セクションの\(indexPath.row)番セルが選択されました") // 確認用
        
        let cell: UITableViewCell = self.tableView(tableView, cellForRowAt: indexPath)
            if let selectedText = cell.textLabel?.text! {
                if let detailText = cell.detailTextLabel?.text! {
                //textField.text = selectedText // 確認用
                print("選択したセルの内容:\(selectedText)") // 正しく表示される
                    print("detail:\(detailText)") //  正しく表示される
//              // Userdeaults.standard に保存する
                UserDefaults.standard.set(selectedText, forKey: "targetPlace")
                    
                }
            }
       }
}


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

