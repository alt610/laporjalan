//
//  LaporAdminViewController.swift
//  Lapor Jalan
//
//  Created by Alfin Taufiqurrahman on 02/01/19.
//  Copyright © 2019 Alfin Taufiqurrahman. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation
import GooglePlaces
import GoogleMaps
import Firebase
import FirebaseFirestore

class LaporAdminViewController: UIViewController, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    var lokasi = String()
    var lat = Double()
    var long = Double()
    var thoroughfare = String()
    let dataLogin = LoginViewController()
    var email:String = (Auth.auth().currentUser?.email)!
    var tanggal = String()
    var deskripsi = String()
    var status = "Belum Ditinjau"
    var image = UIImage()
    
    private var presenter: UploadPresenterAdmin!
    
    @IBOutlet weak var lokasiSayaTextField: UITextField!
    @IBOutlet weak var imagePicked: UIImageView!
    @IBOutlet weak var deskripsiTextField: UITextField!
    @IBOutlet weak var kirimButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(LaporAdminViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LaporAdminViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        presenter = UploadPresenterAdmin(viewController: self)
        
        setKirimButton(enabled: false)
        
        lokasiSayaTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        deskripsiTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        
        kameraTap()
        lokasiTap()
        buatToolbar()
        keyboardEvents()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    //coba kamera tap
    func kameraTap(){
        
        let tapKamera = UITapGestureRecognizer(target: self, action: #selector(self.openTheCamera))
        imagePicked.isUserInteractionEnabled = true
        imagePicked.addGestureRecognizer(tapKamera)
    }
    
    //kamera
    @objc func openTheCamera(sender: UITapGestureRecognizer){
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imagePicked.image = image
        self.image = image!
        dismiss(animated:true, completion: nil)
    }
    
    //lokasi tap
    func lokasiTap(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapLokasi))
        lokasiSayaTextField.isUserInteractionEnabled = true
        lokasiSayaTextField.addGestureRecognizer(tap)
    }
    @objc func tapLokasi(sender: UITapGestureRecognizer){
        performSegue(withIdentifier: "openMap", sender: nil)
    }
    
    //kirim data dari map
    @IBAction func unwindFromMapView(_ sender: UIStoryboardSegue){
        lokasiSayaTextField.text = "Lokasi Saya"
        if lokasi != "" {
            lokasiSayaTextField.text = lokasi
        }
    }
    
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        if segue.identifier == "openMap"{
    //            let mapViewController = segue.destination as! MapViewController
    //            mapViewController.title = "Lokasi"
    //        }
    //    }
    
    //timestamp
    func timestamp() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: now)
        tanggal = dateString
    }
    

    func buatToolbar() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil)
        
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.items = [flexible, doneButton]
        toolBar.isUserInteractionEnabled = true

        deskripsiTextField.inputAccessoryView = toolBar
    }
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
    @objc func keyboardWillChange(notification: Notification){
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else{
            return
        }
        
        if notification.name == Notification.Name.UIKeyboardWillShow || notification.name == Notification.Name.UIKeyboardWillChangeFrame {
            view.frame.origin.y = -keyboardRect.height
        }
    }
    func keyboardEvents(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    @IBAction func kirimButton(_ sender: Any) {
        //TODO: post to firebase
        
        kirimSemua()
    }
    
    func kirimSemua(){
        let alert = UIAlertController(title: "Konfirmasi", message: "Kirim laporan ini?", preferredStyle: UIAlertControllerStyle.alert)
        let clearAction = UIAlertAction(title: "Kirim", style: UIAlertActionStyle.destructive) { (alert: UIAlertAction!) -> Void in
            
            self.timestamp()
            self.present(self.alertView, animated: true, completion: nil)
            guard let image = self.imagePicked.image, let deskripsi = self.deskripsiTextField.text else {
                print("Data tidak lengkap")
                return
            }
            //            print(self.email)
            //            print(image)
            //        print(tanggal)
            //        print(lokasi)
            //        print(lat)
            //        print(long)
            //        print(thoroughfare)
            //        print(deskripsi)
            //        print(ukuranTerpilih!)
            //        print(status)
            self.presenter.uploadLaporan(withImage: image, email: self.email, tanggal: self.tanggal, lokasi: self.lokasi, lat: self.lat, long: self.long, thoroughfare: self.thoroughfare, deskripsi: deskripsi, completionBlock: { [unowned self] (errorMessage) in
                print("kirim laporan sukses")
                self.self.dismissAlertUpload()
            })
            
            //bataskomenuji
        }
        let cancelAction = UIAlertAction(title: "Batal", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) -> Void in
        }
        
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion:nil)
        
    }
    
    @objc func textFieldChanged(_ target:UITextField) {
        let cekLokasi = lokasiSayaTextField.text
        let cekDeskripsi = deskripsiTextField.text
        let formFilled = cekLokasi != nil && cekLokasi != "" && cekDeskripsi != nil && cekDeskripsi != ""
        setKirimButton(enabled: formFilled)
    }
    
    func setKirimButton(enabled: Bool){
        if enabled{
            kirimButton.alpha = 1.0
            kirimButton.isEnabled = true
        }else{
            kirimButton.alpha = 0.5
            kirimButton.isEnabled = false
        }
    }
    
    let alertView = UIAlertController(title: "Mengirim...", message: "", preferredStyle: .alert)
    
    func alertSukses(){
        let alert = UIAlertController(title: "Sukses", message: "Laporan anda telah terkirim!", preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) -> Void in
            
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissAlertUpload() {
        imagePicked.image  = UIImage(named: "cameraico")
        lokasiSayaTextField.text = ""
        deskripsiTextField.text = ""
        self.alertView.dismiss(animated: true, completion: nil)
        self.alertSukses()
    }
    
    func handleError(_ error: String) {
        let alertViewController = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertViewController, animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    @IBAction func logoutButton(_ sender: Any) {
        
        logOut()
    }
    
    func logOut(){
        let users = Users()
        
        users.logOut(completionBlock: { [unowned self] (errorMessage) in
            self.performSegue(withIdentifier: "goToBegin", sender: self)
            self.dismiss(animated: false, completion: nil)
        } )
        
    }
    
}
