////
////  AlbumViewModel.swift
////  jellyfinMusic
////
////  Created by Esmond Missen on 4/11/20.
////
//
//import Foundation
//import Combine
//
//protocol AlbumViewModelProtocol {
//    var albums: [AlbumViewModel] { get }
//    var downloadsOnly: Bool { get set }
//    func fetchLatestAlbums()
////    func addTodo(title: String)
//    func toggleDownloaded(for album: AlbumViewModel)
//}
//
//final class AlbumListViewModel: ObservableObject {
//    @Published var albums = [AlbumViewModel]()
//    @Published var downloadsOnly = false {
//        didSet {
//            fetchLatestAlbums()
//        }
//    }
//    
//    var dataManager: DataManagerProtocol
//    
//    init(dataManager: DataManagerProtocol = DataManager.shared) {
//        self.dataManager = dataManager
//        fetchLatestAlbums()
//    }
//}
//
//// MARK: - TodoListViewModelProtocol
//extension AlbumListViewModel: AlbumViewModelProtocol {
//    func fetchLatestAlbums() {
//        albums = dataManager.fetchLatestAlbums(downloadsOnly: downloadsOnly)
//    }
//    
//    func toggleDownloaded(for album: AlbumViewModel) {
////        dataManager.toggleDownloaded(for: album)
//        fetchLatestAlbums()
//    }
//}
