//
//  MartemComponents.swift
//  Martem
//
//  Created by Tufan Cakir on 21.11.26.
//

import SwiftUI

struct MartemButtonStyle: ButtonStyle {
    @Environment(\.martemTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var selected = false
    var primary = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(
                !isEnabled
                    ? theme.mutedText
                    : (selected || primary
                        ? theme.highlight : theme.primaryText)
            )
            .frame(minHeight: theme.number("minimumTouchTarget"))
            .padding(.horizontal, theme.number("mediumSpacing"))
            .background(
                configuration.isPressed ? theme.elevatedSurface : theme.surface
            )
            .overlay(
                Rectangle().stroke(
                    selected ? theme.highlight : theme.border,
                    lineWidth: theme.number(
                        selected ? "selectedBorderWidth" : "borderWidth"
                    )
                )
            )
            .opacity(isEnabled ? 1 : 0.55)
            .animation(
                reduceMotion
                    ? nil : .easeOut(duration: theme.number("pressDuration")),
                value: configuration.isPressed
            )
    }
}

struct MartemPanel<Content: View>: View {
    @Environment(\.martemTheme) private var theme
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(theme.number("largeSpacing"))
            .background(theme.surface)
            .overlay(
                Rectangle().stroke(
                    theme.border,
                    lineWidth: theme.number("borderWidth")
                )
            )
    }
}
