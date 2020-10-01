//
//  GameState.swift
//  Scoreboard
//
//  Created by user179118 on 9/9/20.
//  Copyright © 2020 stevef. All rights reserved.
//

import Foundation
import CoreData


public class GameStateActive: ObservableObject {
    init(loaded_game: GameStateSaved? = nil) {
        self.loaded_game = loaded_game
        
        if loaded_game != nil {
            self.game_name = loaded_game!.game_name
            self.high_score_wins = loaded_game!.high_score_wins
            self.phase_10 = loaded_game!.phase_10
            self.players = loaded_game!.players
            self.phases = loaded_game!.phases
            self.totals = loaded_game!.totals
            self.scores = loaded_game!.scores
            self.game_in_progress = true
        }
    }
    
    let loaded_game: GameStateSaved?
    
    let max_game_name_length: Int = 20
    let max_player_name_length: Int = 10
    @Published var game_name: String = "" {
        didSet {
            if game_name.count > max_game_name_length {
                self.game_name = String(self.game_name.prefix(max_game_name_length))
            }
        }
    }
    @Published var high_score_wins: Bool = true
    @Published var phase_10: Bool = false
    @Published var players: [String] = []
    @Published var phases: [Int] = []
    @Published var current_player: String = "" {
        didSet {
            if current_player.count > max_player_name_length {
                self.current_player = String(self.current_player.prefix(max_player_name_length))
            }
        }
    }
    
    var totals: [Int] = []
    @Published var scores: [[Int]] = [[]]
    
    var game_in_progress = false
}

public class GameStateSaved:NSManagedObject, Identifiable {
    
    @NSManaged public var game_name: String
    @NSManaged public var high_score_wins: Bool
    @NSManaged public var phase_10: Bool
    @NSManaged public var players: [String]
    @NSManaged public var phases: [Int]
    @NSManaged public var totals: [Int]
    @NSManaged public var scores: [[Int]]
    @NSManaged public var end_date: Date
}

extension GameStateSaved {
    static func GetGames() -> NSFetchRequest<GameStateSaved> {
        let request:NSFetchRequest<GameStateSaved> = GameStateSaved.fetchRequest() as! NSFetchRequest<GameStateSaved>
        
        let sort_descriptor = NSSortDescriptor(key: "end_date", ascending: false)
        
        request.sortDescriptors = [sort_descriptor]
        
        return request
    }
}
