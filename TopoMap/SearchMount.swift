//  SearchMount.swift
//  Where
//
//  Created by 森部高昌 on 2021/12/19.
//  山の配列データをcsvファイルから読み込む。
//  [ふりがな,山名,緯度,経度,高度,都道府県名,山域名,地理院地図へのリンク]
//  山のデータを配列に入れる
//  ①searchBarに検索する山名を入力する
//  ②データを検索する
//  ③返ってきた値をtableViewに表示する。
//  ④tableViewで選択したcellから、山名・緯度・経度を取得する
//  2022/01/17

import UIKit

class SearchMountController: UIViewController, UISearchBarDelegate,UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var searchText: UISearchBar!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    
    // tableViewは、datasouce、delegateをviewControllerとの接続も必要。右クリックして確認できる

    var findItems:[[String]] = []
    
    // -------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //山の配列データをcsvファイルから読み込む。
        //[ふりがな,山名,緯度,経度,高度,都道府県名,山域名,地理院地図へのリンク]
        originalMountDatas = dataLoad()
        
        searchText.delegate = self
        searchText.placeholder = "ひらがなで、地名を入力してください"
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // -------------------------------------------------------------------------------
    //戻る"↩"ボタンで初期画面"StartViewController"に戻る
    
    @IBAction func backButtonClicked(_ sender: UIBarButtonItem) {
        
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "StartViewController") as! ViewController
        self.dismiss(animated: true) //画面表示を消去
        self.present(nextView, animated: true, completion: nil)
        
   }
    
    // csvファイルから、山のデータを読み込む　"MountData.csv"
    func dataLoad() -> [[String]] {
        // データを格納するための配列を準備する
        var dataArray :[[String]] = [] // 二重配列にして、空配列にしておく
        // データの読み込み準備 ファイルが見つからないときは実行しない
        guard let thePath = Bundle.main.path(forResource: "MountData", ofType: "csv") else {
            return [["null"]]
        }
        
        do {
            let csvStringData = try String(contentsOfFile: thePath, encoding: String.Encoding.utf8)
            csvStringData.enumerateLines(invoking: {(line,stop) in //改行されるごとに分割する
            let data = line.components(separatedBy: ",") //１行を","で分割して配列に入れる
                dataArray.append(data) // 格納用の配列に、１行ずつ追加していく
                }) // invokingからのクロージャここまで
        }catch let error as NSError {
                 print("ファイル読み込みに失敗。\n \(error)")
        } // Do節ここまで
         
        // dataArray 山のデータ 二重配列
        //print(dataArray[100])  //OK
        
        return dataArray

    }

    
    //　以下　SearchBar 関係　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    // searchBarへの入力に対する処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true) //キーボードを閉じる
        if let searchWord = searchBar.text {
            searchMount(keyword: searchWord) //入力されていたら、山名を検索する
        }
    }
  
    //---------------------------------------------------------------
    // 山名の検索  ：keyword 検索したい語句
    func searchMount(keyword:String) {
        findItems = [] // 空にしておく
        for data in originalMountDatas { //originalMountDatasから、１件ずつdataに取り出して調べる
//            if data[0] == keyword { //ふりがなの部分が一致したとき
//                self.findItems.append(data)// tableViewに表示する配列に追加
//                let lastItem = self.findItems[self.findItems.count - 1]//現在のデータ
//                    print("lastItem[1]:\(lastItem[1])") // 山名確認
//            }

            if (data[0].hasPrefix(keyword)){ //ふりがな部分が前方一致で見つかったとき
                print(data[0])//検索結果が表示される
                self.findItems.append(data)// tableViewに表示する配列に追加
            }else{
               //print("見つかりません")
            }
            
        }
        self.tableView.reloadData() //tableViewへ表示する
        //表示される
    }
    
            
    // 以下　tableView 関係　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    // 行数の取得
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.findItems.count
    }

    // セルへの表示
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
        let findItem = self.findItems[indexPath.row] // セルに表示されるデータ配列
        cell.textLabel?.text = findItem[0] + "(" + findItem[1] + ")" // 検索結果　山名の表示
        cell.detailTextLabel?.text = findItem[5] + "/" + findItem[6] // 検索結果　県名・山域名の表示
        return cell
    }

    // セルを選択したときの動作：データ保存、map画面へ遷移
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = self.findItems[indexPath.row]

        // 選択した地点のデータを保存する
        let userDefaults = UserDefaults.standard
        userDefaults.set(selectedItem[1], forKey: "selectmountName") // 山名
        userDefaults.set(selectedItem[2], forKey: "selectLatitude") // 緯度
        userDefaults.set(selectedItem[3], forKey: "selectLongitude") // 経度
                
        // map画面へ遷移する
        // ①storyboardのインスタンス取得
        let storyboard: UIStoryboard = self.storyboard!
        // ②遷移先ViewControllerのインスタンス取得
        let nextView = storyboard.instantiateViewController(withIdentifier: "CurrentViewController") as! CurrentViewController
        // ③画面遷移
        self.present(nextView, animated: true, completion: nil)
                
    }
    // 　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    
}
