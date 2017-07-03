import Foundation

func executeOnMainQueue(closure: @escaping () -> Void) {
  DispatchQueue.main.async(execute: closure)
}
