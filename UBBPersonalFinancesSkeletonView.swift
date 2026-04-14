//
//  PersonalFinancesSkeletonView.swift
//  UBB
//
//  Created by Chaman Sharma on 07/04/26.
//  Copyright © 2026 UBB. All rights reserved.
//

import UIKit

final class UBBPersonalFinancesSkeletonView {
    private let skeletonTrackColor = UIColor(
        red: 239.0 / 255.0,
        green: 243.0 / 255.0,
        blue: 247.0 / 255.0,
        alpha: 1.0
    )
    private let skeletonFillColor = UIColor(
        red: 219.0 / 255.0,
        green: 229.0 / 255.0,
        blue: 237.0 / 255.0,
        alpha: 1.0
    )

    func getSkeletonView() -> UIView {
        let rootView = UIView()
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.backgroundColor = .clear

        let topCardsStack = UIStackView()
        topCardsStack.translatesAutoresizingMaskIntoConstraints = false
        topCardsStack.axis = .horizontal
        topCardsStack.alignment = .fill
        topCardsStack.distribution = .fillEqually
        topCardsStack.spacing = 40.0

        let leftSummaryCard = makeTopCard()
        let rightSummaryCard = makeTopCard()
        topCardsStack.addArrangedSubview(leftSummaryCard)
        topCardsStack.addArrangedSubview(rightSummaryCard)

        let detailCard = makeBottomCard()

        rootView.addSubview(topCardsStack)
        rootView.addSubview(detailCard)

        NSLayoutConstraint.activate([
            topCardsStack.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 32.0),
            topCardsStack.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 56.0),
            topCardsStack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -56.0),

            detailCard.topAnchor.constraint(equalTo: topCardsStack.bottomAnchor, constant: 56.0),
            detailCard.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 56.0),
            detailCard.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -56.0),
            detailCard.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -32.0)
        ])

        return rootView
    }

    private func makeTopCard() -> UIView {
        let card = makeCard()
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentView)

        let primaryLine = makeSkeletonLine(height: 52.0, overlayWidthMultiplier: 0.43)
        let secondaryLine = makeSkeletonLine(height: 52.0, overlayWidthMultiplier: 0.43)
        let tertiaryLine = makeSkeletonLine(height: 38.0, overlayWidthMultiplier: 0.27)

        contentView.addSubview(primaryLine)
        contentView.addSubview(secondaryLine)
        contentView.addSubview(tertiaryLine)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 284.0),

            contentView.topAnchor.constraint(equalTo: card.topAnchor, constant: 42.0),
            contentView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 40.0),
            contentView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -40.0),
            contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -40.0),

            primaryLine.topAnchor.constraint(equalTo: contentView.topAnchor),
            primaryLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            primaryLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            secondaryLine.topAnchor.constraint(equalTo: primaryLine.bottomAnchor, constant: 16.0),
            secondaryLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            secondaryLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.68),

            tertiaryLine.topAnchor.constraint(equalTo: secondaryLine.bottomAnchor, constant: 28.0),
            tertiaryLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tertiaryLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.44),
            tertiaryLine.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor)
        ])

        return card
    }

    private func makeBottomCard() -> UIView {
        let card = makeCard()
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentView)

        let leftBlock = UIView()
        leftBlock.translatesAutoresizingMaskIntoConstraints = false
        leftBlock.backgroundColor = skeletonTrackColor
        leftBlock.layer.cornerRadius = 18.0

        let headlineLine = makeSkeletonLine(height: 52.0, overlayWidthMultiplier: 0.43)
        let subtitleLine = makeSkeletonLine(height: 38.0, overlayWidthMultiplier: 0.43)
        let actionLine = makeSkeletonLine(height: 54.0, overlayWidthMultiplier: 0.41)

        contentView.addSubview(leftBlock)
        contentView.addSubview(headlineLine)
        contentView.addSubview(subtitleLine)
        contentView.addSubview(actionLine)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 218.0),

            contentView.topAnchor.constraint(equalTo: card.topAnchor, constant: 40.0),
            contentView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 40.0),
            contentView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -40.0),
            contentView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -40.0),

            leftBlock.topAnchor.constraint(equalTo: contentView.topAnchor),
            leftBlock.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            leftBlock.widthAnchor.constraint(equalToConstant: 140.0),
            leftBlock.heightAnchor.constraint(equalToConstant: 136.0),

            headlineLine.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0),
            headlineLine.leadingAnchor.constraint(equalTo: leftBlock.trailingAnchor, constant: 28.0),
            headlineLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.50),

            subtitleLine.topAnchor.constraint(equalTo: headlineLine.bottomAnchor, constant: 16.0),
            subtitleLine.leadingAnchor.constraint(equalTo: headlineLine.leadingAnchor),
            subtitleLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.29),

            actionLine.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8.0),
            actionLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            actionLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.19)
        ])

        return card
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = KDLColors.kdlCellBackground()
        card.layer.cornerRadius = 28.0
        card.layer.masksToBounds = false
        card.layer.shadowColor = KDLColors.shadowColor().cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowOffset = CGSize(width: 0.0, height: 12.0)
        card.layer.shadowRadius = 24.0
        return card
    }

    private func makeSkeletonLine(height: CGFloat, overlayWidthMultiplier: CGFloat) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = skeletonTrackColor
        container.layer.cornerRadius = height / 4.0

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = skeletonFillColor
        overlay.layer.cornerRadius = height / 4.0

        container.addSubview(overlay)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: height),

            overlay.topAnchor.constraint(equalTo: container.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            overlay.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            overlay.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: overlayWidthMultiplier)
        ])

        return container
    }
}
