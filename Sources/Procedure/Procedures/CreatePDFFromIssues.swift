import CommandLineKit
import Environment
import Model
import Quartz
import Request
import UI
import Yams

public struct CreatePDFFromIssues: Procedure {
    enum Error: Swift.Error {
        case openPDF, noIssuesSelected, noIssuesLoaded, noConfig
    }

    public init() {}

    public func run() -> Bool {
        do {
            guard let config = Env.current.configStore.config ?? {
                // run init if there is no config file
                guard Initialize().run() else { return nil }
                return Env.current.configStore.config
            }() else { throw Error.noConfig }

            // get issues of current sprint
            guard let sprint = GetCurrentSprint(jiraProject: config.jiraProject).awaitResponseWithDebugPrinting()?.sprints.first,
                let issues = GetIssuesBySprint(
                    sprint: sprint,
                    exclude: [.subTask, .subBug],
                    limit: 100
                )
                .awaitResponseWithDebugPrinting()?
                .issues
                .sorted(by: { $0.id < $1.id })
            else { throw Error.noIssuesLoaded }

            // how to use the LineSelector
            Env.current.shell.write("\nAll highlighted issues will be printed. Toggle selection with Tab key.\n")

            // present the list of issues to the user to discard unwanted
            let previouslySelected = (Env.current.defaults[.selectedIssues] as [String]?) ?? []
            let atLeastOneCurrentIssueWasPreviouslySelected = issues.contains { issue in previouslySelected.contains(issue.key) }
            let dataSource = GenericLineSelectorDataSource(items: issues) {
                ("\($0.key) \($0.fields.summary)", atLeastOneCurrentIssueWasPreviouslySelected ? previouslySelected.contains($0.key) : true)
            }
            guard let selectedIssues = LineSelector(dataSource: dataSource)?.multiSelection()?.output,
                !selectedIssues.isEmpty else { throw Error.noIssuesSelected }
            Env.current.defaults[.selectedIssues] = selectedIssues.map { $0.key }

            // remove the usage description for LineSelector
            LineDrawer(linesToDrawCount: 0).reset(lines: 3)

            // resolve epic links for each issue
            let epics = getEpics(for: selectedIssues)

            let directory = try Env.current.directory.init(path: .current, create: false)

            // get file URL for PDF
            let file = directory.file("\(sprint.trainCasedName).pdf")

            // fill the PDF with the issues of the current sprint
            drawPDF(in: file, for: selectedIssues, sprint: sprint, with: epics, config: config)

            // open the PDF
            if !Env.current.workspace.open(file.path.url) {
                throw Error.openPDF
            }
        } catch {
            Env.current.shell.write("\(error)")
            return false
        }

        return true
    }

