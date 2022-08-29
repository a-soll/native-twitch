import Foundation
class SwiftClient {
    var client: Client
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")

    init() {
        client = Client_init(self.accessToken, self.userId, self.userLogin)
    }

    deinit {
        clear_headers(&client)
    }
}
