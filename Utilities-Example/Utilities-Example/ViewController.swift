//
//  ViewController.swift
//  Utilities-Example
//
//  Created by Johan Bergsee on 2024-08-15.
//
//

import UIKit

class ViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private lazy var demos: [(title: String, builder: () -> UIViewController)] = {
        var list: [(title: String, builder: () -> UIViewController)] = [
            ("ProgressHUD Demo", { ProgressHUDDemoViewController() }),
        ]
        if #available(iOS 18.0, *) {
            list.append(("ValidatedField Demo", { ValidatedFieldDemoViewController() }))
        }
        return list
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Utilities Examples"
        setupTableView()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = demos[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = demos[indexPath.row].builder()
        navigationController?.pushViewController(vc, animated: true)
    }
}
