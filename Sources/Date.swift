/*
 * Copyright 2016 JD Fergason
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

private var rfc3339fractionalformatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSSSSZZZZZ"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.calendar = Calendar(identifier: .iso8601)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter
}()

private var rfc3339formatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"
  formatter.timeZone = TimeZone(secondsFromGMT: 0)
  formatter.calendar = Calendar(identifier: .iso8601)
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter
}()

private func localTimeOffset() -> String {
    let totalSeconds: Int = TimeZone.current.secondsFromGMT()
    let minutes: Int = (totalSeconds / 60) % 60
    let hours: Int = totalSeconds / 3600
    return String(format: "%02d%02d", hours, minutes)
 }

extension Date {
  // rfc3339 w fractional seconds w/ time offset
  init?(rfc3339FractionalSecondsFormattedString: String) {
    if let d = rfc3339fractionalformatter.date(from: rfc3339FractionalSecondsFormattedString) {
      self.init(timeInterval: 0, since: d)
    } else {
      return nil
    }
  }

  // rfc3339 w fractional seconds w/o time offset
  init?(rfc3339LocalFractionalSecondsFormattedString: String) {
    if let d = rfc3339fractionalformatter.date(
      from: rfc3339LocalFractionalSecondsFormattedString + localTimeOffset()) {
      self.init(timeInterval: 0, since: d)
    } else {
      return nil
    }
  }

  // rfc3339 w/o fractional seconds w/ time offset
  init?(rfc3339FormattedString: String) {
    if let d = rfc3339formatter.date(from: rfc3339FormattedString) {
      self.init(timeInterval: 0, since: d)
    } else {
      return nil
    }
  }

  // rfc3339 w/o fractional seconds w/o time offset
  init?(rfc3339LocalFormattedString: String) {
    if let d = rfc3339formatter.date(from: rfc3339LocalFormattedString + localTimeOffset()) {
      self.init(timeInterval: 0, since: d)
    } else {
      return nil
    }
  }
}
