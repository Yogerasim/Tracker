import UIKit

final class ContainerTableViewCell: UITableViewCell {
    
    private let leftPadding: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.systemGray4
        view.layer.zPosition = 1 // separator всегда выше контента галочки
        return view
    }()
    
    var isLastCell: Bool = false {
        didSet {
            separatorLine.isHidden = isLastCell
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStyle() {
        backgroundColor = .systemGray6
        contentView.backgroundColor = .systemGray6
        selectionStyle = .none
        layoutMargins = .zero
        separatorInset = .zero
        
        contentView.addSubview(leftPadding)
        NSLayoutConstraint.activate([
            leftPadding.widthAnchor.constraint(equalToConstant: 20),
            leftPadding.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftPadding.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            leftPadding.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        ])
        
        if let label = textLabel {
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leftPadding.trailingAnchor),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
                label.topAnchor.constraint(equalTo: contentView.topAnchor),
                label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
        
        contentView.addSubview(separatorLine)
        NSLayoutConstraint.activate([
            separatorLine.heightAnchor.constraint(equalToConstant: 1),
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

extension ContainerTableViewCell {
    
    /// Настраивает ячейку с заголовком и опциональной деталью
    func configure(title: String, detail: String?) {
        // Удаляем предыдущий стек, если есть
        contentView.viewWithTag(101)?.removeFromSuperview()
        
        // Основной заголовок
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppFonts.body
        titleLabel.textColor = AppColors.backgroundBlackButton
        
        let stack: UIStackView
        if let detail = detail, !detail.isEmpty {
            let detailLabel = UILabel()
            detailLabel.text = detail
            detailLabel.font = AppFonts.caption2
            detailLabel.textColor = AppColors.gray
            
            stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
            stack.axis = .vertical
            stack.spacing = 4
        } else {
            stack = UIStackView(arrangedSubviews: [titleLabel])
            stack.axis = .vertical
            stack.spacing = 0
        }
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.tag = 101
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        accessoryType = .disclosureIndicator
        selectionStyle = .none
    }
}
