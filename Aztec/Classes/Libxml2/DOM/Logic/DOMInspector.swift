import Foundation

extension Libxml2 {
    /// Groups all the DOM inspection & node lookup logic.
    ///
    class DOMInspector: DOMLogic {

        private typealias Test = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> TestResult

        /// Used as a result type for searching the DOM tree.
        ///
        private enum TestResult {

            /// The test didn't succeed.
            ///
            case failure

            /// The test was successful for this node.
            ///
            case success

            /// One or more descendants of the provided element fulfill the condition
            ///
            case descendant(element: ElementNode)
        }

        private typealias MatchTest = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> MatchType

        /// Used as a result type for searching the DOM tree.
        ///
        private enum MatchType {

            /// No match.
            ///
            case noMatch

            /// The reference node is a match.
            ///
            case match

            /// One of the descendants of the reference element is a match.
            ///
            case descendant(element: ElementNode)
        }

        typealias ElementAndLocation = (element: ElementNode, location: Int)
        typealias ElementAndRange = (element: ElementNode, range: NSRange)
        private typealias EnumerationStep = (_ node: Node, _ startLocation: Int, _ endLocation: Int) -> NextStep

        /// An enum used for enumerating through a DOM tree.  Defines how enumeration continues
        /// after the reference step.
        ///
        private enum NextStep {

            /// Stop enumerating
            ///
            case stop

            /// Continue enumerating siblings from left to right.  Exits if no other sibling is
            /// found.
            ///
            case continueWithSiblings

            /// Enumerate the children of the reference element (from left to right).
            ///
            case continueWithChildren(element: ElementNode)
        }

        // MARK: - Parent

        /// Call this method whenever you node the specified node MUST have a parent set.
        /// This method will interrupt program execution if a parent isn't set.
        ///
        /// - Parameters:
        ///     - node: the node you want to get the parent of.
        ///
        /// - Returns: the parent element.
        ///
        func parent(of node: Node) -> ElementNode {
            guard let parent = node.parent else {
                fatalError("This method should only be called whenever you are sure a parent is set.")
            }

            return parent
        }

        // MARK: - Node Introspection

        func isEmptyTextNode(_ node: Node) -> Bool {
            return node is TextNode && node.length() == 0
        }

        // MARK: - Siblings

        func rightSibling(of node: Node) -> Node? {
            guard let parent = node.parent else {
                assertionFailure("Shouldn't call this method in a node without a parent.")
                return nil
            }

            let nextIndex = parent.indexOf(childNode: node) + 1

            guard parent.children.count > nextIndex else {
                return nil
            }

            return parent.children[nextIndex]
        }

        // MARK: - Finding nodes

        /// Finds a node ending at the specified location.
        ///
        //// - Parameters:
        ///     - location: the location where the node is supposed to end.
        ///
        /// - Returns: the node that ends at the specified location.
        ///
        func findNode(endingAt location: Int) -> Node? {
            return findDescendant(of: rootNode, endingAt: location)
        }

        /// Finds the leftmost and lowest element intersecting the specified location.
        ///
        func findLeftmostLowestDescendantElement(intersecting location: Int) -> ElementAndLocation {
            return findLeftmostLowestDescendantElement(of: rootNode, intersecting: location)
        }

        /// Finds the lowest element containing the full specified range.
        ///
        //// - Parameters:
        ///     - startingElement: the head node of the subtree for the search.
        ///     - range: the range that must be contained by the element.
        ///     - blockLevelOnly: flag to specify if the requested element has to be a block-level
        ///             element.
        ///
        /// - Returns: a pair containing the matching element (or `startingElement`, if no better
        ///         match is found) and the input location relative in the returned element's
        ///         coordinates.
        ///
        func findLowestElementDescendant(
            of startingElement: ElementNode,
            containing range: NSRange,
            blockLevelOnly: Bool = false) -> ElementAndRange {

            assert(startingElement.range().contains(range: range))

            var result = (startingElement, range)

            navitageDescendants(of: startingElement) { (node, startLocation, endLocation) -> NextStep in

                guard let element = node as? ElementNode else {
                    return .stop
                }

                let nodeRange = NSRange(location: startLocation, length: endLocation - startLocation)

                if range().contains(range: nodeRange) {
                    return .continueWithChildren(element: element)
                } else {
                    return .stop
                }

                /// ASDASDASDASDASDSASDS


                guard startLocation <= location else {
                    return .stop
                }

                guard location <= endLocation && !isEmptyTextNode(node),
                    let element = node as? ElementNode,
                    blockLevelOnly || element.isBlockLevelElement() else {

                        return .continueWithSiblings
                }

                let relativeLocation = location - startLocation

                // The current element matches our search.  It may be necessary to go through the
                // child nodes, but for the time being its our best candidate.
                //
                result = (element, relativeLocation)

                if element.children.count > 0 {
                    return .continueWithChildren(element: element)
                } else {
                    return .stop
                }
            }
            
            return result
        }

