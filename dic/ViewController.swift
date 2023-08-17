import UIKit
import SnapKit
import Alamofire
struct Welcome: Codable {
    let head: Head
    let def: [Def]
}
struct Def: Codable {
    let text, pos, gen, anm: String
    let tr: [Tr]
}
struct Tr: Codable {
    let text, pos: String
    let fr: Int
    let syn: [Syn]?
    let mean: [Mean]?
}
struct Mean: Codable {
    let text: String
}
struct Syn: Codable {
    let text, pos: String
    let fr: Int
}
struct Head: Codable {}
var history: [String] = []
class FirstViewController: UIViewController {
    let lbl1: UILabel = {
        let lbl = UILabel()
        lbl.text = "Русский"
        return lbl
    }()
    let tf: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Напишите то что хотите перевести"
        return tf
    }()
    let btn: UIButton = {
        let btn = UIButton()
        btn.setTitle("Перевести", for: .normal)
        btn.addTarget(self, action: #selector(translateBtn), for: .touchUpInside)
        btn.configuration = .filled()
        return btn
    }()
    let lbl2: UILabel = {
        let lbl = UILabel()
        lbl.text = "English"
        return lbl
    }()
    let tf2: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Result"
        return tf
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(tf)
        view.addSubview(lbl1)
        view.addSubview(tf2)
        view.addSubview(lbl2)
        view.addSubview(btn)
        tf.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        lbl1.snp.makeConstraints {
            $0.bottom.equalTo(tf.snp.bottom).offset(-50)
            $0.centerX.equalToSuperview()
        }
        tf2.snp.makeConstraints {
            $0.top.equalTo(lbl1).offset(-70)
            $0.centerX.equalToSuperview()
        }
        lbl2.snp.makeConstraints {
            $0.bottom.equalTo(tf2.snp.bottom).offset(-50)
            $0.centerX.equalToSuperview()
        }
        btn.snp.makeConstraints {
            $0.bottom.equalTo(tf.snp.bottom).offset(70)
            $0.centerX.equalToSuperview()
        }
    }
    @objc func translateBtn() {
        guard let text = tf.text else { return }
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let urlString = "https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=dict.1.1.20230817T100735Z.935837f9b3054433.935c4cb6270bbb085aaf37f6042de7e38477a804&lang=ru-en&text=\(encodedText)"
        AF.request(urlString).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(Welcome.self, from: data)
                    self.tf2.text = result.def.first?.tr.first?.text ?? ""
                    if let translation = self.tf2.text {
                        let pre = text
                        let res = "Текст: \(pre) Перевод: \(translation)"
                        history.insert(res, at: 0)
                        UserDefaults.standard.setValue(history, forKey: "history")
                    }
                } catch {
                    print("error: \(error)")
                }
            case .failure(let error):
                print("failure: \(error)")
            }
        }
    }
}
class SecondViewController: UIViewController {
    var history: [String] = UserDefaults.standard.array(forKey: "history") as? [String] ?? []
    let tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        history = UserDefaults.standard.array(forKey: "history") as? [String] ?? []
        tableView.reloadData()
    }
}
extension SecondViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = history[indexPath.row]
        return cell
    }
}
class ViewController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let fvc = FirstViewController()
        let fvci = UITabBarItem(title: "Словарь", image: UIImage(systemName: "character.book.closed"), selectedImage: UIImage(systemName: "character.book.closed.fill"))
        fvc.tabBarItem = fvci
        let svc = SecondViewController()
        let svci = UITabBarItem(title: "История", image: UIImage(systemName: "book"), selectedImage: UIImage(systemName: "book.fill"))
        svc.tabBarItem = svci
        self.viewControllers = [fvc, svc]
    }
}
