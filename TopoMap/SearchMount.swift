//  SearchMount.swift
//  Created by 森部高昌 on 2021/12/19.
//  山の配列データをcsvファイルから読み込む。
//  [ふりがな,山名,緯度,経度,高度,都道府県名,山域名,地理院地図へのリンク]
//  山のデータを配列に入れる
//  ①searchBarに検索する山名を入力する
//  ②データを検索する
//  ③返ってきた値をtableViewに表示する。
//  ④tableViewで選択したcellから、山名・緯度・経度を取得する

//  2022/01/17から再編集開始 データをサーチしてテーブルに表示する

import UIKit

class SearchMountController: UIViewController, UISearchBarDelegate,UITableViewDelegate, UITableViewDataSource {
// tableViewは、datasouce、delegateをviewControllerとの接続も必要。
// 右クリックして確認できる
    @IBOutlet weak var mySearchBar: UISearchBar!// Search.swiftでは、
    
    @IBOutlet weak var tableView: UITableView! // Search.swiftでも、同名

    // Back ボタンを押したとき、地図画面(起動画面)に遷移する
    @IBAction func backButtonClicked(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        let nextView = storyboard.instantiateViewController(withIdentifier: "Map") as! ViewController
        nextView.modalPresentationStyle = .fullScreen // 画面が下にずれることを解消できるようだ
        self.present(nextView,animated: true, completion: { () in
        })
    }
        
    var originalMountDatas:[[String]] = [] // 山のデータを読み込む配列
    var findItems:[[String]] = [] // 検索結果を入れる配列
    
    // -------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        originalMountDatas = dataLoad() //山の配列データをcsvファイルから読み込む。
            //内容：[ふりがな,山名,緯度,経度,高度,都道府県名,山域名,地理院地図へのリンク先アドレス]
        mySearchBar.delegate = self
        //searchText.placeholder = "ひらがなで、地名を入力してください"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // -------------------------------------------------------------------------------
    // csvファイルから、山のデータを読み込む　"MountData.csv"から読み込む
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
        return dataArray // dataArray 山のデータ 二重配列
    }
    
    //　以下　SearchBar 関係　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
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
            if (data[0].hasPrefix(keyword)){ //ふりがな部分が前方一致で見つかったとき
                print(data[0])//検索結果が表示される
                self.findItems.append(data)// tableViewに表示する配列に追加
            }else{
               //print("見つかりません")
            }
        }
        self.tableView.reloadData() //tableViewへ表示する
    }
    
            
    // 以下　tableView 関係　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
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
                
        // 最初のmap画面へ遷移する
        // ①storyboardのインスタンス取得
        let storyboard: UIStoryboard = self.storyboard!
        // ②遷移先ViewControllerのインスタンス取得
        let nextView = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        // ③画面遷移
        self.present(nextView, animated: true, completion: nil)
                
    }
    // 　＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
    
} // end of class SearchMountController
