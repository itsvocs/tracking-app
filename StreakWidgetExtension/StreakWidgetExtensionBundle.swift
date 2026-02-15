//
//  StreakWidgetExtensionBundle.swift
//  StreakWidgetExtension
//
//  Created by Jo on 15.02.26.
//

import WidgetKit
import SwiftUI

@main
struct StreakWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        StreakWidgetExtension()
        StreakWidgetExtensionControl()
        StreakWidgetExtensionLiveActivity()
    }
}
