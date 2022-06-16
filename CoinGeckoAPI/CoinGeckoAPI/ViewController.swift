//
//  ViewController.swift
//  CoinGeckoAPI
//
//  Created by IOS on 15/06/22.
//

import UIKit
import Foundation

struct CoinData :Decodable{
    var symbol: String
    var nama: String
    var image: String
    var current_price: Double
    var price_exhange: Double
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dataCD = [CoinData]()
    var loading = true
    var sendBack: Double = 0.0
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.tableView.reloadData()
        tableView.delegate = self
        tableView.dataSource = self
        getExchange()
    }
    
    func getCoin(){
        let headers = [
            "X-RapidAPI-Key": "cf03aa58eamsh3d91f495f620a0fp1a4987jsn9b043d002bb7",
            "X-RapidAPI-Host": "coingecko.p.rapidapi.com"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://coingecko.p.rapidapi.com/coins/markets?vs_currency=usd&page=1&per_page=100&order=market_cap_desc")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "")
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse ?? "")
            }
            if let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [Any]{
//                print(json)
                print("Harga USD to IDR: ", self.sendBack)
                var idx = 0
                for item in json{
                    idx = idx + 1
                    if let object = item as? [String:Any]{
                        let name = object["name"] as? String ?? ""
                        let symbol = object["symbol"] as? String ?? ""
                        let currentPrice = object["current_price"] as? Double ?? 0.0
                        let image = object["image"] as? String ?? ""
                        let exchangePrice = self.sendBack * currentPrice
                        self.dataCD.append(CoinData(symbol: symbol.self, nama: name.self, image: image.self, current_price: currentPrice.self, price_exhange: exchangePrice.self))
                        print("Index: ",idx, " Name: ", name, " USD: ", currentPrice, " IDR: ", exchangePrice)
                    }
                    self.loading = false
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        })
        dataTask.resume()
    }
    
    func getExchange(){
        let headers = [
            "X-RapidAPI-Key": "cf03aa58eamsh3d91f495f620a0fp1a4987jsn9b043d002bb7",
            "X-RapidAPI-Host": "currency-exchange.p.rapidapi.com"
        ]

        let request = NSMutableURLRequest(url: NSURL(string: "https://currency-exchange.p.rapidapi.com/exchange?from=USD&to=IDR&q=1.0")! as URL,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "")
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse ?? "")
            }
            if let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Double{
//                print(json)
                self.sendBack = json
                print("ToIDR: ", json)
                DispatchQueue.main.async {
                    self.getCoin()
                }
            }
        })

        dataTask.resume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loading{
            return 1
        }
        else{
            return dataCD.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! CustomTableViewCell

        if loading{
            cell.label1.text = "Loading..."
            cell.label2.text = "Loading..."
            cell.label3.text = "Loading..."
            cell.label4.text = "Loading..."
        }else{
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency

            formatter.locale = Locale(identifier: "en-US")
            let usd = formatter.string(from: dataCD[indexPath.row].current_price as NSNumber)

            formatter.locale = Locale(identifier: "id_ID")
            let idr = formatter.string(from: dataCD[indexPath.row].price_exhange as NSNumber)

            
            cell.iconImageView.downloaded(from: dataCD[indexPath.row].image)
            cell.label1.text = dataCD[indexPath.row].nama
            cell.label3.text = usd
            cell.label2.text = dataCD[indexPath.row].symbol.uppercased()
            //pembulatan 2 angka dibelakang koma
            cell.label4.text = idr
        }
        return cell
    }
    
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
