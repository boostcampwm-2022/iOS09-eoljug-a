//
//  DefaultFeedCellHeader.swift
//  Eoljuga
//
//  Created by youtak on 2022/11/17.
//

import UIKit

import SnapKit

class DefaultFeedCellHeader: UIStackView {

    lazy var profileImageView = UIImageView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = Constant.Image.profileSmall.cgFloat / 2
        $0.image = UIImage(systemName: "square.fill")
        $0.contentMode = .scaleAspectFill
    }

    lazy var nameLabel = UILabel().then {
        $0.textColor = UIColor.systemGray
        $0.font = UIFont.bold12
        $0.text = "하늘이"
    }

    lazy var badgeStackView = DefaultFeedCellBadgeStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        configureStackView()
        addArrangedSubViews([profileImageView, nameLabel, badgeStackView])
        configureProfileImageView()
    }

    private func configureStackView() {
        axis = .horizontal
        distribution = .equalSpacing
        alignment = .center
        spacing = Constant.space8.cgFloat
        isLayoutMarginsRelativeArrangement = true
    }

    private func configureProfileImageView() {
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(Constant.Image.profileSmall)
        }
    }
}
