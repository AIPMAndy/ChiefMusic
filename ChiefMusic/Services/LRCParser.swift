import Foundation

struct LRCParser {
    /// Parse LRC format lyrics
    /// Format: [mm:ss.xx] text
    static func parse(_ content: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"\[(\d{2}):(\d{2})\.?(\d{0,3})\](.+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            
            guard let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let minuteRange = Range(match.range(at: 1), in: line),
                  let secondRange = Range(match.range(at: 2), in: line),
                  let msRange = Range(match.range(at: 3), in: line),
                  let textRange = Range(match.range(at: 4), in: line) else {
                continue
            }
            
            let minuteStr = String(line[minuteRange])
            let secondStr = String(line[secondRange])
            let msStr = String(line[msRange])
            let text = String(line[textRange]).trimmingCharacters(in: .whitespaces)
            
            guard let mins = Double(minuteStr), let secs = Double(secondStr) else { continue }
            let ms: Double
            if msStr.isEmpty {
                ms = 0
            } else if let msVal = Double(msStr) {
                ms = msVal / pow(10, Double(msStr.count))
            } else {
                ms = 0
            }
            
            let time = mins * 60 + secs + ms
            lines.append(LyricLine(time: time, text: text))
        }
        
        return lines.sorted { $0.time < $1.time }
    }
}
