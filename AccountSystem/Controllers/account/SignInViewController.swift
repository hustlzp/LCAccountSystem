//
//  SignInViewController.swift
//  AccountSystem
//
//  Created by hustlzp on 2019/7/25.
//  Copyright © 2019 hustlzp. All rights reserved.
//

import UIKit
import MBProgressHUD
import PromiseKit
import SDWebImage
import AVOSCloud

class SignInViewController: AccountBaseViewController {
    private var phoneField: AccountTextField!
    private var passwordField: AccountTextField!
    
    // MARK: Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: View Lifecycle
    
    override func loadView() {
        super.loadView()
        
        phoneField = AccountTextField(placeholder: "手机号".localized(), keyboardType: .numberPad)
        stackView.addRow(phoneField, inset: UIEdgeInsets(top: Size.accountFirstFieldTopGap, left: Size.accountFieldHorizonalGap, bottom: 0, right: Size.accountFieldHorizonalGap))
        
        passwordField = AccountTextField(placeholder: "密码".localized(), isSecure: true)
        stackView.addRow(passwordField, inset: UIEdgeInsets(top: Size.accountFieldTopGap, left: Size.accountFieldHorizonalGap, bottom: 0, right: Size.accountFieldHorizonalGap))
        
        let submitButton = AccountButton(title: "登录".localized(), target: self, action: #selector(submit))
        stackView.addRow(submitButton, top: 30, left: Size.accountFieldHorizonalGap, bottom: 0)
        
        let forgotPasswordText = NSMutableAttributedString(string: "忘记密码？".localized(), attributes: [.font: UIFont.systemFont(ofSize: 15, weight: .regular), .foregroundColor: UIColor.lightGray])
        let forgotPasswordButton = createTextButton(forgotPasswordText, action: #selector(goToForgotPassword))
        stackView.addRow(forgotPasswordButton, top: 45, left: 0, bottom: 0)
        
        let socialWapView = createSocialWapView()
        view.addSubview(socialWapView)
        
        socialWapView.snp.makeConstraints { (make) in
            make.centerX.equalTo(view)
            make.bottom.equalTo(view).offset(-40 - Size.safeAreaBottomGap)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "登录".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "注册".localized(), style: .plain, target: self, action: #selector(goToSignUp))
    }
    
    // MARK: User Interaction
    
    @objc private func submit() {
        guard let phone = self.phoneField.text?.trim(), !phone.isEmpty else {
            MBProgressHUD.showForInfo(UIApplication.shared.keyWindow!, text: "手机号不能为空".localized())
            return
        }
        
        guard let password = passwordField.text?.trim(), !password.isEmpty else {
            MBProgressHUD.showForInfo(UIApplication.shared.keyWindow!, text: "密码不能为空".localized())
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        
        view.endEditing(true)
        
        User.logInWithMobilePhone(.promise, phone, password: password).then { (_) -> Guarantee<Void> in
            return hud.hideForSuccess(.promise, "登录成功".localized())
        }.done { (_) in
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            self.navigationController?.popToRootViewController(animated: true)
        }.catch { (error) in
            hud.hideForError(error)
        }
    }
    
    @objc private func goToForgotPassword() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
    }
    
    @objc private func goToSignUp() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
    
    @objc private func signInByQQ() {
        signIn(platform: .qq)
    }
    
    @objc private func signInByWechat() {
        signIn(platform: .wechat)
    }
    
    @objc private func signInByWeibo() {
        signIn(platform: .weibo)
    }
    
    @objc private func signInByTwitter() {
        signIn(platform: .twitter)
    }
    
    @objc private func signInByFacebook() {
        signIn(platform: .facebook)
    }
    
    // MARK: Notification Handler
    
    // MARK: View Helpers
    
    func createTextButton(_ attributedString: NSAttributedString, action: Selector) -> UIButton {
        let textButton = UIButton()
        textButton.addTarget(self, action: action, for: .touchUpInside)
        
        let label = UILabel()
        label.isUserInteractionEnabled = false
        label.attributedText = attributedString
        textButton.addSubview(label)
        
        // 约束
        
        textButton.snp.makeConstraints { (make) in
            make.height.equalTo(38)
        }
        
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: Size.accountFieldHorizonalGap, bottom: 0, right: Size.accountFieldHorizonalGap))
        }
        
        return textButton
    }
    
