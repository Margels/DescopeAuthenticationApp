import Vapor
import Leaf
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    let rsaPublicKey = """
-----BEGIN PUBLIC KEY-----

-----END PUBLIC KEY-----
"""

    // Initialize an RSA key with public pem.
    let key = try RSAKey.public(pem: rsaPublicKey)
    app.jwt.signers.use(.rs256(key: key))
    
    app.views.use(.leaf)
    
    
    // register routes
    try routes(app)
}

// JWT payload structure.
struct TestPayload: JWTPayload, Content {
    
    // Maps the longer Swift property names to the
    // shortened keys used in the JWT payload.
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case roles = "roles"
        case deliveryMethod = "amr"
        case permissions = "permissions"
        case userInfo = "nsec"
    }

    // The "sub" (subject) claim identifies the principal that is the
    // subject of the JWT.
    var subject: SubjectClaim

    // The "exp" (expiration time) claim identifies the expiration time on
    // or after which the JWT MUST NOT be accepted for processing.
    var expiration: ExpirationClaim
    
    var roles: [String]
    var deliveryMethod: [String]
    var permissions: [String]
    var userInfo: [String: String]

    // Run any additional verification logic beyond
    // signature verification here.
    // Since we have an ExpirationClaim, we will
    // call its verify method.
    func verify(using signer: JWTSigner) throws {
        try self.expiration.verifyNotExpired()
    }
}
