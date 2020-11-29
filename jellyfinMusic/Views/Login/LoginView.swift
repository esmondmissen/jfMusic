//
//  LoginView.swift
//  jFin
//
//  Created by Esmond Missen on 27/7/20.
//

import SwiftUI

struct LoginView: View {
    
    // MARK: - Propertiers
    @State private var server = ""
    @State private var username = ""
    @State private var password = ""
    @State private var loggingIn = false
    @State private var librarySelect = false
    @State private var libraries: [JFView] = []
    @State private var selectedId: String = ""
    @Namespace private var animation
    
    // MARK: - View
    var body: some View {
        ScrollView{
          VStack() {
            LoginLogo()
            VStack(alignment: .center, spacing: 15) {
                if !librarySelect{
                    VStack{
                        Text("Enter Server Details")
                            .padding(.top, 15)
                            .foregroundColor(Color.white.opacity(0.8))
                        HStack{
                            Image(systemName: "globe")
                                .foregroundColor(.purple)
                                .padding()
                            TextField("Server", text: self.$server)
                                .multilineTextAlignment(.leading)
                                .keyboardType(UIKeyboardType.URL)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .background(Color.clear)
                                .foregroundColor(Color.white.opacity(loggingIn ? 0.4 : 0.8))
                                .padding()
                                .disabled(loggingIn)
                        }.border(width: 2, edge: .bottom, color: Color.purple.opacity(0.2))
                        HStack{
                            Image(systemName: "person")
                                .foregroundColor(.purple)
                                .padding()
                            TextField("Username", text: self.$username)
                                .multilineTextAlignment(.leading)
                                .keyboardType(UIKeyboardType.alphabet)
                                .background(Color.clear)
                                .foregroundColor(Color.white.opacity(loggingIn ? 0.4 : 0.8))
                                .padding()
                                .disabled(loggingIn)
                        }.border(width: 2, edge: .bottom, color: Color.purple.opacity(0.2))
                        HStack{
                            Image(systemName: "key")
                                .foregroundColor(.purple)
                                .padding()
                            SecureField("Password", text: self.$password)
                                .multilineTextAlignment(.leading)
                                .keyboardType(UIKeyboardType.default)
                                .background(Color.clear)
                                .foregroundColor(Color.white.opacity(loggingIn ? 0.4 : 0.8))
                                .padding()
                                .disabled(loggingIn)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red:0.148, green:0.082, blue:0.237), lineWidth: 2)
                                .matchedGeometryEffect(id: "border", in: animation)
                                .animation(.linear(duration: 0.2)))
                    Button(action: {
    //                        self.hideKeyboard()
                        loggingIn = true
                        NetworkingManager.shared.authenticate(server: server, username: username, password: password){ suc in
                            loggingIn = false
                            NetworkingManager.shared.getViews(){ items in
                                libraries = items.filter({ $0.collectionType == "music"})
                                
                                if libraries.count == 1 {
                                    selectedId = libraries.first!.id
                                    withAnimation(.linear(duration: 0.2)){
                                        librarySelect = true
                                    }
                                }else{
                                    
                                }
                            }
                        }
                            
                    }) {
                        Text(!loggingIn ? "Sign In" :  "Signing In" )
                        .font(.headline)
                            .foregroundColor(Color.white.opacity(loggingIn ? 0.4 : 0.8))
                        .padding()
                        .frame(width: nil, height: 50, alignment: .center)
                        .background(Color.purple.opacity(loggingIn ? 0.1 : 0.2))
                        .cornerRadius(15.0)
                            .animation(.linear(duration: 0.2))
                            .matchedGeometryEffect(id: "button", in: animation)
                    }.disabled(loggingIn)
                }else{
                    VStack{
                        Text("Select your music library")
                            .padding(.top, 15)
                        ForEach(libraries.filter({ $0.collectionType == "music"}), id: \.id){ lib in
                            Button(action: {
                                self.selectedId = lib.id
                                withAnimation(.linear(duration: 0.2)){
                                    librarySelect = false
                                }
                            }){
                                HStack{
                                    Image(systemName: self.selectedId == lib.id ? "checkmark.circle.fill" : "circle")
                                        .resizable().aspectRatio(contentMode: .fit)
                                        .foregroundColor(Color("Purple"))
                                        .frame(height: 30)
                                    Text(lib.name)
                                    Spacer()
                                }
                                .foregroundColor(Color.white.opacity(loggingIn ? 0.4 : 0.8))
                                .padding()
                                .background(Color.purple.opacity(loggingIn ? 0.1 : 0.2))
                                .cornerRadius(15.0)
                                .animation(.linear(duration: 0.2))
                            }.buttonStyle(ButtonScaleEffect(scale: 1.1))
                        }.padding(15)
                    }
                    .opacity(librarySelect ? 1 : 0)
                    .animation(.linear(duration: 0.2), value: librarySelect)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red:0.148, green:0.082, blue:0.237), lineWidth: 2)
                                .matchedGeometryEffect(id: "border", in: animation)
                                .animation(.linear(duration: 0.2)))
                    Button(action: {
                        NetworkingManager.shared.savePrimaryLibrary(libraryId: self.selectedId){ res in
                            print(NetworkingManager.shared.libraryId)
                        }
                    }) {
                        Text("Select" )
                        .font(.headline)
                            .foregroundColor(Color.white.opacity(0.8))
                        .padding()
                        .frame(width: nil, height: 50, alignment: .center)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(15.0)
                            .matchedGeometryEffect(id: "button", in: animation)
                            .animation(.linear(duration: 0.2))
                    }
                    
                    
                }
            }.padding(20)
          }
          .edgesIgnoringSafeArea(.all)
          
        }.background(LinearGradient(gradient: Gradient(colors: [Color(red: 0/255, green: 11/255, blue: 37/255, opacity: 1), .black]), startPoint: .top, endPoint: .bottom).edgesIgnoringSafeArea(.all))
    }
}

struct LoginLogo : View{
    @State private var animate = false
    var body: some View{
        Image("Placeholder")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 150)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
