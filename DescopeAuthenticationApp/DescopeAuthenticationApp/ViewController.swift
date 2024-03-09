//
//  ViewController.swift
//  DescopeAuthenticationApp
//
//  Created by Margels on 21/02/24.
//

import UIKit
import DescopeKit
import AuthenticationServices

class ViewController: UIViewController {
    
    private lazy var containerStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.distribution = .fill
        sv.spacing = 5
        return sv
    }()
    
    private lazy var otpTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .none
        tf.placeholder = "Insert OTP here..."
        tf.delegate = self
        return tf
    }()
    
    private lazy var otpTextFieldLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .tertiaryLabel
        return v
    }()
    
    private lazy var continueButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .clear
        b.setTitle("Continue", for: .normal)
        b.setTitleColor(.systemGreen, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        b.alpha = 0.5
        b.isUserInteractionEnabled = false
        b.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
        return b
    }()
    
    let deliveryMethod: DeliveryMethod = .email
    let loginId = "<YOUR_TEST_EMAIL_ADDRESS>"
    var code: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        setUpConstraints()
        
        Task { await signUpDemoUser() }
        
    }
    
    private func setUpViews() {
        self.view.addSubview(containerStackView)
        containerStackView.addArrangedSubview(otpTextField)
        containerStackView.addArrangedSubview(otpTextFieldLine)
        containerStackView.addArrangedSubview(continueButton)
        containerStackView.setCustomSpacing(15, after: otpTextFieldLine)
    }
    
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            
            containerStackView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            containerStackView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            self.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: 50),
            otpTextFieldLine.heightAnchor.constraint(equalToConstant: 1)
            
        ])
    }
    
    private func signUpDemoUser() async {
        
        // Args:
        //    deliveryMethod: Delivery method to use to send OTP. Supported values include DeliveryMethod.email or DeliveryMethod.sms
        let deliveryMethod = self.deliveryMethod
        //    loginId: email or phone - becomes the loginId for the user from here on and also used for delivery
        let loginId = self.loginId
        //    user: Optional user object to populate new user information.
        var signInOptions: [SignInOptions] = [.customClaims([
            "name": "Test User", 
            "phone": "000000000"
        ])]
        if let session = Descope.sessionManager.session {
            signInOptions.append(contentsOf: [
                .mfa(refreshJwt: session.refreshJwt),
                .stepup(refreshJwt: session.refreshJwt)
            ])
        }
        
        do {
            let string = try await Descope.otp.signUpOrIn(with: deliveryMethod, loginId: loginId, options: signInOptions)
            print("Successfully initiated OTP Sign Up or In for \(string)")
        } catch {
            print("Failed to initiate OTP Sign Up or In with Error: \(error)")
        }
        
    }
    
    private func verifyDemoUser() async {
        
        // Args:
        //    deliveryMethod: Delivery method to use to send OTP. Supported values include DeliveryMethod.email or DeliveryMethod.sms
        let deliveryMethod = self.deliveryMethod
        //   loginId (str): The loginId of the user being validated
        let loginId = self.loginId
        //   code (str): The authorization code enter by the end user during signup/signin
        let code = self.code
        
        do {
            let descopeSession = try await Descope.otp.verify(with: deliveryMethod, loginId: loginId, code: code)
            let jwt = descopeSession.sessionToken.jwt
            
            
            Constants.shared.getUserInformation(with: jwt) { userInfo in
                var outcomeAlertTitle = ""
                var outcomeAlertMessage = ""
                var permissions = userInfo?.permissions?.first
                let role = userInfo?.roles?.first
                switch (role, role == "Example") {
                case (.some(let roleStringValue), true):
                    outcomeAlertTitle = "Authenticated successfully"
                    outcomeAlertMessage = "You have \(roleStringValue) role which allows you to have \(permissions ?? "access") to the app."
                default:
                    outcomeAlertTitle = "Authentication denied"
                    outcomeAlertMessage = "You currently do not have role permissions to have full access to the app."
                }
                self.showAlert(title: outcomeAlertTitle, message: outcomeAlertMessage)
            }
            
        } catch DescopeError.wrongOTPCode {
            print("Failed to verify OTP Code: ")
            print("Wrong code entered")
        } catch {
            print("Failed to verify OTP Code: ")
            print(error)
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
    @objc private func didTapContinue() {
        Task { await verifyDemoUser() }
    }
    
}


extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.text {
        case .some(let text):
            self.code = text
            continueButton.alpha = 1
            continueButton.isUserInteractionEnabled = true
        case .none:
            continueButton.alpha = 0.5
            continueButton.isUserInteractionEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
