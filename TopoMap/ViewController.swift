//
//  ViewController.swift
//  TopoMap
//
//  Created by 森部高昌 on 2021/09/26.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    @IBAction func sliderDidChange(_ slider: UISlider) {
        if let renderer = mapView.renderer(for: tileOverlay) {
            renderer.alpha = CGFloat(slider.value)
        }
    }
    
    // 国土地理院が提供する色別標高図のURL
    // ここを変えるだけで、様々な地図データを表示できる！
    private let tileOverlay = MKTileOverlay(urlTemplate: "https://cyberjapandata.gsi.go.jp/xyz/std/{z}/{x}/{y}.png")
    //https://cyberjapandata.gsi.go.jp/xyz/relief/{z}/{x}/{y}.png

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.addOverlay(tileOverlay, level: .aboveLabels)
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return MKTileOverlayRenderer(overlay: overlay)
    }
}

