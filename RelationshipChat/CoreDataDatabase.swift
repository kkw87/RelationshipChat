//
//  CoreDataDatabase.swift
//  RelationshipChat
//
//  Created by Kevin Wang on 8/16/17.
//  Copyright © 2017 KKW. All rights reserved.
//

import Foundation

@available(iOS 10.0, *)

struct CoreDataDB {
    static let Context = CoreDataDB.Container.viewContext
    static let Container = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
}
