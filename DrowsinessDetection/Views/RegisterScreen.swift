//
//  RegisterView.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import SwiftUI

struct RegisterScreen: View {
    var body: some View {
        ZStack {
            Color(.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 320, height: 70, alignment: .center)
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 20)
                    .opacity(0.6)
                    .overlay(
                        Text("Email")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 20))
                    )
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 320, height: 70, alignment: .center)
                    .foregroundColor(.white)
                    .opacity(0.6)
                    .shadow(color: .gray, radius: 20)
                    .overlay(
                        Text("New Password")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 20))
                    )
                
                Button {
                    //register user
                } label: {
                    Text("Register")
                        .padding()
                        .foregroundColor(.blue)
                        .font(.system(size: 25))
                }
                Spacer()
            }.offset(y: 90)
        }
    }
}

struct RegisterScreen_Previews: PreviewProvider {
    static var previews: some View {
        RegisterScreen()
    }
}
