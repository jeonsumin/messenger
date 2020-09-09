//
//  StorageManager.swift
//  Messenger
//
//  Created by Terry on 2020/08/30.
//  Copyright © 2020 Terry. All rights reserved.
//

import Foundation
import FirebaseStorage


final class StorageManager
{
    static let shard = StorageManager()
    
    private let storate = Storage.storage().reference()
    
    /*
     /images/afraz9-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
        
    //Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data,fileName: String, completion: @escaping UploadPictureCompletion) {
        storate.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                // faild
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storate.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Faild to get downlaod url")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                let urlString = url.absoluteString
                print("Downdload url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // Upload Image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data,fileName: String, completion: @escaping UploadPictureCompletion) {
        storate.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard error == nil else {
                // faild
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storate.child("message_images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else {
                    print("Faild to get downlaod url")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                let urlString = url.absoluteString
                print("Downdload url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    // Upload Video that will be sent in a conversation message
      public func uploadMessageVideo(with fileUrl: URL,fileName: String, completion: @escaping UploadPictureCompletion) {
        storate.child("message_video/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: {[weak self] metadata, error in
              guard error == nil else {
                  // faild
                  print("failed to upload video File  to firebase for picture")
                  completion(.failure(StorageErrors.failedToUpload))
                  return
              }
              
              self?.storate.child("message_video/\(fileName)").downloadURL(completion: {url, error in
                  guard let url = url else {
                      print("Faild to get downlaod url")
                      completion(.failure(StorageErrors.failedToUpload))
                      return
                  }
                  
                  let urlString = url.absoluteString
                  print("Downdload url returned: \(urlString)")
                  completion(.success(urlString))
              })
          })
      }
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String,completion: @escaping (Result<URL,Error>) -> Void ){
        let reference = storate.child(path)
        
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}

