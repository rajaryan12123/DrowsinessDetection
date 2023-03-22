//
//  LoginScreen.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import SwiftUI

struct LoginScreen: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color("BrandBlue")
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 320, height: 70, alignment: .center)
                        .foregroundColor(.white)
                        .overlay(
                            Text("Email")
                                .foregroundColor(Color.blue)
                                .font(.system(size: 20))
                        )
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 320, height: 70, alignment: .center)
                        .foregroundColor(.white)
                        .overlay(
                            Text("Password")
                                .foregroundColor(Color.blue)
                                .font(.system(size: 20))
                        )
                    
                    NavigationLink {
                        //go to camera view
                        
                        ViewControllerRepresentable()
                            .navigationBarBackButtonHidden(true)
                        
                    } label: {
                        Text("Login")
                            .padding()
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                    }
                    
                    Spacer()
                }.offset(y: 90)
            }
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}

struct ViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
}
