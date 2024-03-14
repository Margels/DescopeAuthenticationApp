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
    
    private lazy var signInOrUpStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.distribution = .fill
        sv.spacing = 5
        return sv
    }()
    
    private lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.borderStyle = .none
        tf.placeholder = "Insert your email address here..."
        tf.delegate = self
        return tf
    }()
    
    private lazy var emailTextFieldLine: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .tertiaryLabel
        return v
    }()
    
    private lazy var signInOrUpButton: UIButton = {
        let b = UIButton()
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .clear
        b.setTitle("Sign in or up", for: .normal)
        b.setTitleColor(.systemGreen, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        b.alpha = 0.5
        b.isUserInteractionEnabled = false
        b.addTarget(self, action: #selector(didTapSignInOrUp), for: .touchUpInside)
        return b
    }()
    
    private lazy var otpStackView: UIStackView = {
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
    var loginId = ""
    var code: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpViews()
        setUpConstraints()
        
    }
    
    private func setUpViews() {
        self.view.addSubview(containerStackView)
        
        containerStackView.addArrangedSubview(signInOrUpStackView)
        signInOrUpStackView.addArrangedSubview(emailTextField)
        signInOrUpStackView.addArrangedSubview(emailTextFieldLine)
        signInOrUpStackView.addArrangedSubview(signInOrUpButton)
        signInOrUpStackView.setCustomSpacing(15, after: emailTextFieldLine)
        
        containerStackView.addArrangedSubview(otpStackView)
        otpStackView.addArrangedSubview(otpTextField)
        otpStackView.addArrangedSubview(otpTextFieldLine)
        otpStackView.addArrangedSubview(continueButton)
        otpStackView.setCustomSpacing(15, after: otpTextFieldLine)
        
        otpStackView.isHidden = true
    }
    
    private func setUpConstraints() {
        NSLayoutConstraint.activate([
            
            containerStackView.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
            containerStackView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
            self.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor, constant: 50),
            emailTextFieldLine.heightAnchor.constraint(equalToConstant: 1),
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
            DispatchQueue.main.async {
                self.signInOrUpStackView.isHidden = true
                UIView.animate(withDuration: 1, delay: 0) {
                    self.otpStackView.isHidden = false
                }
            }
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
    
    @objc private func didTapSignInOrUp() {
        Task { await signUpDemoUser() }
    }
    
}


extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let isTextEmpty = textField.text == nil || textField.text == ""
        switch (textField, textField.text) {
        case (emailTextField, .some(let text)):
            self.loginId = text
            signInOrUpButton.alpha = isTextEmpty ? 0.5 : 1
            signInOrUpButton.isUserInteractionEnabled = isTextEmpty ? false : true
        case (otpTextField, .some(let text)):
            self.code = text
            continueButton.alpha = isTextEmpty ? 0.5 : 1
            continueButton.isUserInteractionEnabled = isTextEmpty ? false : true
        default:
            [signInOrUpButton, continueButton].forEach { $0.alpha = 0.5 }
            [signInOrUpButton, continueButton].forEach { $0.isUserInteractionEnabled = false }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
