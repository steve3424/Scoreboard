//
//  CongratulationsView.swift
//  Scoreboard
//
//  Created by user179118 on 9/1/20.
//  Copyright © 2020 user926153. All rights reserved.
//

import SwiftUI

struct CongratulationsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var root_view: Bool
    
    let winners: [String]
    @State var save_failed: Bool
    
    var body: some View {
        VStack(alignment: .center) {
            // NAV BAR
            HStack {
                Button(action: {
                    self.root_view = false
                }) {
                    HStack {
                        Text("home")
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Spacer()
            
            Text("CONGRATS!!")
                .font(.title)
            ForEach((0...self.winners.count - 1), id: \.self) {
                player_index in
                Text(self.winners[player_index])
            }
            
            Spacer()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .alert(isPresented: $save_failed) {
            Alert(title: Text("Save Game Failed!"), message: Text("Something went wrong and this game did not save. Sorry."), dismissButton: .default(Text("OK")))
        }
    }
}

struct CongratulationsView_Previews: PreviewProvider {
    static var previews: some View {
        CongratulationsView(root_view: .constant(true), winners: [], save_failed: false)
    }
}
