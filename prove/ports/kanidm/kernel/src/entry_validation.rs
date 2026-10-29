//! Complete Entry::validate decision at f608c4f with interned identifiers.
//! Vectors representing maps/sets must be sorted and unique by key.
//! Intrinsic ValueSet validation is an explicit supplied Boolean boundary.
use crate::schema_tags;
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Attribute {
    pub key: u16,
    pub count: usize,
    pub syntax: u16,
    pub valid: bool,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AttributeSchema {
    pub key: u16,
    pub name: u16,
    pub phantom: bool,
    pub multi: bool,
    pub syntax: u16,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ClassSchema {
    pub key: u16,
    pub systemmust: Vec<u16>,
    pub must: Vec<u16>,
    pub systemmay: Vec<u16>,
    pub may: Vec<u16>,
    pub systemsupplements: Vec<u16>,
    pub supplements: Vec<u16>,
    pub systemexcludes: Vec<u16>,
    pub excludes: Vec<u16>,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Entry {
    pub class_present: bool,
    pub classes: Option<Vec<u16>>,
    pub attrs: Vec<Attribute>,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Error {
    NoClassFound,
    InvalidClass(Vec<u16>),
    SupplementsNotSatisfied(Vec<u16>),
    ExcludesNotSatisfied(Vec<u16>),
    Corrupted,
    MissingMustAttribute(Vec<u16>),
    PhantomAttribute(u16),
    InvalidAttribute(u16),
    InvalidAttributeSyntax(u16),
    AttributeNotValidForClass(u16),
}
pub fn contains(xs: &[u16], key: u16) -> bool {
    let mut i = 0;
    while i < xs.len() {
        if xs[i] == key {
            return true;
        }
        i += 1
    }
    false
}
pub fn class_index(xs: &[ClassSchema], key: u16) -> Option<usize> {
    let mut i = 0;
    while i < xs.len() {
        if xs[i].key == key {
            return Some(i);
        }
        i += 1
    }
    None
}
pub fn attribute_index(xs: &[AttributeSchema], key: u16) -> Option<usize> {
    let mut i = 0;
    while i < xs.len() {
        if xs[i].key == key {
            return Some(i);
        }
        i += 1
    }
    None
}
pub fn present(xs: &[Attribute], key: u16) -> bool {
    let mut i = 0;
    while i < xs.len() {
        if xs[i].key == key {
            return true;
        }
        i += 1
    }
    false
}
fn append(out: &mut Vec<u16>, xs: &[u16]) {
    let mut i = 0;
    while i < xs.len() {
        out.push(xs[i]);
        i += 1
    }
}
fn class_constraints(c: &ClassSchema, kind: u8) -> Vec<u16> {
    let mut out = Vec::new();
    if kind == 0 {
        append(&mut out, &c.systemsupplements);
        append(&mut out, &c.supplements)
    } else if kind == 1 {
        append(&mut out, &c.systemexcludes);
        append(&mut out, &c.excludes)
    } else {
        append(&mut out, &c.systemmust);
        append(&mut out, &c.must);
        if kind == 3 {
            append(&mut out, &c.systemmay);
            append(&mut out, &c.may)
        }
    }
    out
}
/// Ordered flat_map of class constraints. All classes have already been checked.
pub fn constraints(classes: &[ClassSchema], names: &[u16], kind: u8) -> Vec<u16> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < names.len() {
        if let Some(j) = class_index(classes, names[i]) {
            let one = class_constraints(&classes[j], kind);
            append(&mut out, &one);
        }
        i += 1
    }
    out
}
pub fn invalid_classes(classes: &[ClassSchema], names: &[u16]) -> Vec<u16> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < names.len() {
        if class_index(classes, names[i]).is_none() {
            out.push(names[i])
        }
        i += 1
    }
    out
}
pub fn overlap(xs: &[u16], ys: &[u16]) -> Vec<u16> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < xs.len() {
        if contains(ys, xs[i]) {
            out.push(xs[i])
        }
        i += 1
    }
    out
}
pub fn schema_complete(attrs: &[AttributeSchema], names: &[u16]) -> bool {
    let mut i = 0;
    while i < names.len() {
        if attribute_index(attrs, names[i]).is_none() {
            return false;
        }
        i += 1
    }
    true
}
pub fn missing_attributes(entry: &Entry, attrs: &[AttributeSchema], must: &[u16]) -> Vec<u16> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < must.len() {
        if let Some(j) = attribute_index(attrs, must[i]) {
            if !present(&entry.attrs, attrs[j].name) {
                out.push(attrs[j].name)
            }
        }
        i += 1
    }
    out
}
pub fn validate_attribute(
    ava: &Attribute,
    attrs: &[AttributeSchema],
    may: &[u16],
    extensible: bool,
) -> Result<(), Error> {
    if !extensible && !contains(may, ava.key) {
        return Err(Error::AttributeNotValidForClass(ava.key));
    }
    let j = match attribute_index(attrs, ava.key) {
        None => {
            return Err(if extensible {
                Error::InvalidAttribute(ava.key)
            } else {
                Error::Corrupted
            })
        }
        Some(j) => j,
    };
    let a = &attrs[j];
    if extensible && a.phantom {
        return Err(Error::PhantomAttribute(ava.key));
    }
    if !schema_tags::ava_accepts(a.multi, ava.count, a.syntax, ava.syntax, ava.valid) {
        return Err(Error::InvalidAttributeSyntax(ava.key));
    }
    Ok(())
}
pub fn validate_attributes(
    entry: &Entry,
    attrs: &[AttributeSchema],
    may: &[u16],
    extensible: bool,
) -> Result<(), Error> {
    let mut i = 0;
    while i < entry.attrs.len() {
        validate_attribute(&entry.attrs[i], attrs, may, extensible)?;
        i += 1
    }
    Ok(())
}
pub fn validate(
    entry: &Entry,
    classes: &[ClassSchema],
    attrs: &[AttributeSchema],
) -> Result<(), Error> {
    if !entry.class_present {
        return Err(Error::NoClassFound);
    }
    // Class IDs: conflict=0,extensibleobject=1,recycled=2; other IDs arbitrary.
    if let Some(names) = &entry.classes {
        if contains(names, 0) {
            return Ok(());
        }
    }
    let names = match &entry.classes {
        None => return Err(Error::NoClassFound),
        Some(n) => n,
    };
    let recycled = contains(names, 2);
    let extensible = contains(names, 1);
    let invalid = invalid_classes(classes, names);
    if !(invalid.len() == 0) {
        return Err(Error::InvalidClass(invalid));
    }
    let supplements = constraints(classes, names, 0);
    if !(supplements.len() == 0) && (overlap(&supplements, names).len() == 0) {
        return Err(Error::SupplementsNotSatisfied(supplements));
    }
    let excluded = overlap(&constraints(classes, names, 1), names);
    if !(excluded.len() == 0) {
        return Err(Error::ExcludesNotSatisfied(excluded));
    }
    let must = constraints(classes, names, 2);
    // Complete schema lookup precedes missing-attribute errors, even for recycled entries.
    if !schema_complete(attrs, &must) {
        return Err(Error::Corrupted);
    }
    let missing = missing_attributes(entry, attrs, &must);
    if !(missing.len() == 0) && !recycled {
        return Err(Error::MissingMustAttribute(missing));
    }
    if extensible {
        validate_attributes(entry, attrs, &[], true)
    } else {
        let may = constraints(classes, names, 3);
        if !schema_complete(attrs, &may) {
            return Err(Error::Corrupted);
        }
        validate_attributes(entry, attrs, &may, false)
    }
}
