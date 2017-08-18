//
//  ViewController.swift
//  Aplestory
//
//  Created by woopadesign02 on 27/04/17.
//  Copyright © 2017 Crosswalk. All rights reserved.
//

import UIKit
import WebKit
import MBProgressHUD
import AVFoundation

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, MBProgressHUDDelegate {
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    var webView : WKWebView?

    var loadingDone: Bool? = false

    @IBOutlet weak var customLogoView: UIImageView!
    
    
    @IBOutlet weak var backgroundView: UIView!
    
    
    var popViewController:UIViewController?
    var load : MBProgressHUD = MBProgressHUD()
    var toolbar:UIToolbar?
    var backButton: UIBarButtonItem?
    var forwardButton: UIBarButtonItem?
    var reloadButton: UIBarButtonItem?
    
    var mainURL:URL?
    var urlString:String?
    
    var lastOffsetY :CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlString = "http://dev.wdesign.co.nz/apleapp"

        customLogoView = self.customLogo()
        self.loadToolbar()
        self.loadWebView()
        
    }
    
    func playerDidReachEnd(){
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    func showLoader() {
        if backgroundView == nil {
            self.load = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.load.mode = MBProgressHUDMode.customView
            self.load.customView = self.customImageView()
            self.load.bezelView.color = UIColor.clear
            self.load.bezelView.style = .solidColor

        }
    }
    
    func loadToolbar() {
        self.toolbar = self.getToolbar()
        self.toolbar?.isHidden = true
        self.backButton?.isEnabled = false
        self.forwardButton?.isEnabled = false
    }
    
    func back() {
        _ = self.webView?.goBack()
    }
    
    func forward() {
        _ = self.webView?.goForward()
    }
    
    func reload() {
        if var urlForWebView = self.webView?.url {
            if urlForWebView.absoluteString.contains("NoInternet.html") {
                if !(urlString?.isEmpty)! {
                    urlForWebView = URL(string: urlString!)!
                }
            }
            self.showLoader()
            let request = URLRequest(url: urlForWebView)
            _ = self.webView?.load(request)
        }
    }
    
    func loadWebView() {
        self.getURL()
        self.loadWebSite()
    }
    
    func getURL() {
        
        if !(urlString?.isEmpty)! {
            if self.mainURL == nil {
                self.mainURL = URL(string: urlString!)
            }
        }
    }
    
    func loadWebSite() {
        let theConfiguration:WKWebViewConfiguration? = WKWebViewConfiguration()
        let thisPref:WKPreferences = WKPreferences()
        thisPref.javaScriptCanOpenWindowsAutomatically = true;
        thisPref.javaScriptEnabled = true
        theConfiguration!.preferences = thisPref;
        
        self.webView = WKWebView(frame: view.frame, configuration: theConfiguration!)
        self.webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView?.scrollView.bounces = false
        if self.mainURL != nil {
            let requestObj = URLRequest(url: self.mainURL!)
            _ = self.webView?.load(requestObj)
        } else {
            
             var fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "www/index", ofType: "html")!)
             if #available(iOS 9.0, *) {
             _ = self.webView?.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
             } else {
             do {
             fileURL = try fileURLForBuggyWKWebView8(fileURL: fileURL)
             _ = self.webView?.load(URLRequest(url: fileURL))
             } catch let error as NSError {
             print("Error: " + error.debugDescription)
             }
             }
        }
        
        self.webView?.scrollView.delegate = self
        self.webView?.navigationDelegate = self
        self.webView?.uiDelegate = self
        self.webView?.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    func fileURLForBuggyWKWebView8(fileURL: URL) throws -> URL {
        // Some safety checks
        if !fileURL.isFileURL {
            throw NSError(
                domain: "BuggyWKWebViewDomain",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("URL must be a file URL.", comment:"")])
        }
        _ = try! fileURL.checkResourceIsReachable()
        
        // Create "/temp/www" directory
        let fm = FileManager.default
        let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("www")
        try! fm.createDirectory(at: tmpDirURL, withIntermediateDirectories: true, attributes: nil)
        
        // Now copy given file to the temp directory
        let dstURL = tmpDirURL.appendingPathComponent(fileURL.lastPathComponent)
        let _ = try? fm.removeItem(at: dstURL)
        try! fm.copyItem(at: fileURL, to: dstURL)
        
        // Files in "/temp/www" load flawlesly :)
        return dstURL
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let bounds = UIScreen.main.bounds
        if(velocity.y>0) {
            //Code will work without the animation block.I am using animation block incase if you want to set any delay to it.
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: {

                self.toolbar?.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: 40)
                
                print("Hide")
            }, completion: nil)
            
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions(), animations: {

                self.toolbar?.isHidden = false
                
                self.toolbar?.frame = CGRect(x: 0, y: bounds.height - 40, width: bounds.width, height: 40)
                
                print("Unhide")
            }, completion: nil)    
        }
    }

    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "loading") {
            //self.progressBar.layer.zPosition = 1
            self.backButton?.isEnabled = self.webView!.canGoBack
            self.forwardButton?.isEnabled = self.webView!.canGoForward
        } else if (keyPath == "estimatedProgress") {
            let estimatedProgress = Float(self.webView!.estimatedProgress)
            if estimatedProgress > 1 {
                self.didFinish()
                
            } else {
                //self.progressBar.progress = estimatedProgress
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.toolbar?.isHidden = true
        self.didFinish()
    }
    
    func didFinish() {
        
        self.webView?.frame = self.view.frame
        
        self.backgroundView?.removeFromSuperview()
        self.backgroundView = nil
        
        UIView.transition(with: self.view, duration: 0.1, options: .transitionCrossDissolve, animations: {
            
            
            if !(self.urlString?.isEmpty)! {
                if self.mainURL != URL(string: self.urlString!) {
                    self.mainURL = URL(string: self.urlString!)
                }
            }
            
            
            UserDefaults.standard.removeObject(forKey: "URL")
            
            if self.popViewController == nil {
                if self.webView != nil {
                    self.view.addSubview(self.webView!)
                    //self.progressBar.layer.zPosition = 1
                }
                if self.toolbar != nil {
                    self.view.addSubview(self.toolbar!)
                }
            }
            
        }) { (success) in
            self.load.hide(animated: true)
            print("loading finished")
            //self.progressBar.layer.zPosition = 0
        }
    }
    
    
    func getDomainFromURL(_ url:URL?) -> String {
        var domain:String = ""
        let domains = self.domains()
        if url?.host != nil {
            let host = url!.host?.lowercased()
            var separatedHost = host?.components(separatedBy: ".")
            separatedHost = separatedHost?.reversed()
            
            for tld in separatedHost! {
                if domains.contains(tld.uppercased()) {
                    domain = ".\(tld)\(domain)"
                } else {
                    domain = "\(tld)\(domain)"
                    break
                }
            }
        }
        return domain
    }
    
    
    func getViewController(_ configuration:WKWebViewConfiguration) -> UIViewController {
        let webView2:WKWebView = WKWebView(frame: self.view.frame, configuration: configuration)
        webView2.frame = UIScreen.main.bounds
        webView2.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        webView2.navigationDelegate = self
        webView2.uiDelegate = self
        
        let newViewController = UIViewController()
        newViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ViewController.dismissViewController))
        newViewController.modalPresentationStyle = .overCurrentContext
        newViewController.view = webView2
        return newViewController
    }
    
    func dismissPopViewController(_ domain:String) {
        if self.mainURL != nil {
            let mainDomain = self.getDomainFromURL(self.mainURL!)
            if domain == mainDomain{
                if self.popViewController != nil {
                    self.dismissViewController()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        self.popViewController = self.getViewController(configuration)
        let navController = UINavigationController(rootViewController: self.popViewController!)
        self.present(navController, animated: true, completion: nil)
        return self.popViewController?.view as? WKWebView
    }
    
    func dismissViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController:WKUserContentController, message:WKScriptMessage) {
        print(message)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message)
    }
    
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.showLoader()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
     // insert javascript
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        var fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "NoInternet", ofType: "html")!)
        if #available(iOS 9.0, *) {
            _ = self.webView?.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        } else {
            do {
                fileURL = try fileURLForBuggyWKWebView8(fileURL: fileURL)
                _ = self.webView?.load(URLRequest(url: fileURL))
            } catch let error as NSError {
                print("Error: " + error.debugDescription)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        let domain = self.getDomainFromURL(webView.url)
        self.dismissPopViewController(domain)
    }
    
    func getToolbar() -> UIToolbar? {
        var toolbar: UIToolbar?
        
        self.backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(ViewController.back))
        self.forwardButton = UIBarButtonItem(image: UIImage(named: "forward"), style: .plain, target: self, action: #selector(ViewController.forward))
        self.reloadButton = UIBarButtonItem(image: UIImage(named: "refresh"), style: .plain, target: self, action: #selector(ViewController.reload))
        
        self.backButton?.tintColor = UIColor.black
        self.forwardButton?.tintColor = UIColor.black
        self.reloadButton?.tintColor = UIColor.black
        
        let fixedSpaceButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        fixedSpaceButton.width = 42
        let flexibleSpaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        var items = [UIBarButtonItem]()
        items.append(self.backButton!)
        items.append(fixedSpaceButton)
        items.append(self.forwardButton!)
        

        items.append(flexibleSpaceButton)
        items.append(self.reloadButton!)
        
        let bounds = UIScreen.main.bounds
        toolbar = UIToolbar(frame: CGRect(x: 0, y: bounds.height - 40, width: bounds.width, height: 40))
        toolbar!.setItems(items, animated: true)
        return toolbar
    }
    
    

    
    /**
     open custom app with urlScheme : telprompt, sms, mailto
     
     - parameter urlScheme: telpromt, sms, mailto
     - parameter additional_info: additional info related to urlScheme
     */
    func openCustomApp(urlScheme:String, additional_info:String){
        let url = "\(urlScheme)"+"\(additional_info)"
        if let requestUrl:NSURL = NSURL(string:url) {
            let application:UIApplication = UIApplication.shared
            if application.canOpenURL(requestUrl as URL) {
                application.openURL(requestUrl as URL)
            }
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow);
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.load.hide(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("NAVIGATION URL: \(navigationAction.request.url!.host)")
        
        let url = navigationAction.request.url?.absoluteString
        
        let hostAddress = navigationAction.request.url?.host
        
        // To connnect app store
        if hostAddress == "itunes.apple.com" {
            if UIApplication.shared.canOpenURL(navigationAction.request.url!) {
                UIApplication.shared.openURL(navigationAction.request.url!)
                decisionHandler(.cancel)
                return
            }
        }
        
        
        #if DEBUG
            print("url = \(url), host = \(hostAddress)")
        #endif
        
        let url_elements = url!.components(separatedBy: ":")
        
        switch url_elements[0] {
        case "tel":
            #if DEBUG
                print("this is phone number")
            #endif
            openCustomApp(urlScheme: "telprompt://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "sms":
            #if DEBUG
                print("this is sms")
            #endif
            openCustomApp(urlScheme: "sms://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "mailto":
            #if DEBUG
                print("this is mail")
            #endif
            openCustomApp(urlScheme: "mailto://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "comgooglemaps":
            #if DEBUG
                print("this is sms")
            #endif
            openCustomApp(urlScheme: "comgooglemaps://", additional_info: url_elements[1])
            decisionHandler(.cancel)
        default:
            #if DEBUG
                print("normal http request")
            #endif
        }
        
        let domain = self.getDomainFromURL(navigationAction.request.url!)
        
        if (navigationAction.navigationType == WKNavigationType.linkActivated) {
            print("domains: \(domain)")
            print("navigationType: LinkActivated")
            
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.allow)
        } else if (navigationAction.navigationType == WKNavigationType.backForward) {
            print("navigationType: BackForward")
            decisionHandler(WKNavigationActionPolicy.allow)
        } else if (navigationAction.navigationType == WKNavigationType.formResubmitted) {
            print("navigationType: FormResubmitted")
            decisionHandler(WKNavigationActionPolicy.allow)
        } else if (navigationAction.navigationType == WKNavigationType.formSubmitted) {
            print("navigationType: FormSubmitted")
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.allow)
        } else if (navigationAction.navigationType == WKNavigationType.reload) {
            print("navigationType: Reload")
            decisionHandler(WKNavigationActionPolicy.allow)
        } else {
            self.dismissPopViewController(domain)
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }

    
    func domains() -> NSArray {
        if let url = Bundle.main.url(forResource: "domains", withExtension: "json") {
            if let data = try? Data(contentsOf: url) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    if let domains = json as? [String] {
                        return domains as NSArray
                    }
                } catch {
                    print("error serializing JSON: \(error)")
                }
            }
            print("Error!! Unable to load domains.json.json")
        }
        return []
    }
    
    func customImageView() -> UIImageView {
        
        let imageView = UIImageView(image: UIImage(named: "image.png"))

        if (UIDevice.current.userInterfaceIdiom == .pad) {
            imageView.animationImages = [UIImage(named: "pl1.png")!, UIImage(named: "pl2.png")!, UIImage(named: "pl3.png")!, UIImage(named: "pl4.png")!, UIImage(named: "pl5.png")!, UIImage(named: "pl6.png")!, UIImage(named: "pl7.png")!, UIImage(named: "pl8.png")!, UIImage(named: "pl9.png")!, UIImage(named: "pl10.png")!, UIImage(named: "pl11.png")!, UIImage(named: "pl12.png")!, UIImage(named: "pl13.png")!]
            imageView.animationDuration = 1.5
            
        } else {
            imageView.animationImages = [UIImage(named: "pl1x50.png")!, UIImage(named: "pl2x50.png")!, UIImage(named: "pl3x50.png")!, UIImage(named: "pl4x50.png")!, UIImage(named: "pl5x50.png")!, UIImage(named: "pl6x50.png")!, UIImage(named: "pl7x50.png")!, UIImage(named: "pl8x50.png")!, UIImage(named: "pl9x50.png")!, UIImage(named: "pl10x50.png")!, UIImage(named: "pl11x50.png")!, UIImage(named: "pl12x50.png")!, UIImage(named: "pl13x50.png")!]
            imageView.animationDuration = 1
        }
        imageView.startAnimating()

        return imageView
        
    }
    
    func customLogo() -> UIImageView {
        
        
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            
            customLogoView.animationImages = [UIImage(named: "1.png")!, UIImage(named: "2.png")!, UIImage(named: "3.png")!, UIImage(named: "4.png")!, UIImage(named: "5.png")!, UIImage(named: "6.png")!, UIImage(named: "7.png")!, UIImage(named: "8.png")!, UIImage(named: "9.png")!, UIImage(named: "10.png")!, UIImage(named: "11.png")!, UIImage(named: "12.png")!, UIImage(named: "13.png")!, UIImage(named: "14.png")!, UIImage(named: "15.png")!, UIImage(named: "16.png")!, UIImage(named: "17.png")!, UIImage(named: "18.png")!, UIImage(named: "19.png")!, UIImage(named: "20.png")!, UIImage(named: "21.png")!]
        } else {
            customLogoView.animationImages = [UIImage(named: "loading-phone1.png")!, UIImage(named: "loading-phone2.png")!, UIImage(named: "loading-phone3.png")!, UIImage(named: "loading-phone4.png")!, UIImage(named: "loading-phone5.png")!, UIImage(named: "loading-phone6.png")!, UIImage(named: "loading-phone7.png")!, UIImage(named: "loading-phone8.png")!, UIImage(named: "loading-phone9.png")!, UIImage(named: "loading-phone10.png")!, UIImage(named: "loading-phone11.png")!, UIImage(named: "loading-phone12.png")!, UIImage(named: "loading-phone13.png")!, UIImage(named: "loading-phone14.png")!, UIImage(named: "loading-phone15.png")!, UIImage(named: "loading-phone16.png")!, UIImage(named: "loading-phone17.png")!, UIImage(named: "loading-phone18.png")!, UIImage(named: "loading-phone19.png")!, UIImage(named: "loading-phone20.png")!, UIImage(named: "loading-phone21.png")!]
        }
        
        customLogoView.animationDuration = 2
        customLogoView.startAnimating()

        return customLogoView
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        UIView.transition(with: self.view, duration: 0.1, options: .transitionCrossDissolve, animations: {
            let bounds = UIScreen.main.bounds
            self.toolbar?.frame = CGRect(x: 0, y: bounds.height - 40, width: bounds.width, height: 40)
            
            var y:CGFloat = bounds.height - 50
            if self.toolbar != nil {
                y = y - self.toolbar!.frame.height
            }
            
        }) { (success) in
            
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
