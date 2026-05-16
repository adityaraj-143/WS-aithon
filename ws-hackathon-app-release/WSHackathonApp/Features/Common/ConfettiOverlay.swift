//
//  ConfettiOverlay.swift
//  WSHackathonApp
//

import SwiftUI

struct ConfettiOverlay: View {
    
    @State private var particles: [ConfettiParticle] = []
    @State private var startTime = Date()
    
    private let confettiColors: [Color] = [
        .brandPrimary,
        .brandSecondary,
        .brandAccentWash,
        .wsSuccess,
        .textPrimary,
        .textTertiary
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startTime)
                
                for particle in particles {
                    let age = elapsed - particle.delay
                    guard age > 0 else { continue }
                    
                    let progress = age / particle.lifetime
                    guard progress < 1 else { continue }
                    
                    let x = particle.startX * size.width + sin(age * particle.wobbleSpeed) * particle.wobbleAmplitude
                    let y = particle.startY * size.height + age * particle.fallSpeed
                    
                    let opacity = 1.0 - pow(progress, 2)
                    let rotation = Angle(degrees: age * particle.rotationSpeed)
                    
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    
                    let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size)
                    
                    context.fill(
                        RoundedRectangle(cornerRadius: particle.size * 0.2).path(in: rect),
                        with: .color(particle.color)
                    )
                    
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTime = Date()
            particles = (0..<40).map { _ in
                ConfettiParticle(
                    startX: Double.random(in: 0.1...0.9),
                    startY: Double.random(in: -0.2...0.0),
                    size: Double.random(in: 6...12),
                    color: confettiColors.randomElement()!,
                    fallSpeed: Double.random(in: 80...200),
                    wobbleSpeed: Double.random(in: 2...6),
                    wobbleAmplitude: Double.random(in: 15...40),
                    rotationSpeed: Double.random(in: 60...240),
                    lifetime: Double.random(in: 1.5...2.5),
                    delay: Double.random(in: 0...0.3)
                )
            }
        }
    }
}

private struct ConfettiParticle {
    let startX: Double
    let startY: Double
    let size: Double
    let color: Color
    let fallSpeed: Double
    let wobbleSpeed: Double
    let wobbleAmplitude: Double
    let rotationSpeed: Double
    let lifetime: Double
    let delay: Double
}
