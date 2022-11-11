import Foundation

class SwiftClient {
    var client = Client()
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")

    init() {
        Client_init(&self.client, self.accessToken, "gp762nuuoqcoxypju8c569th9wz7q5", &self.userId, self.userLogin)
    }

    deinit {
        client_clear_headers(&self.client)
    }
}
