import Foundation

class SwiftClient {
    var client = Client()
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")

    init() {
        Client_init(&self.client, self.accessToken, "gp762nuuoqcoxypju8c569th9wz7q5", self.userId, self.userLogin)
    }

    deinit {
        clear_headers(&self.client)
    }
}

//func start_client() -> Client {
//    let accessToken = UserDefaults.standard.string(forKey: "AccessToken")
//    let userLogin = UserDefaults.standard.string(forKey: "UserLogin")
//    let userId = UserDefaults.standard.string(forKey: "UserId")
//
//    var client = Client()
//    Client_init(&client, accessToken, "gp762nuuoqcoxypju8c569th9wz7q5", userId, userLogin)
//    return client
//}
