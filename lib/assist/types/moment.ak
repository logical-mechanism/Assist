use aiken/interval.{
  Finite, Interval, IntervalBound, NegativeInfinity, PositiveInfinity,
}
use aiken/transaction.{ValidityRange}

/// A finite moment of time represented as simple start and end integers.
pub type Moment {
  start: Int,
  end: Int,
}

/// Check if a moment data structure is logical. 
///
/// ```aiken
/// moment.is_logical(datum.moment)
/// ```
pub fn is_logical(m: Moment) -> Bool {
  and {
    m.end >= m.start,
    m.start >= 0,
    m.end >= 0,
  }
}

test an_empty_moment() {
  let m: Moment = Moment { start: 0, end: 0 }
  is_logical(m) == True
}

test a_nonvalid_moment() {
  let m: Moment = Moment { start: 10, end: 0 }
  is_logical(m) == False
}

test a_valid_moment() {
  let m: Moment = Moment { start: 10, end: 11230 }
  is_logical(m) == True
}

/// Check if a moment is contained within some validity range of a tx.
/// This assumes inclusivity.
///
/// ```aiken
/// moment.is_contained(datum.moment, this_tx.validity_range)
/// ```
pub fn is_contained(m: Moment, vr: ValidityRange) -> Bool {
  when vr.lower_bound.bound_type is {
    // must be finite
    NegativeInfinity -> False
    // get the lower bound int
    Finite(lower_bound) ->
      when vr.upper_bound.bound_type is {
        // must be finite
        NegativeInfinity -> False
        // get the upper bound int
        Finite(upper_bound) -> and {
            // the lower bound is less than or equal the start of the momement
            lower_bound <= m.start,
            // the upper bound is greater or equal to the end of the momment
            upper_bound >= m.end,
          }
        // must be finite
        PositiveInfinity -> False
      }
    // must be finite
    PositiveInfinity -> False
  }
}

test an_empty_moment_is_not_contained_in_infinty() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound {
        bound_type: NegativeInfinity,
        is_inclusive: True,
      },
      upper_bound: IntervalBound {
        bound_type: PositiveInfinity,
        is_inclusive: True,
      },
    }
  let m: Moment = Moment { start: 0, end: 0 }
  // the bounds can not be infinite
  is_contained(m, vr) == False
}

test an_empty_moment_is_contained_in_a_finite_range() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(-10), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
    }
  let m: Moment = Moment { start: 0, end: 0 }
  is_contained(m, vr) == True
}

test a_moment_is_contained_in_the_validity_range() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(0), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
    }
  let m: Moment = Moment { start: 0, end: 10 }
  is_contained(m, vr) == True
}

/// Check if a validity range of a tx is after a moment.
/// This assumes exclusivity.
///
/// ```aiken
/// moment.is_after(datum.moment, this_tx.validity_range)
/// ```
pub fn is_after(m: Moment, vr: ValidityRange) -> Bool {
  when vr.lower_bound.bound_type is {
    // must be finite
    NegativeInfinity -> False
    // get the lower bound int
    Finite(lower_bound) -> m.end < lower_bound
    // must be finite
    PositiveInfinity -> False
  }
}

test a_validity_range_is_after_a_moment() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(5), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
    }
  let m: Moment = Moment { start: 1, end: 4 }
  is_after(m, vr) == True
}

test a_validity_range_is_not_after_a_moment() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(0), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
    }
  let m: Moment = Moment { start: 1, end: 13 }
  is_after(m, vr) == False
}

/// Check if a validity range of a tx is before a moment.
/// This assumes exclusivity.
///
/// ```aiken
/// moment.is_before(datum.moment, this_tx.validity_range)
/// ```
pub fn is_before(m: Moment, vr: ValidityRange) -> Bool {
  when vr.upper_bound.bound_type is {
    // must be finite
    NegativeInfinity -> False
    // get the upper bound int
    Finite(upper_bound) -> upper_bound < m.start
    // must be finite
    PositiveInfinity -> False
  }
}

test a_validity_range_is_before_a_moment() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(0), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
    }
  let m: Moment = Moment { start: 11, end: 13 }
  is_before(m, vr) == True
}

test a_validity_range_is_not_before_a_moment() {
  let vr: ValidityRange =
    Interval {
      lower_bound: IntervalBound { bound_type: Finite(10), is_inclusive: True },
      upper_bound: IntervalBound { bound_type: Finite(12), is_inclusive: True },
    }
  let m: Moment = Moment { start: 11, end: 13 }
  is_before(m, vr) == False
}
