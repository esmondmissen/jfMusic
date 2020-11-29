//
//  Account.swift
//  jellyfinMusic
//
//  Created by Esmond Missen on 27/10/20.
//

import SwiftUI

struct Account: View {
    @State private var username: String = ""
    @State private var qualityIndex: Int = [128, 196, 256, 320].firstIndex(of: UserDefaults.standard.double(forKey: "Quality")) ?? 2 {
        didSet{
            NetworkingManager.shared.quality = Double(qualityOptions[qualityIndex] * 1024)
        }
    }
    var qualityOptions: [Double] = [128, 196, 256, 320]{
        didSet{
            print("Hello")
        }
    }
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("STREAMING")){
                    Picker(selection: $qualityIndex, label: Text("Streaming Quality")) {
                            ForEach(0 ..< qualityOptions.count) {
                                Text("\(Int(qualityOptions[$0]))kbps")
                            }
                        }
                }
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.0.1")
                    }
                    Section {
                        Button(action: {
                            NetworkingManager.shared.signOut()
                        }) {
                            Text("Sign Out")
                        }
                    }
                }
            }.navigationBarTitle("Account")
        }
    }
}


struct Account_Previews: PreviewProvider {
    static var previews: some View {
        Account()
    }
}
