import UIKit

/// Encapsulates data for a row in an `OptionsTableView`.
///
struct OptionsTableViewOption: Equatable {
    let image: UIImage?
    let title: NSAttributedString

    // MARK: - Equatable

    static func ==(lhs: OptionsTableViewOption, rhs: OptionsTableViewOption) -> Bool {
        return lhs.title == rhs.title
    }
}

class OptionsTableView: UITableView {
    var options = [OptionsTableViewOption]()

    var onSelect: ((_ selected: Int) -> Void)?

    var cellDeselectedTintColor: UIColor? {
        didSet {
            reloadData()
        }
    }

    init(frame: CGRect, options: [OptionsTableViewOption]) {
        self.options = options
        super.init(frame: frame, style: .plain)
        self.delegate = self
        self.dataSource = self

        register(OptionsTableViewCell.self, forCellReuseIdentifier: OptionsTableViewCell.reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension OptionsTableView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        cell.accessoryType = .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }

        cell.accessoryType = .checkmark
        onSelect?(indexPath.row)
    }
}

extension OptionsTableView: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseCell = self.dequeueReusableCell(withIdentifier: OptionsTableViewCell.reuseIdentifier, for: indexPath) as! OptionsTableViewCell

        let option = options[indexPath.row]
        reuseCell.textLabel?.attributedText = option.title
        reuseCell.imageView?.image = option.image

        reuseCell.deselectedTintColor = cellDeselectedTintColor

        let isSelected = indexPath.row == super.indexPathForSelectedRow?.row
        reuseCell.isSelected = isSelected

        return reuseCell
    }
}

class OptionsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "OptionCell"

    var deselectedTintColor: UIColor?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        imageView?.tintColor = selected ? tintColor : deselectedTintColor
        accessoryType = selected ? .checkmark : .none
    }
}