    private func drawPDF(in file: File, for issues: [Issue], sprint: SprintJQL, with epics: [String: Epic], config: Configuration) {
        // calculate power of two of maximum fitting issues on one page with columns and rows
        let ceilLg = log2(CGFloat(config.issuesPerPage)).rounded(.up)
        let printedIssuesPerPage = pow(2, ceilLg)
        let columns = pow(2, (ceilLg / 2).rounded(.down))
        let rows = printedIssuesPerPage / columns

        // set up CGContext and NSGraphicsContext
        let printInfo = NSPrintInfo.shared
        printInfo.orientation = columns == rows ? .landscape : .portrait
        var mediaBox = CGRect(origin: .zero, size: printInfo.paperSize)
        guard let graphicsContext = CGContext(file.path.url as CFURL, mediaBox: &mediaBox, metadata(for: sprint)) else { return }
        let nsGraphicsContext = NSGraphicsContext(cgContext: graphicsContext, flipped: false)

        NSGraphicsContext.current = nsGraphicsContext

        let boxData = NSData(bytes: &mediaBox, length: MemoryLayout.size(ofValue: mediaBox))
        let pageInfo = [kCGPDFContextMediaBox as String: boxData]

        // Size of printable area / issue
        let printableRect = config.limitToPrintableArea ? printInfo.imageablePageBounds : mediaBox

        // Size of cells
        let columnWidth = (printableRect.width / CGFloat(columns)).rounded(.down)
        let rowHeight = (printableRect.height / CGFloat(rows)).rounded(.down)
        let cellSize = CGSize(
            width: columnWidth - CGFloat(columns > 1 ? 1 : 0), // smaller to print some space between the issues
            height: rowHeight - CGFloat(rows > 1 ? 1 : 0)
        )
        let scale = CGFloat(1) / CGFloat(printedIssuesPerPage).squareRoot()

        // Data to print
        var issuesWithCategoryDisplayNameAndCategoryAndEpic = issues.compactMap { issue -> (issue: Issue, categoryDisplayName: String, category: IssueCategory, epic: Epic)? in
            let epicLink = issue.fields.epicLink ?? IssueCategory.featureKey
            guard let (categoryDisplayName, category, epic) = getCategory(
                epicLink: epicLink,
                epics: epics,
                config: Env.current.configStore.config ?? config // Config could have been updated in the meantime
                )
                ?? getCategory(
                    epicLink: epicLink,
                    epics: epics,
                    config: updateConfig(
                        newEpicLink: epicLink,
                        config: Env.current.configStore.config ?? config,
                        epics: epics
                    )
                )
                else { return nil }
            return (issue, categoryDisplayName, category, epic)
        }
        .sorted { $0.categoryDisplayName < $1.categoryDisplayName }

        // add sprint goal slide
        if Env.current.shell.promptDecision("Add slide for current sprint goal?"),
            let goal = GetSprint(id: sprint.id).awaitResponseWithDebugPrinting()?.goal,
            let (category, epic) = getSprintGoalCategory() {
            issuesWithCategoryDisplayNameAndCategoryAndEpic.append((
                issue: Issue(
                    key: epic.fields.name,
                    fields: .init(
                        summary: goal,
                        parent: nil,
                        issuetype: .story,
                        updated: nil,
                        description: nil,
                        fixVersions: [],
                        epicLink: ""
                    ),
                    id: 0),
                categoryDisplayName: epic.fields.name,
                category: category,
                epic: epic))
        }

        var index = 0
        var done = false

        let pagesCount = Int((Double(issuesWithCategoryDisplayNameAndCategoryAndEpic.count) / Double(printedIssuesPerPage)).rounded(.up))

        // pages
        for _ in 0 ..< pagesCount {
            // start new PDF page
            graphicsContext.beginPDFPage(pageInfo as NSDictionary)

            // columns
            for column in stride(from: 0, to: columns, by: 1) where !done {
                let originX = printableRect.origin.x + column * columnWidth

                // rows
                for row in stride(from: 0, to: rows, by: 1) where !done {
                    let rect = CGRect(
                        origin: .init(
                            x: originX,
                            // 0,0 coordinate is at the bottom left but issues are printed from the top
                            // so the first issue starts at the height of the bounding rect minus rowHeight,
                            // the next there minus one rowHeight and so on.
                            y: printableRect.origin.y
                                + printableRect.height
                                - rowHeight
                                - row
                                * rowHeight
                        ),
                        size: cellSize
                    )

                    let (issue, categoryDisplayName, category, epic) = issuesWithCategoryDisplayNameAndCategoryAndEpic[index]

                    // white background of summary and description
                    let contentBackgroundRect = CGRect(
                        x: rect.origin.x
                            + config.insets.contentBackgroundInsets.left.scaled(scale),
                        y: rect.origin.y
                            + config.insets.contentBackgroundInsets.bottom.scaled(scale),
                        width: rect.width
                            - config.insets.contentBackgroundInsets.left.scaled(scale)
                            - config.insets.contentBackgroundInsets.right.scaled(scale),
                        height: rect.height
                            - config.insets.contentBackgroundInsets.top.scaled(scale)
                            - config.insets.contentBackgroundInsets.bottom.scaled(scale)
                    )

                    // bounding box of summary and description
                    let contentRect = CGRect(
                        x: contentBackgroundRect.origin.x
                            + config.insets.contentInsets.left.scaled(scale),
                        y: contentBackgroundRect.origin.y
                            + config.insets.contentInsets.bottom.scaled(scale),
                        width: contentBackgroundRect.width
                            - config.insets.contentInsets.left.scaled(scale)
                            - config.insets.contentInsets.right.scaled(scale),
                        height: contentBackgroundRect.height
                            - config.insets.contentInsets.top.scaled(scale)
                            - config.insets.contentInsets.bottom.scaled(scale)
                    )

                    // draw background
                    graphicsContext.setFillColor(category.color.cgColor)
                    graphicsContext.fill(rect)

                    // draw category on background
                    let categoryLabel = epic.fields.name.hasPrefix(categoryDisplayName)
                        ? epic.fields.name
                        : "\(categoryDisplayName) / \(epic.fields.name)"
                    let categoryAttributes = config.fontSettings.category.attributes(color: .white, scale: scale)
                    let categoryAttributedString = NSAttributedString(string: categoryLabel, attributes: categoryAttributes)
                    let categoryBoundingRect = categoryAttributedString.boundingRect(with: .init(
                        width: contentRect.width
                            - config.fontSettings.category.insets.left.scaled(scale)
                            - config.fontSettings.category.insets.right.scaled(scale),
                        height: config.insets.contentBackgroundInsets.bottom.scaled(scale)
                            - config.fontSettings.category.insets.bottom.scaled(scale)
                    ))
                    let categoryMarginBottom = rect.minY
                        + (config.insets.contentBackgroundInsets.bottom.scaled(scale)
                            - categoryBoundingRect.height
                        ) / 2
                    categoryAttributedString.draw(in: .init(
                        x: contentRect.maxX
                            - categoryBoundingRect.width
                            - config.fontSettings.category.insets.right.scaled(scale),
                        y: categoryMarginBottom
                            + config.fontSettings.category.insets.bottom.scaled(scale),
                        width: categoryBoundingRect.width,
                        height: categoryBoundingRect.height
                    ))

                    // draw fixVersion on background
                    let fixVersions = issue.fields.fixVersions
                        .map { config.fixVersionEmojis[$0.name] ?? $0.name }
                        .joined(separator: " ")
                    if !fixVersions.isEmpty {
                        let fixVersionsAttributedString = NSAttributedString(
                            string: fixVersions,
                            attributes: config.fontSettings.fixVersions.attributes(color: .white, scale: scale)
                        )
                        let fixVersionsBoundingRect = fixVersionsAttributedString.boundingRect(with: .init(
                            width: contentRect.width
                                - categoryBoundingRect.width
                                - config.fontSettings.category.insets.right.scaled(scale)
                                - config.fontSettings.fixVersions.insets.left.scaled(scale),
                            height: config.insets.contentBackgroundInsets.bottom.scaled(scale)
                                - config.fontSettings.fixVersions.insets.bottom.scaled(scale)
                        ))
                        let fixVersionsMarginBottom = rect.minY
                            + (config.insets.contentBackgroundInsets.bottom.scaled(scale)
                                - fixVersionsBoundingRect.height
                            ) / 2
                        fixVersionsAttributedString.draw(in: .init(
                            x: contentRect.minX
                                + config.fontSettings.fixVersions.insets.left.scaled(scale),
                            y: fixVersionsMarginBottom
                                + config.fontSettings.fixVersions.insets.bottom.scaled(scale),
                            width: fixVersionsBoundingRect.width,
                            height: fixVersionsBoundingRect.height
                        ))
                    }

                    // draw white background for summary and description
                    graphicsContext.setFillColor(NSColor.white.cgColor)
                    graphicsContext.fill(contentBackgroundRect)

                    let (cleansedDescription, appliedRange) = issue
                        .cleansedDescription(
                            ranges: config.descriptionPatterns,
                            maxLines: config.descriptionLinesMax
                        )

                    if Env.current.debug {
                        let green = TextProperties(.green, nil)
                        let blue = TextProperties(.blue, nil)
                        let grey = TextProperties(.grey, nil)
                        Env.current.shell.write("""

                        \(green.apply(to: "Issue \(issue.key): \(issue.fields.summary)"))

                        \(blue.apply(to: "* Original description:"))
                        \(issue.fields.description.map(grey.apply(to:)) ?? "No description")

                        \(blue.apply(to: "* Cleansed description:"))
                        \(cleansedDescription ?? "No cleansed description")

                        \(blue.apply(to: "* Applied range:"))
                        \(appliedRange.map{ String(describing: $0) } ?? "No range applied")

                        """)
                    }

                    // draw summary and description
                    let textsWithfontStyle = [
                        (issue.fields.summary, config.fontSettings.summary),
                        ((cleansedDescription == nil || cleansedDescription?.isEmpty == true) ? nil : config.textResources["aim"], config.fontSettings.aim),
                        (cleansedDescription, config.fontSettings.description)
                    ]

                    var availableSpace = contentRect

                    for case let (string?, fontStyle) in textsWithfontStyle where !string.isEmpty {
                        let maxSize = CGSize(
                            width: availableSpace.width
                                - fontStyle.insets.left.scaled(scale)
                                - fontStyle.insets.right.scaled(scale),
                            height: availableSpace.height
                                - fontStyle.insets.top.scaled(scale)
                                - fontStyle.insets.bottom.scaled(scale)
                        )

                        let (attributedString, size) = string.attributedStringWithSize(
                            fitting: maxSize,
                            fontName: fontStyle.fontName,
                            maxFontSize: fontStyle.fontSize,
                            scale: scale,
                            attributes: fontStyle.attributes(
                                color: category.color,
                                scale: scale
                            )
                        )

                        attributedString.draw(in: .init(
                            origin: .init(
                                x: availableSpace.minX
                                    + fontStyle.insets.left.scaled(scale),
                                y: availableSpace.maxY
                                    - size.height
                                    - fontStyle.insets.top.scaled(scale)
                            ),
                            size: size
                        ))

                        availableSpace = availableSpace.divided(
                            atDistance: size.height
                                + fontStyle.insets.top.scaled(scale)
                                + fontStyle.insets.bottom.scaled(scale),
                            from: .maxYEdge
                        ).remainder
                    }

                    index += 1

                    if index == issuesWithCategoryDisplayNameAndCategoryAndEpic.endIndex {
                        done = true
                    }
                }
            }

            // end PDF page
            graphicsContext.endPDFPage()
        }

        NSGraphicsContext.current = nil
        graphicsContext.closePDF()
    }

