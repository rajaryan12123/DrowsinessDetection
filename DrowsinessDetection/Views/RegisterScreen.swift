//
//  RegisterView.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import SwiftUI

struct RegisterScreen: View {
    
    @State var email_text: String = ""
    @State var password_text: String = ""
    
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
                            TextField("Email", text: $email_text)
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
                            SecureField("New Password", text: $password_text)
                                .foregroundColor(Color.gray)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .textInputAutocapitalization(.never)
                        )
                    
                    Button {
                        //register user
                    } label: {
                        Text("Register")
                            .padding()
                            .foregroundColor(Color("BrandBlue"))
                            .font(.system(size: 25))
                    }
                    Spacer()
                }.offset(y: 90)
            }
        }
    }
}

struct RegisterScreen_Previews: PreviewProvider {
    static var previews: some View {
        RegisterScreen()
    }
}
