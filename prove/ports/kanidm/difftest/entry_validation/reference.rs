#![allow(dead_code,unused_variables,non_upper_case_globals)]
use std::{collections::{BTreeMap,BTreeSet},borrow::Borrow,fmt};
use super::candidate::{self,Error};
type Map<K,V> = BTreeMap<K,V>;
macro_rules! trace {($($x:tt)*)=>{}}
macro_rules! admin_debug {($($x:tt)*)=>{}}
macro_rules! admin_warn {($($x:tt)*)=>{}}
macro_rules! admin_error {($($x:tt)*)=>{}}
macro_rules! warn {($($x:tt)*)=>{}}
#[derive(Clone,Debug,PartialEq,Eq,PartialOrd,Ord)]
struct Attribute(u16);
impl Attribute {const Class:Self=Self(0);}
impl fmt::Display for Attribute {fn fmt(&self,f:&mut fmt::Formatter<'_>)->fmt::Result{write!(f,"z{:05}",self.0)}}
enum EntryClass {Conflict,Recycled,ExtensibleObject}
impl From<EntryClass> for String {fn from(c:EntryClass)->String{match c{EntryClass::Conflict=>"conflict",EntryClass::Recycled=>"recycled",EntryClass::ExtensibleObject=>"extensibleobject"}.into()}}
#[derive(Debug)]
enum SchemaError {NoClassFound,InvalidClass(Vec<String>),SupplementsNotSatisfied(Vec<String>),ExcludesNotSatisfied(Vec<String>),Corrupted,MissingMustAttribute(Vec<Attribute>),PhantomAttribute(String),InvalidAttribute(String),InvalidAttributeSyntax(String),AttributeNotValidForClass(String)}
struct ValueSet {classes:Option<BTreeSet<String>>,count:usize,syntax:u16,valid:bool}
impl ValueSet {fn len(&self)->usize{self.count} fn as_iutf8_set(&self)->Option<&BTreeSet<String>>{self.classes.as_ref()}}
struct SchemaAttribute {name:Attribute,phantom:bool,multi:bool,syntax:u16}
impl SchemaAttribute {
 fn validate_ava(&self,name:&Attribute,v:&ValueSet)->Result<(),SchemaError>{
 if (!self.multi && v.count>1) || self.syntax!=v.syntax || !v.valid {Err(SchemaError::InvalidAttributeSyntax(name.to_string()))}else{Ok(())}}
}
struct SchemaClass {systemmust:Vec<Attribute>,must:Vec<Attribute>,systemmay:Vec<Attribute>,may:Vec<Attribute>,systemsupplements:Vec<String>,supplements:Vec<String>,systemexcludes:Vec<String>,excludes:Vec<String>}
trait SchemaTransaction {fn get_classes(&self)->&BTreeMap<String,SchemaClass>;fn get_attributes(&self)->&BTreeMap<Attribute,SchemaAttribute>;}
struct Schema {classes:BTreeMap<String,SchemaClass>,attrs:BTreeMap<Attribute,SchemaAttribute>}
impl SchemaTransaction for Schema {fn get_classes(&self)->&BTreeMap<String,SchemaClass>{&self.classes}fn get_attributes(&self)->&BTreeMap<Attribute,SchemaAttribute>{&self.attrs}}
struct Entry {attrs:BTreeMap<Attribute,ValueSet>,class_present:bool}
impl Entry {
 fn attribute_pres(&self,_:Attribute)->bool{self.class_present}
 fn attribute_equality(&self,_:Attribute,pv:&String)->bool{self.attrs.get(&Attribute::Class).and_then(|v|v.classes.as_ref()).is_some_and(|s|s.contains(pv))}
 fn get_ava_set(&self,a:impl Borrow<Attribute>)->Option<&ValueSet>{self.attrs.get(a.borrow())}
    fn validate(&self, schema: &dyn SchemaTransaction) -> Result<(), SchemaError> {
        let schema_classes = schema.get_classes();
        let schema_attributes = schema.get_attributes();

        // Now validate it!
        trace!(?self.attrs, "Entry::validate -> target");

        // First, check we have class on the object ....
        if !self.attribute_pres(Attribute::Class) {
            // lrequest_error!("Missing attribute class");
            return Err(SchemaError::NoClassFound);
        }

        if self.attribute_equality(Attribute::Class, &EntryClass::Conflict.into()) {
            // Conflict entries are exempt from schema enforcement. Return true.
            trace!("Skipping schema validation on conflict entry");
            return Ok(());
        };

        // Are we in the recycle bin? We soften some checks if we are.
        let recycled = self.attribute_equality(Attribute::Class, &EntryClass::Recycled.into());

        // Do we have extensible? We still validate syntax of attrs but don't
        // check for valid object structures.
        let extensible =
            self.attribute_equality(Attribute::Class, &EntryClass::ExtensibleObject.into());

        let entry_classes = self.get_ava_set(Attribute::Class).ok_or_else(|| {
            admin_debug!("Attribute '{}' missing from entry", Attribute::Class);
            SchemaError::NoClassFound
        })?;
        let mut invalid_classes = Vec::with_capacity(0);

        let mut classes: Vec<&SchemaClass> = Vec::with_capacity(entry_classes.len());

        // We need to keep the btreeset of entry classes here so we can check the
        // requires and excludes.
        let entry_classes = if let Some(ec) = entry_classes.as_iutf8_set() {
            ec.iter()
                .for_each(|s| match schema_classes.get(s.as_str()) {
                    Some(x) => classes.push(x),
                    None => {
                        admin_debug!("invalid class: {:?}", s);
                        invalid_classes.push(s.to_string())
                    }
                });
            ec
        } else {
            admin_debug!("corrupt class attribute");
            return Err(SchemaError::NoClassFound);
        };

        if !invalid_classes.is_empty() {
            return Err(SchemaError::InvalidClass(invalid_classes));
        };

        // Now determine the set of excludes and requires we have, and then
        // assert we don't violate them.

        let supplements_classes: Vec<_> = classes
            .iter()
            .flat_map(|cls| cls.systemsupplements.iter().chain(cls.supplements.iter()))
            .collect();

        // So long as one supplement is present we can continue.
        let valid_supplements = if supplements_classes.is_empty() {
            // No need to check.
            true
        } else {
            supplements_classes
                .iter()
                .any(|class| entry_classes.contains(class.as_str()))
        };

        if !valid_supplements {
            warn!(
                "Validation error, the following possible supplement classes are missing - {:?}",
                supplements_classes
            );
            let supplements_classes = supplements_classes.iter().map(|s| s.to_string()).collect();
            return Err(SchemaError::SupplementsNotSatisfied(supplements_classes));
        }

        let excludes_classes: Vec<_> = classes
            .iter()
            .flat_map(|cls| cls.systemexcludes.iter().chain(cls.excludes.iter()))
            .collect();

        let mut invalid_excludes = Vec::with_capacity(0);

        excludes_classes.iter().for_each(|class| {
            if entry_classes.contains(class.as_str()) {
                invalid_excludes.push(class.to_string())
            }
        });

        if !invalid_excludes.is_empty() {
            admin_warn!(
                "Validation error, the following excluded classes are present - {:?}",
                invalid_excludes
            );
            return Err(SchemaError::ExcludesNotSatisfied(invalid_excludes));
        }

        // What this is really doing is taking a set of classes, and building an
        // "overall" class that describes this exact object for checking. IE we
        // build a super must/may set from the small class must/may sets.

        //   for each class
        //      add systemmust/must and systemmay/may to their lists
        //      add anything from must also into may

        // Now from the set of valid classes make a list of must/may
        //
        // NOTE: We still need this on extensible, because we still need to satisfy
        // our other must conditions as well!
        let must: Result<Vec<&SchemaAttribute>, _> = classes
            .iter()
            // Join our class systemmmust + must into one iter
            .flat_map(|cls| cls.systemmust.iter().chain(cls.must.iter()))
            .map(|s| {
                // This should NOT fail - if it does, it means our schema is
                // in an invalid state!
                schema_attributes.get(s).ok_or(SchemaError::Corrupted)
            })
            .collect();

        let must = must?;

        // Check that all must are inplace
        //   for each attr in must, check it's present on our ent
        let mut missing_must = Vec::with_capacity(0);
        for attr in must.iter() {
            let avas = self.get_ava_set(&attr.name);
            if avas.is_none() {
                missing_must.push(attr.name.clone());
            }
        }

        if !missing_must.is_empty() {
            admin_warn!(
                "Validation error, the following required ({}) (must) attributes are missing - {:?}",
                self.get_display_id(), missing_must
            );
            // We if are in the recycle bin, we don't hard error here. This can occur when
            // a migration occurs and we delete an acp, and then the related group. Because
            // this would trigger refint which purges the acp_receiver_group, then this
            // must value becomes unsatisfiable. So here we soften the check for recycled
            // entries because they are in a "nebulous" state anyway.
            if !recycled {
                return Err(SchemaError::MissingMustAttribute(missing_must));
            }
        }

        if extensible {
            self.attrs.iter().try_for_each(|(attr_name, avas)| {
                    match schema_attributes.get(attr_name) {
                        Some(a_schema) => {
                            // Now, for each type we do a *full* check of the syntax
                            // and validity of the ava.
                            if a_schema.phantom {
                                admin_warn!(
                                    "Rejecting attempt to add phantom attribute to extensible object: {}",
                                    attr_name
                                );
                                Err(SchemaError::PhantomAttribute(attr_name.to_string()))
                            } else {
                                a_schema.validate_ava(attr_name, avas)
                                // .map_err(|e| lrequest_error!("Failed to validate: {}", attr_name);)
                            }
                        }
                        None => {
                            admin_error!(
                                "Invalid Attribute {}, undefined in schema_attributes",
                                attr_name.to_string()
                            );
                            Err(SchemaError::InvalidAttribute(
                                attr_name.to_string()
                            ))
                        }
                    }
                })?;
        } else {
            // Note - we do NOT need to check phantom attributes here because they are
            // not allowed to exist in the class, which means a phantom attribute can't
            // be in the may/must set, and would FAIL our normal checks anyway.

            // The set of "may" is a combination of may and must, since we have already
            // asserted that all must requirements are fulfilled. This allows us to
            // perform extended attribute checking in a single pass.
            let may: Result<Map<&Attribute, &SchemaAttribute>, _> = classes
                .iter()
                // Join our class systemmmust + must + systemmay + may into one.
                .flat_map(|cls| {
                    trace!(?cls);
                    cls.systemmust
                        .iter()
                        .chain(cls.must.iter())
                        .chain(cls.systemmay.iter())
                        .chain(cls.may.iter())
                })
                .map(|s| {
                    // This should NOT fail - if it does, it means our schema is
                    // in an invalid state!
                    Ok((s, schema_attributes.get(s).ok_or(SchemaError::Corrupted)?))
                })
                .collect();

            let may = may?;

            // TODO #70: Error needs to say what is missing
            // We need to return *all* missing attributes, not just the first error
            // we find. This will probably take a rewrite of the function definition
            // to return a result<_, vec<schemaerror>> and for the schema errors to take
            // information about what is invalid. It's pretty nontrivial.

            // Check that any other attributes are in may
            //   for each attr on the object, check it's in the may+must set
            self.attrs.iter().try_for_each(|(attr_name, avas)| {
                    match may.get(attr_name) {
                        Some(a_schema) => {
                            // Now, for each type we do a *full* check of the syntax
                            // and validity of the ava.
                            a_schema.validate_ava(attr_name, avas)
                            // .map_err(|e| lrequest_error!("Failed to validate: {}", attr_name);
                        }
                        None => {
                            admin_error!(
                                "{} {} - not found in the list of valid attributes for this set of classes {:?} - valid attributes are {:?}",

                                attr_name.as_str(),
                                self.get_display_id(),
                                entry_classes.iter().collect::<Vec<_>>(),
                                may.keys().collect::<Vec<_>>()
                            );
                            Err(SchemaError::AttributeNotValidForClass(
                                attr_name.to_string()
                            ))
                        }
                    }
                })?;
        }

        // Well, we got here, so okay!
        Ok(())
    }
}
fn class_name(n:u16)->String{match n{0=>"conflict".into(),1=>"extensibleobject".into(),2=>"recycled".into(),_=>format!("z{n:05}")}}
fn class_id(s:String)->u16{match s.as_str(){"conflict"=>0,"extensibleobject"=>1,"recycled"=>2,_=>s[1..].parse().unwrap()}}
fn attr_id(s:String)->u16{s[1..].parse().unwrap()}
fn error(e:SchemaError)->Error {match e{
 SchemaError::NoClassFound=>Error::NoClassFound,SchemaError::Corrupted=>Error::Corrupted,
 SchemaError::InvalidClass(v)=>Error::InvalidClass(v.into_iter().map(class_id).collect()),
 SchemaError::SupplementsNotSatisfied(v)=>Error::SupplementsNotSatisfied(v.into_iter().map(class_id).collect()),
 SchemaError::ExcludesNotSatisfied(v)=>Error::ExcludesNotSatisfied(v.into_iter().map(class_id).collect()),
 SchemaError::MissingMustAttribute(v)=>Error::MissingMustAttribute(v.into_iter().map(|a|a.0).collect()),
 SchemaError::PhantomAttribute(s)=>Error::PhantomAttribute(attr_id(s)),
 SchemaError::InvalidAttribute(s)=>Error::InvalidAttribute(attr_id(s)),
 SchemaError::InvalidAttributeSyntax(s)=>Error::InvalidAttributeSyntax(attr_id(s)),
 SchemaError::AttributeNotValidForClass(s)=>Error::AttributeNotValidForClass(attr_id(s))}}
pub fn validate(e:&candidate::Entry,classes:&[candidate::ClassSchema],attrs:&[candidate::AttributeSchema])->Result<(),Error>{
 let schema=Schema {classes:classes.iter().map(|c|(class_name(c.key),SchemaClass {
 systemmust:c.systemmust.iter().copied().map(Attribute).collect(),must:c.must.iter().copied().map(Attribute).collect(),
 systemmay:c.systemmay.iter().copied().map(Attribute).collect(),may:c.may.iter().copied().map(Attribute).collect(),
 systemsupplements:c.systemsupplements.iter().copied().map(class_name).collect(),supplements:c.supplements.iter().copied().map(class_name).collect(),
 systemexcludes:c.systemexcludes.iter().copied().map(class_name).collect(),excludes:c.excludes.iter().copied().map(class_name).collect()})).collect(),
 attrs:attrs.iter().map(|a|(Attribute(a.key),SchemaAttribute{name:Attribute(a.name),phantom:a.phantom,multi:a.multi,syntax:a.syntax})).collect()};
 let entry=Entry {class_present:e.class_present,attrs:e.attrs.iter().map(|a|(Attribute(a.key),ValueSet {
 classes:if a.key==0{e.classes.as_ref().map(|v|v.iter().copied().map(class_name).collect())}else{None},count:a.count,syntax:a.syntax,valid:a.valid})).collect()};
 entry.validate(&schema).map_err(error)
}
