//
//  Optional+Additive.swift
//  TeXMaker
//
//  Created by 孟超 on 2025/1/15.
//

extension Optional where Wrapped: AdditiveArithmetic {
    static func + (_ lhs: Self, rhs: Wrapped) -> Wrapped {
        (lhs ?? .zero) + rhs
    }
    static func + (_ lhs: Wrapped, rhs: Self) -> Wrapped {
        lhs + (rhs ?? .zero)
    }
    static func + (_ lhs: Self, rhs: Self) -> Wrapped {
        (lhs ?? .zero) + (rhs ?? .zero)
    }
}
