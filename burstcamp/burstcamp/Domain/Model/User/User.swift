//
//  User.swift
//  Eoljuga
//
//  Created by neuli on 2022/11/17.
//

import Foundation

struct User: Codable {
    let userUUID: String
    let nickname: String
    let profileImageURL: String
    let domain: Domain
    let camperID: String
    let ordinalNumber: Int
    let blogURL: String
    let blogTitle: String
    var scrapFeedUUIDs: [String]
    let signupDate: Date
    let isPushOn: Bool
}

extension User {

    init(dictionary: [String: Any]) {
        self.userUUID = dictionary["userUUID"] as? String ?? ""
        self.nickname = dictionary["nickname"] as? String ?? ""
        self.profileImageURL = dictionary["profileImageURL"] as? String ?? ""
        let domainString = dictionary["domain"] as? String ?? "iOS"
        self.domain = Domain(rawValue: domainString) ?? .iOS
        self.camperID = dictionary["camperID"] as? String ?? ""
        self.ordinalNumber = dictionary["ordinalNumber"] as? Int ?? 7
        self.blogURL = dictionary["blogURL"] as? String ?? ""
        self.blogTitle = dictionary["blogTitle"] as? String ?? ""
        self.scrapFeedUUIDs = dictionary["scrapFeedUUIDs"] as? [String] ?? []
        self.signupDate = dictionary["signupDate"] as? Date ?? Date()
        self.isPushOn = dictionary["isPushOn"] as? Bool ?? false
    }

    init?(userUUID: String, signUpUser: SignUpUser, blogTitle: String) {
        self.userUUID = userUUID

        if let nickname = signUpUser.getNickname(),
           let domain = signUpUser.getDomain(),
           let camperID = signUpUser.getCamperID() {
            self.nickname = nickname
            self.profileImageURL = "https://github.com/\(nickname).png"
            self.domain = domain
            self.camperID = camperID
        } else {
            return nil
        }

        self.ordinalNumber = 7
        self.blogURL = signUpUser.getBlogURL()
        self.blogTitle = blogTitle
        self.scrapFeedUUIDs = []
        self.signupDate = Date()
        self.isPushOn = false
    }

    init(userAPIModel: UserAPIModel) {
        self.userUUID = userAPIModel.userUUID
        self.nickname = userAPIModel.nickname
        self.profileImageURL = userAPIModel.profileImageURL
        self.domain = Domain(rawValue: userAPIModel.domain) ?? .iOS
        self.camperID = userAPIModel.camperID
        self.ordinalNumber = userAPIModel.ordinalNumber
        self.blogURL = userAPIModel.blogURL
        self.blogTitle = userAPIModel.blogTitle
        self.scrapFeedUUIDs = userAPIModel.scrapFeedUUIDs
        self.signupDate = userAPIModel.signupDate
        self.isPushOn = userAPIModel.isPushOn
    }
    
    var toFeedWriter: FeedWriter {
        return FeedWriter(
            userUUID: self.userUUID,
            nickname: self.nickname,
            camperID: self.camperID,
            ordinalNumber: self.ordinalNumber,
            domain: self.domain,
            profileImageURL: self.profileImageURL,
            blogTitle: self.blogTitle
        )
    }

    func newUser(profileImageURL: String) -> User {
        return User(
            userUUID: self.userUUID,
            nickname: self.nickname,
            profileImageURL: profileImageURL,
            domain: self.domain,
            camperID: self.camperID,
            ordinalNumber: self.ordinalNumber,
            blogURL: self.blogURL,
            blogTitle: self.blogTitle,
            scrapFeedUUIDs: self.scrapFeedUUIDs,
            signupDate: self.signupDate,
            isPushOn: self.isPushOn
        )
    }
}