    func createSocialWapView() -> UIStackView {
        let wapView = UIStackView()
        wapView.axis = .horizontal
        
        if UMSocialManager.default().isInstall(.QQ) {
            let qqButton = SocialAuthButton(platformType: .qq, target: self, action: #selector(signInByQQ))
            wapView.addArrangedSubview(qqButton)
        }
        
        if UMSocialManager.default().isInstall(.sina) {
            let weiboButton = SocialAuthButton(platformType: .weibo, target: self, action: #selector(signInByWeibo))
            wapView.addArrangedSubview(weiboButton)
        }
        
        if UMSocialManager.default().isInstall(.wechatSession) {
            let wechatButton = SocialAuthButton(platformType: .wechat, target: self, action: #selector(signInByWechat))
            wapView.addArrangedSubview(wechatButton)
        }
        
        if UMSocialManager.default().isInstall(.twitter) {
            let twitterButton = SocialAuthButton(platformType: .twitter, target: self, action: #selector(signInByTwitter))
            wapView.addArrangedSubview(twitterButton)
        }
        
        if UMSocialManager.default().isInstall(.facebook) {
            let facebookButton = SocialAuthButton(platformType: .facebook, target: self, action: #selector(signInByFacebook))
            wapView.addArrangedSubview(facebookButton)
        }
        
        return wapView
    }
    
    // MARK: Internal Helpers
    
    private func signIn(platform: SocialPlatform) {
        UMSocialManager.default()?.getUserInfo(.promise, platformType: platform.platformTypeForUM, currentViewController: self).done({ (response) in
            let result = Utils.getAuthDateAndOptionFromUMResponse(response, platform: platform)
            
            guard let authData = result.authData else {
                MBProgressHUD.showForError(UIApplication.shared.keyWindow!, error: MyError.custom(errorDescription: String(format: "%@ 登录失败".localized(), platform.name)))
                return
            }
            
            let hud = MBProgressHUD.showAdded(to: UIApplication.shared.keyWindow!, animated: true)
            
            let option = result.option
            let signInPromise = User.login(.promise, authData: authData, platformId: platform.platformIdForLeanCloud, options: option)
            
            firstly(execute: { () -> Promise<User> in
                // 如果当前存在匿名登录账户，则尝试将第三方账号关联到该账户
                if let user = User.current(), user.isAnonymous() {
                    return user.associate(.promise, authData: authData, platformId: platform.platformIdForLeanCloud, options: option)
                    .map({ _ in user })
                    .recover({ (error) -> Promise<User> in
                        guard (error as NSError?)?.code == 137 else { throw error }
                        
                        // 若该第三方账户被其他用户绑定，则执行登录操作
                        return signInPromise
                    })
                }
                
                // 否则，执行登录操作
                return signInPromise
            }).done({ (user) in
                self.continueSignIn(platform: platform, response: response, currentUser: user, hud: hud)
            }).catch({ (error) in
                hud.hideForInfo(String(format: "%@ 登录失败".localized(), platform.name))
            })
        }).catch({ (error) in
            MBProgressHUD.showForError(UIApplication.shared.keyWindow!, error: error)
        })
    }
    
    private func continueSignIn(platform: SocialPlatform, response: UMSocialUserInfoResponse, currentUser: User, hud: MBProgressHUD) {
        let finishSignInClosure = {
            self.finishSignIn(platform: platform, response: response, currentUser: currentUser, hud: hud)
        }
        
        // 头像
        guard let iconUrlString = response.iconurl, let iconUrl = URL(string: iconUrlString), currentUser.avatar == nil else {
            finishSignInClosure()
            return
        }
        
        SDWebImageDownloader.shared.downloadImage(with: iconUrl) { (_, data, error, _) in
            guard let data = data else {
                finishSignInClosure()
                return
            }
            
            let avatar = AVFile(data: data)
            
            avatar.upload(.promise).done { (avatar) in
                currentUser.avatar = avatar
                finishSignInClosure()
            }.catch { (error) in
                finishSignInClosure()
            }
        }
    }
    
    private func finishSignIn(platform: SocialPlatform, response: UMSocialUserInfoResponse, currentUser: User, hud: MBProgressHUD) {
        // 用户名
        if let name = response.name, currentUser.nickname == nil {
            currentUser.nickname = name
        }
        
        currentUser[keyPath: platform.didSetKeyPath] = true
        currentUser.saveInBackground()
        
        after(seconds: 0.5).then { (_) -> Guarantee<Void> in
            return hud.hideForSuccess(.promise, "登录成功".localized())
        }.done { (_) in
            NotificationCenter.default.post(name: .didSignIn, object: nil)
            self.dismiss(animated: true, completion: nil)
        }
    }
}
