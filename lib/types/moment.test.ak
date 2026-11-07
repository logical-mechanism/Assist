//// Property-based tests for `types/moment`.

use aiken/fuzz
use aiken/interval.{
  Finite, Interval, IntervalBound, IntervalBoundType, NegativeInfinity,
  PositiveInfinity,
}
use cardano/transaction.{ValidityRange}
use types/moment.{Moment}

// ## Fuzzers

/// A logical moment: non-negative and not ending before it starts.
fn logical_moment() -> Fuzzer<Moment> {
  let start <- fuzz.and_then(fuzz.int_between(0, 1000))
  let length <- fuzz.map(fuzz.int_between(0, 1000))
  Moment { start, end: start + length }
}

fn any_moment() -> Fuzzer<Moment> {
  fuzz.map2(
    fuzz.int_between(-1000, 1000),
    fuzz.int_between(-1000, 1000),
    fn(start, end) { Moment { start, end } },
  )
}

fn bound_type() -> Fuzzer<IntervalBoundType> {
  fuzz.either3(
    fuzz.map(fuzz.int_between(0, 2500), Finite),
    fuzz.map(fuzz.int_between(0, 2500), Finite),
    fuzz.one_of([NegativeInfinity, PositiveInfinity]),
  )
}

fn bound() -> Fuzzer<IntervalBound> {
  fuzz.map2(
    bound_type(),
    fuzz.bool(),
    fn(bound_type, is_inclusive) { IntervalBound { bound_type, is_inclusive } },
  )
}

/// Any validity range, finite or not, inclusive or not.
fn validity_range() -> Fuzzer<ValidityRange> {
  fuzz.map2(
    bound(),
    bound(),
    fn(lower_bound, upper_bound) { Interval { lower_bound, upper_bound } },
  )
}

/// A logical moment and a non-empty, finite, inclusive range whose ends land
/// on or right next to the moment's own ends half of the time, so that the
/// boundary comparisons are exercised.
fn moment_and_range() -> Fuzzer<(Moment, (Int, Int))> {
  let m <- fuzz.and_then(logical_moment())
  let near = fn(anchor) {
    fuzz.map(fuzz.int_between(-1, 1), fn(d) { anchor + d })
  }
  let lower <- fuzz.and_then(
    fuzz.either3(near(m.start), near(m.end), fuzz.int_between(0, 2500)),
  )
  let upper <- fuzz.map(
    fuzz.either3(
      near(m.start),
      near(m.end),
      fuzz.int_between(lower, lower + 500),
    ),
  )
  if upper < lower {
    (m, (upper, lower))
  } else {
    (m, (lower, upper))
  }
}

fn is_finite(vr: ValidityRange) -> Bool {
  when (vr.lower_bound.bound_type, vr.upper_bound.bound_type) is {
    (Finite(_), Finite(_)) -> True
    _ -> False
  }
}

// ## Properties

test prop_shift_round_trips(
  input via fuzz.tuple(any_moment(), fuzz.int_between(-10_000, 10_000)),
) {
  let (m, t) = input
  moment.shift(moment.shift(m, t), -t) == m
}

test prop_shift_keeps_the_length(
  input via fuzz.tuple(any_moment(), fuzz.int_between(-10_000, 10_000)),
) {
  let (m, t) = input
  let shifted = moment.shift(m, t)
  shifted.end - shifted.start == m.end - m.start
}

test prop_is_logical_spec(m via any_moment()) {
  let result = moment.is_logical(m)
  fuzz.label_when(result, @"logical", @"not logical")
  result == ( m.start >= 0 && m.start <= m.end )
}

test prop_is_contained_spec(input via moment_and_range()) {
  let (m, (lower, upper)) = input
  let result = moment.is_contained(m, interval.between(lower, upper))
  fuzz.label_when(result, @"contained", @"not contained")
  result == ( m.start <= lower && upper <= m.end )
}

test prop_is_after_spec(input via moment_and_range()) {
  let (m, (lower, upper)) = input
  let result = moment.is_after(m, interval.between(lower, upper))
  fuzz.label_when(result, @"after", @"not after")
  result == ( m.end < lower )
}

test prop_is_before_spec(input via moment_and_range()) {
  let (m, (lower, upper)) = input
  let result = moment.is_before(m, interval.between(lower, upper))
  fuzz.label_when(result, @"before", @"not before")
  result == ( upper < m.start )
}

test prop_positions_are_mutually_exclusive(input via moment_and_range()) {
  let (m, (lower, upper)) = input
  let vr = interval.between(lower, upper)
  let contained = moment.is_contained(m, vr)
  let after = moment.is_after(m, vr)
  let before = moment.is_before(m, vr)
  !(contained && after) && !(contained && before) && !(after && before)
}

test prop_stricter_than_stdlib_intervals(
  input via fuzz.tuple(logical_moment(), validity_range()),
) {
  // every check that passes here also passes with stdlib's interval logic
  let (m, vr) = input
  and {
    !moment.is_contained(m, vr) || interval.includes(
      interval.between(m.start, m.end),
      vr,
    ),
    !moment.is_after(m, vr) || interval.is_entirely_after(vr, m.end),
    !moment.is_before(m, vr) || interval.is_entirely_before(vr, m.start),
  }
}

test prop_infinite_ranges_are_never_contained(
  input via fuzz.tuple(logical_moment(), validity_range()),
) {
  let (m, vr) = input
  is_finite(vr) || !moment.is_contained(m, vr)
}