    private func metadata(for sprint: SprintJQL) -> CFDictionary {
        return [
            kCGPDFContextCreator: Env.current.toolName,
            kCGPDFContextAuthor: NSFullUserName(),
            kCGPDFContextTitle: sprint.name,
            kCGPDFContextSubject: "JIRA issues of sprint \(sprint.name)."
        ] as CFDictionary
    }

    private func updateConfig(newEpicLink: String, config: Configuration, epics: [String: Epic]) -> Configuration {
        guard let epic = epics[newEpicLink]?.fields.name else { return config }

        let newCategory: String?
        if Env.current.shell.promptDecision("New epic \"\(epic)\" found. Do you want to assign it to an existing category? (Otherwise create a new one.)") {
            let keys = config.categories.map { $0.key }
            let dataSource = GenericLineSelectorDataSource(items: keys) { ($0, false) }
            newCategory = LineSelector(dataSource: dataSource)?.singleSelection()?.output
        } else {
            newCategory = Env.current.shell.prompt("New category")
        }

        if let newCategory = newCategory {
            let existingEpics = config.categories[newCategory]?.epics
            let newEpics = existingEpics.map { $0 + [epic] } ?? [epic]
            let existingColor = config.categories[newCategory]?.color
            let newColor = existingColor ?? promptColor() ?? .black
            var config = config
            config.categories[newCategory] = IssueCategory(epics: newEpics, color: newColor)
            Env.current.configStore.config = config
            return config
        }
        return config
    }

