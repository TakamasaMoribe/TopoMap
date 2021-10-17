//
//  Search.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/10/13.
//

import UIKit
import MapKit
import CoreLocation

class SearchController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var textField: UITextField!
    // 検索用テキストフィールド
    @IBOutlet weak var tableView: UITableView!

    
    private var searchCompleter = MKLocalSearchCompleter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        searchCompleter.delegate = self

        // 東京駅を中心にして検索する
        let tokyoStation = CLLocationCoordinate2DMake(35.6811673, 139.7670516) // 東京駅
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001) // ここは適当な値です
        let region = MKCoordinateRegion(center: tokyoStation, span: span)
        searchCompleter.region = region
        
        searchCompleter.resultTypes = .pointOfInterest // 関連する場所
//        searchCompleter.resultTypes = .address //地図上の位置のみ検索する
//        searchCompleter.resultTypes = .query //
    }
    
    @IBAction func textFieldEditingChanged(_ sender: Any) {
        // テキストフィールドに入力されたとき
        searchCompleter.queryFragment = textField.text!
    }

    
    //--------------------------------------------------
    // tableView から選択したときの動作とは違っているので、要変更　選択したセルの値を使うようにする
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
          //キーボードを閉じる。resignFirstResponderはdelegateメソッド
          textField.resignFirstResponder()
          //入力された文字を取り出す
            if let searchKey = textField.text {
             //入力された文字をデバッグエリアに表示
             print(searchKey) //・・・・・・できる
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
                      let targetCoordinate = location.coordinate
                      //緯度経度をデバッグエリアに表示・・・・できた
                      print("targetCoordinate:\(targetCoordinate)")
                       
//--- ここでは、描画はしない
//                       //MKPointAnnotationインスタンスを取得し、ピンを生成
//                        let pin = MKPointAnnotation()
//                       //ピンの置く場所に緯度経度を設定
//                        pin.coordinate = targetCoordinate
//                       //ピンのタイトルを設定
//                        pin.title = searchKey
//                       //ピンを地図に置く
//                        //self.Map.addAnnotation(pin)
//                       self.mapView.addAnnotation(pin)
//                       //検索地点の緯度経度を中心に半径500mの範囲を表示
//                        self.mapView.region = MKCoordinateRegion(center: targetCoordinate, latitudinalMeters: 500.0, longitudinalMeters: 500.0)
//---
                       
                   }
                  }
                }
                })
            }
            //デフォルト動作を行うのでtureを返す。返り値型をBoolにしているため、この記述がないとエラーになる。
           return true
        }
        
}

extension SearchController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompleter.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        //
        let completion = searchCompleter.results[indexPath.row]
                cell.textLabel?.text = completion.title
                cell.detailTextLabel?.text = completion.subtitle
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           print(indexPath.section)
           print(indexPath.row)
        
        print("第\(indexPath.section)セクションの\(indexPath.row)番セルが選択されました")
        
        let cell: UITableViewCell = self.tableView(tableView, cellForRowAt: indexPath)
                print((cell.textLabel?.text)!)

           //print(tableData[indexPath.section][indexPath.row])
       }
    
}


extension SearchController: MKLocalSearchCompleterDelegate {
    
    // 正常に検索結果が更新されたとき
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        tableView.reloadData()
    }
    
    // 検索が失敗したとき
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // エラー処理
    }
}

