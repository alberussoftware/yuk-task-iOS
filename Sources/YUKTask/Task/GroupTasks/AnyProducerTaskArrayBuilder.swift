//
//  AnyProducerTaskArrayBuilder.swift
//  YUKTask
//
//  Created by Ruslan Lutfullin on 2/11/21.
//

@resultBuilder
public struct AnyProducerTaskArrayBuilder {
  public static func buildBlock<O0, F0: Error>(_ t0: ProducerTask<O0, F0>) -> [AnyProducerTask] {
    [.init(t0)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>) -> [AnyProducerTask] {
    [.init(t0), .init(t1)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error, O16, F16: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>, _ t16: ProducerTask<O16, F16>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15), .init(t16)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error, O16, F16: Error, O17, F17: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>, _ t16: ProducerTask<O16, F16>, _ t17: ProducerTask<O17, F17>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15), .init(t16), .init(t17)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error, O16, F16: Error, O17, F17: Error, O18, F18: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>, _ t16: ProducerTask<O16, F16>, _ t17: ProducerTask<O17, F17>, _ t18: ProducerTask<O18, F18>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15), .init(t16), .init(t17), .init(t18)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error, O16, F16: Error, O17, F17: Error, O18, F18: Error, O19, F19: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>, _ t16: ProducerTask<O16, F16>, _ t17: ProducerTask<O17, F17>, _ t18: ProducerTask<O18, F18>, _ t19: ProducerTask<O19, F19>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15), .init(t16), .init(t17), .init(t18), .init(t19)]
  }
  public static func buildBlock<O0, F0: Error, O1, F1: Error, O2, F2: Error, O3, F3: Error, O4, F4: Error, O5, F5: Error, O6, F6: Error, O7, F7: Error, O8, F8: Error, O9, F9: Error, O10, F10: Error, O11, F11: Error, O12, F12: Error, O13, F13: Error, O14, F14: Error, O15, F15: Error, O16, F16: Error, O17, F17: Error, O18, F18: Error, O19, F19: Error, O20, F20: Error>(_ t0: ProducerTask<O0, F0>, _ t1: ProducerTask<O1, F1>, _ t2: ProducerTask<O2, F2>, _ t3: ProducerTask<O3, F3>, _ t4: ProducerTask<O4, F4>, _ t5: ProducerTask<O5, F5>, _ t6: ProducerTask<O6, F6>, _ t7: ProducerTask<O7, F7>, _ t8: ProducerTask<O8, F8>, _ t9: ProducerTask<O9, F9>, _ t10: ProducerTask<O10, F10>, _ t11: ProducerTask<O11, F11>, _ t12: ProducerTask<O12, F12>, _ t13: ProducerTask<O13, F13>, _ t14: ProducerTask<O14, F14>, _ t15: ProducerTask<O15, F15>, _ t16: ProducerTask<O16, F16>, _ t17: ProducerTask<O17, F17>, _ t18: ProducerTask<O18, F18>, _ t19: ProducerTask<O19, F19>, _ t20: ProducerTask<O20, F20>) -> [AnyProducerTask] {
    [.init(t0), .init(t1), .init(t2), .init(t3), .init(t4), .init(t5), .init(t6), .init(t7), .init(t8), .init(t9), .init(t10), .init(t11), .init(t12), .init(t13), .init(t14), .init(t15), .init(t16), .init(t17), .init(t18), .init(t19), .init(t20)]
  }
}
