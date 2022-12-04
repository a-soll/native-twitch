import Foundation

class SwiftClient {
    var client = Client()
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")
    var oAuth = UserDefaults.standard.string(forKey: "OAuthToken")
    var useAdblock = UserDefaults.standard.bool(forKey: "UseAdblock")
    var c_oAuth: CStringWrapper
    var c_accessToken: CStringWrapper
    var c_clientId = CStringWrapper(s: "gp762nuuoqcoxypju8c569th9wz7q5")
    var c_userId: CStringWrapper
    var c_userLogin: CStringWrapper
    
    init() {
        let cstr = oAuth?.cString(using: .utf8)
        self.c_oAuth = CStringWrapper(s: self.oAuth!)
        self.c_accessToken = CStringWrapper(s: self.accessToken!)
        self.c_userId = CStringWrapper(s: self.userId!)
        self.c_userLogin = CStringWrapper(s: self.userLogin!)
        Client_init(&self.client, self.c_accessToken.cStringPtr, self.c_clientId.cStringPtr, c_userId.cStringPtr, self.c_userLogin.cStringPtr, self.c_oAuth.cStringPtr)
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
