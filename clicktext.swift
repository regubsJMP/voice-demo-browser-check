// Find a piece of text on a screenshot (macOS Vision OCR) and print the screen point of its centre — so the runner can click real
// buttons (browser permission prompts, page buttons) with cliclick without hard-coded coordinates.
//   clicktext <screenshot.png> "<text>"   → "x y" in screen points (exit 1 if not found)
// An observation that equals the text exactly wins over one that only contains it (a page may say "please click Allow" next to the
// real "Allow" button).
import AppKit
import Foundation
import Vision

let args = CommandLine.arguments
guard args.count >= 3, let img = NSImage(contentsOfFile: args[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { exit(2) }
let target = args[2].lowercased()
let req = VNRecognizeTextRequest()
req.recognitionLevel = .accurate
req.usesLanguageCorrection = false
try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req])
let scale = Double(NSScreen.main?.backingScaleFactor ?? 1)
let W = Double(cg.width) / scale, H = Double(cg.height) / scale
var exact: CGRect? = nil, partial: CGRect? = nil
for obs in req.results ?? [] {
    guard let cand = obs.topCandidates(1).first else { continue }
    let s = cand.string.trimmingCharacters(in: .whitespaces).lowercased()
    if s == target, exact == nil { exact = obs.boundingBox }
    else if partial == nil, let r = cand.string.lowercased().range(of: target), let box = try? cand.boundingBox(for: r) { partial = box.boundingBox }
}
guard let bb = exact ?? partial else { exit(1) }
print(String(format: "%.0f %.0f", bb.midX * W, (1 - bb.midY) * H))
