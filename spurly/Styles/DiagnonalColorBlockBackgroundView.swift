//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct DiagonalColorBlockBackgroundView: View {
    let colors: [Color] // An array of colors for the blocks
    let angle: Angle // The angle of the diagonal lines

    init(colors: [Color] = [(Color.accent1), (Color.accent2), (Color.accent3)], //
         angle: Angle = .degrees(45)) {
        self.colors = colors
        self.angle = angle
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Ensure there's at least one color
                guard !colors.isEmpty else { return }

                let numberOfBlocks = colors.count
                let rect = CGRect(origin: .zero, size: size)

                // Calculate the "width" of each diagonal strip based on the longest dimension
                // This is a simplification; true perpendicular width is more complex.
                // For even-looking strips, we need a more robust calculation
                // of how far to offset each parallel path.

                // Let's draw N diagonal bands across the view.
                // The paths will be parallel.
                // We need to determine the start and end points for these diagonal lines.
                // The angle determines the slope.

                let transform = CGAffineTransform(rotationAngle: CGFloat(angle.radians))

                // Define a very large rectangle that, when rotated, will cover the entire view.
                // This is easier than calculating exact intersection points for each band.
                let superRectWidth = (size.width + size.height) * 2 // Ensure it's large enough
                let bandHeight = superRectWidth / CGFloat(numberOfBlocks)

                for i in 0..<numberOfBlocks {
                    var path = Path()
                    let color = colors[i % colors.count] // Cycle through colors

                    // Create a rectangular path for the band BEFORE rotation and translation
                    let bandRect = CGRect(x: -superRectWidth / 2,
                                          y: -superRectWidth / 2 + CGFloat(i) * bandHeight,
                                          width: superRectWidth,
                                          height: bandHeight)
                    path.addRect(bandRect)

                    // Rotate and then translate the path to the center of the view.
                    // The translation needs to be adjusted carefully if bands are not centered.
                    // For a full background, we might need to draw overlapping rotated rectangles.

                    // A simpler approach for distinct diagonal bands:
                    // Draw lines that define the edges of the bands.
                    // Start drawing from one corner (e.g., top-left) to the opposite edge.
                }


                // --- Simpler approach using clipping and filling rotated rectangles ---
                // This approach draws full rectangles and clips them.
                // For distinct diagonal bands, we need to define the band shapes more precisely.

                // --- Let's try defining each diagonal band as a shape (polygon) ---
                // This involves calculating the 4 corners of each parallelogram.

                let w = size.width
                let h = size.height
                let tanAngle = tan(CGFloat(angle.radians))

                // 'd' is the perpendicular distance between the dividing lines
                // This total "diagonal width" needs to cover the screen corners.
                // A rough estimate:
                let totalDiagonalLength = abs(w * cos(CGFloat(angle.radians))) + abs(h * sin(CGFloat(angle.radians)))
                                    + abs(w * sin(CGFloat(angle.radians))) + abs(h * cos(CGFloat(angle.radians)))
                let stripWidth = totalDiagonalLength / CGFloat(numberOfBlocks)


                for i in 0..<numberOfBlocks {
                    let color = colors[i % colors.count]
                    var path = Path()

                    // Define the four corners of the parallelogram for the current strip
                    // This requires careful geometric calculation based on the angle
                    // and the strip index. The lines are y = mx + c_i

                    // Point 1: (x, 0) -> (c_i / -m, 0) or (0, y) -> (0, c_i)
                    // Point 2: (x, h) -> ((h - c_i) / m, h) or (w, y) -> (w, mw + c_i)

                    // The lines separating the blocks can be described by:
                    // x * sin(angle) + y * cos(angle) = offset_k
                    // or y * sin(angle) + x * cos(angle) = offset_k depending on orientation

                    // Let's use a simplified approach: draw large rotated rectangles and clip.
                    // Or, draw paths that form triangles/trapezoids.

                    // For a line from (x1,y1) to (x2,y2)
                    // To fill a band, we need two parallel lines.
                    // Line equation: y = tan(angle) * x + c  (if angle is from positive x-axis)
                    // Or x = cot(angle) * y + c'

                    // Simplified: Offset lines and connect points on boundaries.
                    // 'offset' will be the intercept along an axis perpendicular to the lines.
                    // The lines are parallel to a line passing through origin at 'angle'.

                    // Total "width" along the perpendicular axis.
                    // Imagine projecting the rectangle's corners onto a line perpendicular to the diagonals.
                    // The distance between the min and max projection is this total width.
                    let p_axis_x = cos(CGFloat(angle.radians) + .pi/2)
                    let p_axis_y = sin(CGFloat(angle.radians) + .pi/2)

                    let corners = [CGPoint(x:0,y:0), CGPoint(x:w,y:0), CGPoint(x:w,y:h), CGPoint(x:0,y:h)]
                    let projections = corners.map { $0.x * p_axis_x + $0.y * p_axis_y }
                    let min_proj = projections.min()!
                    let max_proj = projections.max()!
                    let total_proj_width = max_proj - min_proj

                    let band_proj_width = total_proj_width / CGFloat(numberOfBlocks)

                    // Define the two separating lines for the current band i
                    // The "constant" for the line equation x*sin(A) + y*cos(A) = C
                    // can be derived from min_proj + CGFloat(i) * band_proj_width

                    // Line 1: p_axis_x * x + p_axis_y * y = min_proj + CGFloat(i) * band_proj_width
                    // Line 2: p_axis_x * x + p_axis_y * y = min_proj + CGFloat(i+1) * band_proj_width

                    // We need to find the intersection points of these two lines with the view boundaries
                    // (x=0, x=w, y=0, y=h) to form the polygon for the band.

                    let c1 = min_proj + CGFloat(i) * band_proj_width
                    let c2 = min_proj + CGFloat(i+1) * band_proj_width

                    // Get intersection points for line defined by p_axis_x * x + p_axis_y * y = C
                    func getIntersections(C: CGFloat) -> [CGPoint] {
                        var points: [CGPoint] = []
                        // Top edge (y=0)
                        if abs(p_axis_x) > 0.0001 { // Avoid division by zero if line is horizontal
                            let x = C / p_axis_x
                            if x >= 0 && x <= w { points.append(CGPoint(x: x, y: 0)) }
                        }
                        // Bottom edge (y=h)
                        if abs(p_axis_x) > 0.0001 {
                            let x = (C - p_axis_y * h) / p_axis_x
                            if x >= 0 && x <= w { points.append(CGPoint(x: x, y: h)) }
                        }
                        // Left edge (x=0)
                        if abs(p_axis_y) > 0.0001 { // Avoid division by zero if line is vertical
                            let y = C / p_axis_y
                            if y >= 0 && y <= h { points.append(CGPoint(x: 0, y: y)) }
                        }
                        // Right edge (x=w)
                        if abs(p_axis_y) > 0.0001 {
                            let y = (C - p_axis_x * w) / p_axis_y
                            if y >= 0 && y <= h { points.append(CGPoint(x: w, y: y)) }
                        }

                        // Sort points to ensure correct path drawing order (e.g., clockwise)
                        // This sorting is crucial and non-trivial for arbitrary polygons.
                        // For convex quadrilaterals formed by slicing a rect, sorting by angle around centroid works.
                        if points.count > 1 {
                            let centroid_x = points.reduce(0) { $0 + $1.x } / CGFloat(points.count)
                            let centroid_y = points.reduce(0) { $0 + $1.y } / CGFloat(points.count)
                            points.sort { p1, p2 in
                                atan2(p1.y - centroid_y, p1.x - centroid_x) <
                                atan2(p2.y - centroid_y, p2.x - centroid_x)
                            }
                        }
                        return points.uniqued() // Helper to remove duplicate points if edges coincide
                    }

                    let points1 = getIntersections(C: c1)
                    let points2 = getIntersections(C: c2)

                    // The band is the polygon formed by points from line1 and line2 on the boundary.
                    // Order them correctly: e.g., points1 in order, then points2 in reverse order.
                    var bandPoints = points1
                    bandPoints.append(contentsOf: points2.reversed())

                    if !bandPoints.isEmpty {
                        path.move(to: bandPoints.first!)
                        for k in 1..<bandPoints.count {
                            path.addLine(to: bandPoints[k])
                        }
                        path.closeSubpath()
                        context.fill(path, with: .color(color))
                    } else {
                        // Fallback: if specific band points aren't found (e.g., band is outside view for some reason)
                        // fill the whole area with the first color for bands that should be visible.
                        // This logic needs to be robust.
                        // For now, if a band has no points, it might mean it's entirely off-screen or an error.
                        // A simpler approach might be to draw large overlapping shapes.
                    }
                }
            }
            // Fallback if Canvas fails or for testing with a simpler method:
            // ZStack {
            //     ForEach(0..<colors.count, id: \.self) { i in
            //         // This is a very basic diagonal fill, not distinct blocks
            //         colors[i]
            //             .rotationEffect(angle, anchor: .center)
            //             .scaleEffect(1.5) // Scale to ensure coverage after rotation
            //             .offset(x: CGFloat(i - colors.count/2) * 50, y: CGFloat(i - colors.count/2) * 50) // Example offset
            //     }
            // }
            // .clipped() // Clip to the bounds of the GeometryReader
        }
        .edgesIgnoringSafeArea(.all) // Ensure it covers the entire screen
    }
}

// Helper to remove duplicate CGPoints (useful if lines intersect at corners)
extension Array where Element == CGPoint {
    func uniqued() -> [CGPoint] {
        var seen = Set<String>()
        return filter {
            let key = "\($0.x)-\($0.y)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
}
