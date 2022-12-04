import Foundation

class SwiftClient {
    var client = Client()
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")
    var oAuth = UserDefaults.standard.string(forKey: "OAuthToken")
    var useAdblock = UserDefaults.standard.bool(forKey: "UseAdblock")

    init() {
        Client_init(&self.client, self.accessToken, "gp762nuuoqcoxypju8c569th9wz7q5", self.userId, self.userLogin, self.oAuth)
    }
    
    deinit {
        client_clear_headers(&self.client)
    }
}

// for longer life C strings
class CStringWrapper {
    var cStringPtr: UnsafeMutablePointer<CChar>
    
    init(s: String) {
        let cStringPtr = strdup(s)
        self.cStringPtr = cStringPtr!
    }
    
    deinit {
        free(cStringPtr)
    }
}