    private func getCategory(epicLink: String, epics: [String: Epic], config: Configuration)
        -> (categoryDisplayName: String, category: IssueCategory, epic: Epic)? {
        guard let epic = epics[epicLink] else { return nil }
        return config
            .categories
            .first { (_: String, value: IssueCategory) -> Bool in value.epics.contains(epic.fields.name) }
            .map { ($0.key, $0.value, epic) }
    }

    private func getSprintGoalCategory() -> (category: IssueCategory, epic: Epic)? {
        guard let config = Env.current.configStore.config,
            let label = config.textResources["sprint_goal"] else { return nil }

        let epic = Epic(fields: .init(name: label, summary: ""))
        let category = config.categories[label] ?? {
            Env.current.shell.write("No color defined for category \"\(label)\".")
            let color = promptColor() ?? .black
            let category = IssueCategory(epics: [label], color: color)
            var config = config
            config.categories[label] = category
            Env.current.configStore.config = config
            return category
        }()

        return (category, epic)
    }

    private func promptColor() -> Color? {
        return Env.current.shell.prompt("Which color should the new category have? Components, each between 0 and 255: <r,g,b,α>").flatMap { input in
            let components = input.trimmingCharacters(in: .whitespaces).split(separator: ",").compactMap { Int($0) }
            guard components.count == 4 else { return nil }
            return Color(red: components[0], green: components[1], blue: components[2], alpha: components[3])
        }
    }
}

private extension CGFloat {
    func scaled(_ scale: CGFloat) -> CGFloat {
        return self * scale
    }
}
