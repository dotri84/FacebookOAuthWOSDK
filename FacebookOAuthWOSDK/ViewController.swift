//
//  ViewController.swift
//  FacebookOAuthWOSDK
//
//  Created by Do Tri on 9/10/18.
//  Copyright © 2018 Do Tri. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import SafariServices

extension URL {
    func getFragmentParam(key: String) -> String? {
        if let params = self.fragment?.components(separatedBy: "&") {
            for param in params {
                if let value = param.components(separatedBy: "=") as [String]? {
                    if value[0] == key {
                        return value[1]
                    }
                }
            }
        }
        return nil
    }
}

class ViewController: UIViewController {
    
    let authString = "https://www.facebook.com/dialog/oauth?client_id=567384830348150&redirect_uri=fb567384830348150%3A%2F%2Fauthorize&scope=public_profile&response_type=token"
    let callbackString = "fb567384830348150://authorize"
    
    @IBOutlet weak var loginFBBtn: UIButton!
    var safariVC : SFSafariViewController!
    @available(iOS 11.0, *)
    lazy var authSession : SFAuthenticationSession? = { return nil }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /*
     * Login with Custom Facebook Button
     */
    @IBAction func loginWithFacebookSDK(_ sender: UIButton) {
        let loginManager = LoginManager()
        loginManager.logIn(readPermissions: [.publicProfile], viewController: self) { (result) in
            switch result {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success( _,  _, let accessToken):
                print(accessToken.appId)
                print(accessToken.authenticationToken)
            }
        }
    }
    
    /*
     * Login with SFAuthenticationSession
     * What’s really cool about SFAuthenticationSession is you can add all of your login logic in the block immediately following the authentication session call (instead of intercepting the openURL method call in your app delegate like in iOS 9–10)
     */
    @IBAction func loginWithSFAuthenticationSession(_ sender: UIButton) {
        if #available(iOS 11.0, *) {
            authSession = SFAuthenticationSession(url: URL(string: authString)!, callbackURLScheme: callbackString) {
                (callBack: URL?, error: Error?) in
                guard error == nil, let successURL = callBack else {
                    // Log error or display error to the user here
                    return
                }
                
                let token = successURL.getFragmentParam(key: "access_token")
                
                print(token ?? "Empty token")
            }
            authSession?.start()
        } else {
            // Fallback on earlier versions
            // Use SFSafariViewController instead
        }
        
    }
    
    /*
     * Login with SFSafariViewController
     * Implementing OAuth 2.0 before iOS 11 required the interception of a Safari redirect with the AppDelegate's (application: openURL: options:) method. From there, most apps completed the OAuth process by either posting a notification or by calling a method on an instance variable of the App Delegate — distributing the authentication code across multiple objects.
     */
    @IBAction func loginWithSFSafariViewController(_ sender: UIButton) {
        NotificationCenter.default.addObserver(self, selector: #selector(safariLogin(_:)), name: Notification.Name.FacebookLoginOK, object: nil)
        
        safariVC = SFSafariViewController(url: URL(string: authString)!)
        safariVC!.delegate = self
        self.present(safariVC!, animated: true, completion: nil)
    }

    @objc func safariLogin(_ notification : Notification) {
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.FacebookLoginOK, object: nil)
        
        safariVC.dismiss(animated: true, completion: nil)
        
        guard let successURL = notification.object as? URL else {
            return
        }
        let token = successURL.getFragmentParam(key: "access_token")!
        print(token)
    }
}

//SFAuthenticationSession
extension ViewController : LoginButtonDelegate {
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        
    }
}

//SFSafariViewController
extension ViewController : SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.FacebookLoginOK, object: nil)
    }
}
