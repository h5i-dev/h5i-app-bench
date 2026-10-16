
// ---- Test seam (not upstream): `FilterComp` is private; build it from a
// public mirror. ----

#[derive(Clone, Debug)]
pub enum DFilter {
    Eq(Attribute, PartialValue),
    Cnt(Attribute, PartialValue),
    Stw(Attribute, PartialValue),
    Enw(Attribute, PartialValue),
    Pres(Attribute),
    LessThan(Attribute, PartialValue),
    Or(Vec<DFilter>),
    And(Vec<DFilter>),
    Inclusion(Vec<DFilter>),
    AndNot(Box<DFilter>),
    SelfUuid,
    Invalid(Attribute),
}

fn dfc(f: DFilter) -> FilterComp {
    match f {
        DFilter::Eq(a, v) => FilterComp::Eq(a, v),
        DFilter::Cnt(a, v) => FilterComp::Cnt(a, v),
        DFilter::Stw(a, v) => FilterComp::Stw(a, v),
        DFilter::Enw(a, v) => FilterComp::Enw(a, v),
        DFilter::Pres(a) => FilterComp::Pres(a),
        DFilter::LessThan(a, v) => FilterComp::LessThan(a, v),
        DFilter::Or(l) => FilterComp::Or(l.into_iter().map(dfc).collect()),
        DFilter::And(l) => FilterComp::And(l.into_iter().map(dfc).collect()),
        DFilter::Inclusion(l) => FilterComp::Inclusion(l.into_iter().map(dfc).collect()),
        DFilter::AndNot(b) => FilterComp::AndNot(Box::new(dfc(*b))),
        DFilter::SelfUuid => FilterComp::SelfUuid,
        DFilter::Invalid(a) => FilterComp::Invalid(a),
    }
}

impl Filter<FilterValid> {
    pub fn difftest_new(f: DFilter) -> Self {
        Filter { state: FilterValid { inner: dfc(f) } }
    }
}
