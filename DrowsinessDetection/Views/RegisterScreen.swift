//
//  RegisterView.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import SwiftUI
import Firebase


struct AlertIdentifier: Identifiable {
    enum Choice {
        case first, second
    }

    var id: Choice
}

struct RegisterScreen: View {
    
    @State var email_text: String = ""
    @State var password_text: String = ""
    @State var password_message: String = "New Password"
    @State var email_message: String = "Email"
    @State private var alertIdentifier: AlertIdentifier?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BrandLightPurple")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 320, height: 70, alignment: .center)
                        .foregroundColor(Color("BrandBlue").opacity(0.3))
                        .shadow(color: .gray, radius: 20)
                        .opacity(0.6)
                        .overlay(
                            TextField(email_message, text: $email_text)
                                .foregroundColor(Color.gray)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.never)
                        )
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 320, height: 70, alignment: .center)
                        .foregroundColor(Color("BrandBlue").opacity(0.3))
                        .opacity(0.6)
                        .shadow(color: .gray, radius: 20)
                        .overlay(
                            SecureField(password_message, text: $password_text)
                                .foregroundColor(Color.gray)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.never)
                        )
                    
                    Button {
                        //register user
                        if password_text.count < 8 {
                            password_text = ""
                            password_message = "Minimum 8 digits"
                        } else {
                            let cur_email = email_text
                            let cur_password = password_text
                            Auth.auth().createUser(withEmail: cur_email, password: cur_password) { authResult, error in
                                if let e = error {
                                    email_text = ""
                                    email_message = "Email"
                                    password_text = ""
                                    password_message = "New Password"
                                    self.alertIdentifier = AlertIdentifier(id: .first)
                                    print("alert should be visible 1")
                                    print(e)
                                } else {
                                    //user registered successfully
                                    email_text = ""
                                    password_text = ""
                                    email_message = "Email"
                                    password_message = "New Password"
                                    self.alertIdentifier = AlertIdentifier(id: .second)
                                    print("user registered")
                                }
                            }
                        }
                        
                        
                    } label: {
                        Text("Register")
                            .padding()
                            .foregroundColor(Color("BrandBlue"))
                            .font(.system(size: 25))
                    }
                    Spacer()
                }.offset(y: 90)
                    .alert(item: $alertIdentifier) { alert in
                                switch alert.id {
                                case .first:
                                    return Alert(title: Text("Some Error occured"),
                                                 message: Text("Try entering email and password again"), dismissButton: .default(Text("ok")))
                                case .second:
                                    return Alert(title: Text("Registration Successful"),
                                                 message: Text(""), dismissButton: .default(Text("ok")))
                            }
                    }
            }
        }
    }
}

struct RegisterScreen_Previews: PreviewProvider {
    static var previews: some View {
        RegisterScreen()
    }
}