        /// Finds the leftmost, lowest descendant element of the refrence element, intersecting a
        /// reference location.
        ///
        //// - Parameters:
        ///     - startingElement: the head node of the subtree for the search.
        ///     - location: the reference location for the search logic.
        ///     - blockLevelOnly: flag to specify if the requested element has to be a block-level
        ///             element.
        ///
        /// - Returns: a pair containing the matching element (or `startingElement`, if no better
        ///         match is found) and the input location relative in the returned element's
        ///         coordinates.
        ///
        func findLeftmostLowestDescendantElement(
            of startingElement: ElementNode,
            intersecting location: Int,
            blockLevelOnly: Bool = false) -> ElementAndLocation {

            var result = (startingElement, location)

            enumerateDescendants(of: startingElement) { (node, startLocation, endLocation) -> NextStep in

                guard startLocation <= location else {
                    return .stop
                }

                guard location <= endLocation && !isEmptyTextNode(node),
                    let element = node as? ElementNode,
                    blockLevelOnly || element.isBlockLevelElement() else {

                        return .continueWithSiblings
                }

                let relativeLocation = location - startLocation

                // The current element matches our search.  It may be necessary to go through the
                // child nodes, but for the time being its our best candidate.
                //
                result = (element, relativeLocation)

                if element.children.count > 0 {
                    return .continueWithChildren(element: element)
                } else {
                    return .stop
                }
            }

            return result
        }

        /// Finds the descendant of the specified node, ending at the specified location.
        ///
        //// - Parameters:
        ///     - startingElement: the node to search the descendant of.
        ///     - location: the location where the descendant ends.
        ///
        /// - Returns: the node that ends at the specified location.
        ///
        private func findDescendant(of startingElement: ElementNode, endingAt location: Int) -> Node? {

            return firstDescendant(of: startingElement, matching: { (node, startLocation, endLocation) -> MatchType in
                // Ignore empty nodes
                //
                guard startLocation != endLocation else {
                    return .noMatch
                }

                if endLocation == location {
                    return .match
                } else if startLocation < location && location < endLocation,
                    let element = node as? ElementNode {

                    return .descendant(element: element)
                }

                return .noMatch
            })
        }

        // MARK: - Finding Node: Core Methods

        /// Navigates the descendants of a provided element.
        ///
        /// - Parameters:
        ///     - startingElement: the reference element for the enumeration.  The enumeration step
        ///             is not executed for this node.
        ///     - step: the enumeration step, returning an indication of how the enumeration will
        ///             continue, or if it needs to be interrupted.
        ///
        private func navigateDescendants(of startingElement: ElementNode, withStep step: EnumerationStep) {

            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                let nextStep = step(child, childStartLocation, childEndLocation)

                switch nextStep {
                case .stop:
                    return
                case let .continueWithChildren(element):
                    navigateDescendants(of: element, withStep: { (descendant, descendantChildStartLocation, descendantChildEndLocation) in
                        let absoluteStartLocation = descendantChildStartLocation + childStartLocation
                        let absoluteEndLocation = descendantChildEndLocation + childStartLocation

                        return step(descendant, absoluteStartLocation, absoluteEndLocation)
                    })
                case .continueWithSiblings:
                    childStartLocation = childEndLocation
                }
            }
        }

        /// Finds the first descendant of the specified element, matching the provided test.
        ///
        /// - Note: search order is left-to-right, top-to-bottom.
        ///
        /// - Parameters:
        ///     - startingElement: the reference element for the lookup.  Excluded from the search.
        ///     - test: the search test condition.
        ///
        /// - Returns: the requested descendant.
        ///
        private func firstDescendant(of startingElement: ElementNode, matching test: MatchTest) -> Node? {

            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                let matchType = test(child, childStartLocation, childEndLocation)

                switch matchType {
                case .match:
                    return child
                case let .descendant(element):
                    return firstDescendant(of: element, matching: { (descendant, grandChildStartLocation, grandChildEndLocation) -> MatchType in
                        let absoluteStartLocation = grandChildStartLocation + childStartLocation
                        let absoluteEndLocation = grandChildEndLocation + childStartLocation

                        return test(descendant, absoluteStartLocation, absoluteEndLocation)
                    })
                default:
                    childStartLocation = childEndLocation
                }
            }
            
            return nil
        }

        private func findDescendants(of element: ElementNode, fulfilling test: TestResult) -> [Node]? {
            var childStartLocation = 0

            for child in startingElement.children {

                let childEndLocation = childStartLocation + child.length()

                let matchType = test(child, childStartLocation, childEndLocation)

                switch matchType {
                case .match:
                    return child
                case let .descendant(element):
                    return firstDescendant(of: element, matching: { (descendant, grandChildStartLocation, grandChildEndLocation) -> MatchType in
                        let absoluteStartLocation = grandChildStartLocation + childStartLocation
                        let absoluteEndLocation = grandChildEndLocation + childStartLocation

                        return test(descendant, absoluteStartLocation, absoluteEndLocation)
                    })
                default:
                    childStartLocation = childEndLocation
                }
            }
            
            return nil
        }
    }
}
