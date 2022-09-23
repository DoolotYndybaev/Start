//
//  ViewController.swift
//  Start
//
//  Created by Doolot on 23/9/22.
//

import UIKit
import MapKit
import CoreLocation
import MobileCoreServices
import AVKit
import AVFoundation

class ViewController: UIViewController, UINavigationControllerDelegate {
    //  Record
    var fileName = "audioFile.m4a"
    
    var soundRecorder: AVAudioRecorder!
    var recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    // Video
    var videoAndImageReview = UIImagePickerController()
    var videoURL: URL?
    
    
    // Location
    let locationManager = CLLocationManager()
    
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationAuthorization()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission { state in
                DispatchQueue.main.async {
                    if state {
                        print("self?.recordBTN.isHidden = false")
                    } else {
                        print("self?.recordBTN.isHidden = true")
                    }
                }
            }
            
        } catch let err {
            print("Error with recording session \(err.localizedDescription)")
        }
        initAudioRecord()
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showAllert(title: "Location Servicec are Disabled ", message: "To enable it go: Settings -> Privacy -> Location services and turn ON")
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func checkLocationAuthorization() {
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.showAllert(title: "Your Location is not Availeble",
                                message: "To give permission go to : Setting -> Map -> Location ")
            }
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New Case is available")
        }
        
    }
    
    private func showAllert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // MARK: StartButton
    @IBAction func startButton(_ sender: Any) {
        // Current Location
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
            
            // Start Video
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.sourceType = .camera
                    imagePicker.mediaTypes = [kUTTypeMovie as String]
                    imagePicker.allowsEditing = false
                    imagePicker.delegate = self
                    
                    present(imagePicker, animated: true)
                    
                } else {
                    self.showAllert(title: "Camera is inaccessible", message: "Application cannot access the camera")
                }
            }
            
        }
    }
    // MARK: Open Video
    @IBAction func openVideo(_ sender: Any) {
        videoAndImageReview.sourceType = .savedPhotosAlbum
        videoAndImageReview.delegate = self
        videoAndImageReview.mediaTypes = ["public.movie"]
        present(videoAndImageReview, animated: true, completion: nil)
    }
    
    func videoAndImageReview(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        videoURL = info[UIImagePickerController.InfoKey.mediaURL.rawValue] as? URL
        print("videoURL:\(String(describing: videoURL))")
        self.dismiss(animated: true, completion: nil)
    }
    
    private func finishRecord() {
        soundRecorder.stop()
        
    }
    
    private func initAudioRecord() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(fileName)
        let recordSetting = [ AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                   AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue,
                      AVNumberOfChannelsKey : 1,
                            AVSampleRateKey : 12000] as [String : Any]
        
        do {
            soundRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSetting )
            soundRecorder.delegate = self
            
            
            
        } catch {
            print(error)
            
        }
    }
}


// MARK: Map

extension  ViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

// MARK: Video
extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        dismiss(animated: true)
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
              mediaType == (kUTTypeMovie as String),
              let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL,
              UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
        else { return }
        UISaveVideoAtPathToSavedPhotosAlbum(url.path,
                                            self,
                                            #selector(video(_:didFinishSavingWithError:contextInfo:)),
                                            nil)
    }
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

extension ViewController:  AVAudioPlayerDelegate, AVAudioRecorderDelegate  {
    
    func setupRecorder() {
        let recordSettings = [ AVFormatIDKey : kAudioFormatAppleLossless,
                    AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
                         AVEncoderBitRateKey : 320000,
                       AVNumberOfChannelsKey : 2,
                             AVSampleRateKey : 44100.2] as [String : Any]
        
        soundRecorder = try! AVAudioRecorder(url: getFileURL() as URL, settings: recordSettings)
        
        soundRecorder.delegate = self
        soundRecorder.prepareToRecord()
        
        
    }
    func getPathDirectory() -> String{
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        return path[0]
    }
    func getFileURL() -> NSURL {
        let path = getPathDirectory().appending(fileName)
        
        let filePath = NSURL(fileURLWithPath: path)
        
        return filePath
    }
    
    @IBAction func recordTapped(_ sender: UIButton) {
        
        if !soundRecorder.isRecording {
            
            soundRecorder.record()
            
        } else {
            
            finishRecord()
            sender.setTitle("Record", for: .normal)
        }
    }
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    }
    
}
