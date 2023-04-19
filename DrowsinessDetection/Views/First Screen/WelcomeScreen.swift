//
//  WelcomeScreen.swift
//  DrowsinessDetection
//
//  Created by Raj Aryan on 22/03/23.
//

import SwiftUI
import UIKit

struct WelcomeScreen: View {
    
    
    var body: some View {
        
        NavigationView {
            VStack {
                Spacer()
                Text("Drowsiness Detection iOS Application")
                    .foregroundColor(.blue)
                    .bold()
                    .font(.system(size: 32))
                    .multilineTextAlignment(.center)
                Spacer()
                
                NavigationLink {
                    RegisterScreen()
                } label: {
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width, height: 70)
                        .foregroundColor(Color("BrandLightBlue"))
                        .overlay(
                            Text("Register")
                                .foregroundColor(Color("BrandBlue"))
                                .font(.system(size: 30))
                        )
                }
                
                NavigationLink {
                    LoginScreen()
                } label: {
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width, height: 70)
                        .foregroundColor(Color("BrandBlue"))
                        .overlay(
                            Text("Login")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                             )
                }
                
               
            }.padding()
        }
    }

}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}


struct ViewControllerPresentable: UIViewControllerRepresentable {
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        
        return vc
    }
}
