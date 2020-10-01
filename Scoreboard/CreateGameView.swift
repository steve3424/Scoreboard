//
//  CreateGameView.swift
//  Scoreboard
//
//  Created by user179118 on 9/1/20.
//  Copyright © 2020 user926153. All rights reserved.
//

import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct CreateGameView: View {
    // core data
    @Environment(\.managedObjectContext) var managed_object_context
    
    // navigation
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var root_view: Bool
    
    
    let max_players = 25
    @ObservedObject var game_state: GameStateActive
    @State var player_message: String = ""
    @State var player_message_color: Color = Color.red
    @State var error_message: Bool = true
    
    @State var player_error: String = ""
    @State var player_add_success: String = ""
    @State var game_name_error: String = ""
    @State var ready_to_start: Bool = false
    
    init(game_to_load: GameStateSaved? = nil, root_view: Binding<Bool>) {
        self._root_view = root_view
        self.game_state = GameStateActive(loaded_game: game_to_load)
    }
    
    private func DeletePlayer(at offsets: IndexSet) {
        self.player_message = "* \(self.game_state.players[offsets.first!]) was deleted"
        self.player_message_color = Color.red
        
        self.game_state.players.remove(atOffsets: offsets)
        self.game_state.totals.remove(atOffsets: offsets)
        self.game_state.phases.remove(atOffsets: offsets)
        for round_index in (0...self.game_state.scores.count - 1) {
            self.game_state.scores[round_index].remove(atOffsets: offsets)
        }
    }
    
    
    private func AddPlayer() {
        
        self.game_state.current_player = self.game_state.current_player.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if self.game_state.current_player.count == 0 {
            self.player_message = "* player name invalid"
            self.player_message_color = Color.red
        }
        else if self.game_state.players.contains(self.game_state.current_player) {
            self.player_message = "* \(self.game_state.current_player) already added"
            self.player_message_color = Color.red
        }
        else if self.game_state.players.count == self.max_players {
            self.player_message = "* only \(self.max_players) players allowed"
            self.player_message_color = Color.red
        }
        else {
            self.game_state.players.append(self.game_state.current_player)
            self.game_state.totals.append(0)
            self.game_state.phases.append(1)
            for round_index in (0...self.game_state.scores.count - 1) {
                self.game_state.scores[round_index].append(0)
            }
            
            self.player_message = "* \(self.game_state.current_player) added to game"
            self.player_message_color = Color.green
            self.game_state.current_player = ""
        }
    }
    
    private func StartGame() -> Bool {
        var start = true
        
        self.game_state.game_name = self.game_state.game_name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        if self.game_state.players.count == 0 {
            self.player_message = "* please add players to the game"
            self.player_message_color = Color.red
            
            start = false
        }
        else {
            self.player_message = ""
            self.game_state.current_player = ""
        }
        
        if self.game_state.game_name.count == 0 {
            self.game_name_error = "* name the game first!"
            start = false
        }
        /*else if !self.IsGameNameUnique() {
            self.game_cant_start_warning = "* game name already in use"
            start = false
        }
         */
        else {
            self.game_name_error = ""
        }
        
        return start
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // NAV BAR
            HStack(alignment: .center) {
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(alignment: .center) {
                        Text("cancel")
                    }
                }
                
                Spacer()
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                self.hideKeyboard()
            }
            
            
            // GAME NAME
            VStack(spacing: 5) {
                Text("Game name:")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.hideKeyboard()
                    }
                    
                
                TextField("Enter up to \(self.game_state.max_game_name_length) characters", text: $game_state.game_name)
                .multilineTextAlignment(.center)
                
                // ERROR
                Text(self.game_name_error)
                    .foregroundColor(Color.red)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.hideKeyboard()
                    }
            }
            .padding()
            
            
            // OPTIONS
            VStack(spacing: 15) {
                Toggle(isOn: $game_state.high_score_wins) {
                    if self.game_state.high_score_wins {
                        Text("High Score Wins")
                            .font(.system(size: 20))
                    }
                    else {
                        Text("Low Score Wins")
                            .font(.system(size: 20))
                    }
                }
                .frame(width: 300)
                
                Toggle(isOn: $game_state.phase_10) {
                    Text("Phase 10")
                        .font(.system(size: 20))
                        .foregroundColor(self.game_state.phase_10 ? Color.green : Color.red)
                }
                .frame(width: 300)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                self.hideKeyboard()
            }
            
            // PLAYERS
            VStack(spacing: 5) {
                Text("Players:")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.hideKeyboard()
                    }
                
                HStack(alignment: .center) {
                    TextField("Enter up to \(self.game_state.max_player_name_length) characters", text: $game_state.current_player)
                    .multilineTextAlignment(.center)
                        
                    Button(action: {
                        self.AddPlayer()
                    }) {
                        Text("Add +")
                    }
                    .frame(width: 100, height: 50)
                }
                
                Text(self.player_message)
                    .foregroundColor(self.player_message_color)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.hideKeyboard()
                    }
            }
            .padding()
            
            // PLAYER NAMES
            List {
                ForEach(self.game_state.players, id: \.self) { player in
                    Text(player)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .onDelete(perform: self.DeletePlayer)
            }
            .frame(width: 300)
            
            Button(action: {
                self.ready_to_start = self.StartGame()
                if self.ready_to_start {
                    self.game_state.game_in_progress = true
                }
            }) {
                if self.game_state.game_in_progress {
                    Text("Continue Game")
                        .font(.title)
                }
                else {
                    Text("Start Game")
                        .font(.title)
                }
            }
            .padding()
            
            NavigationLink(destination: GameView(game_state: self.game_state, root_view: self.$root_view), isActive: $ready_to_start) {
                EmptyView()
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

#if DEBUG

struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView(game_to_load: nil, root_view: .constant(true))
    }
}

#endif
