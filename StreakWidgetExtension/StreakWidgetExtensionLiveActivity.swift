//
//  StreakWidgetExtensionLiveActivity.swift
//  StreakWidgetExtension
//
//  Created by Jo on 15.02.26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StreakWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct StreakWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreakWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension StreakWidgetExtensionAttributes {
    fileprivate static var preview: StreakWidgetExtensionAttributes {
        StreakWidgetExtensionAttributes(name: "World")
    }
}

extension StreakWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: StreakWidgetExtensionAttributes.ContentState {
        StreakWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: StreakWidgetExtensionAttributes.ContentState {
         StreakWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: StreakWidgetExtensionAttributes.preview) {
   StreakWidgetExtensionLiveActivity()
} contentStates: {
    StreakWidgetExtensionAttributes.ContentState.smiley
    StreakWidgetExtensionAttributes.ContentState.starEyes
}
