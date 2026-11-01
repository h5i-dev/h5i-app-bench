#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SamplerChoice {AlwaysOn,AlwaysOff,TraceIdRatio,ParentBasedAlwaysOn,ParentBasedAlwaysOff,ParentBasedTraceIdRatio}
impl SamplerChoice {
    fn name(self) -> &'static str {
        match self {
            Self::AlwaysOn => "always_on",
            Self::AlwaysOff => "always_off",
            Self::TraceIdRatio => "traceidratio",
            Self::ParentBasedAlwaysOn => "parentbased_always_on",
            Self::ParentBasedAlwaysOff => "parentbased_always_off",
            Self::ParentBasedTraceIdRatio => "parentbased_traceidratio",
        }
    }
    /// Whether this choice consults `OTEL_TRACES_SAMPLER_ARG`.
    fn uses_ratio(self) -> bool {
        matches!(self, Self::TraceIdRatio | Self::ParentBasedTraceIdRatio)
    }
}
fn main(){
println!("name/AlwaysOn\t{:?}",SamplerChoice::AlwaysOn.name().as_bytes());
println!("name/AlwaysOff\t{:?}",SamplerChoice::AlwaysOff.name().as_bytes());
println!("name/TraceIdRatio\t{:?}",SamplerChoice::TraceIdRatio.name().as_bytes());
println!("name/ParentBasedAlwaysOn\t{:?}",SamplerChoice::ParentBasedAlwaysOn.name().as_bytes());
println!("name/ParentBasedAlwaysOff\t{:?}",SamplerChoice::ParentBasedAlwaysOff.name().as_bytes());
println!("name/ParentBasedTraceIdRatio\t{:?}",SamplerChoice::ParentBasedTraceIdRatio.name().as_bytes());
println!("uses_ratio/AlwaysOn\t{:?}",SamplerChoice::AlwaysOn.uses_ratio());
println!("uses_ratio/AlwaysOff\t{:?}",SamplerChoice::AlwaysOff.uses_ratio());
println!("uses_ratio/TraceIdRatio\t{:?}",SamplerChoice::TraceIdRatio.uses_ratio());
println!("uses_ratio/ParentBasedAlwaysOn\t{:?}",SamplerChoice::ParentBasedAlwaysOn.uses_ratio());
println!("uses_ratio/ParentBasedAlwaysOff\t{:?}",SamplerChoice::ParentBasedAlwaysOff.uses_ratio());
println!("uses_ratio/ParentBasedTraceIdRatio\t{:?}",SamplerChoice::ParentBasedTraceIdRatio.uses_ratio());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(SamplerChoice::AlwaysOn.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::AlwaysOn.name(),"sampler_choice_f5cc6ea1/name/AlwaysOn");
assert_eq!(SamplerChoice::AlwaysOff.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::AlwaysOff.name(),"sampler_choice_f5cc6ea1/name/AlwaysOff");
assert_eq!(SamplerChoice::TraceIdRatio.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::TraceIdRatio.name(),"sampler_choice_f5cc6ea1/name/TraceIdRatio");
assert_eq!(SamplerChoice::ParentBasedAlwaysOn.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedAlwaysOn.name(),"sampler_choice_f5cc6ea1/name/ParentBasedAlwaysOn");
assert_eq!(SamplerChoice::ParentBasedAlwaysOff.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedAlwaysOff.name(),"sampler_choice_f5cc6ea1/name/ParentBasedAlwaysOff");
assert_eq!(SamplerChoice::ParentBasedTraceIdRatio.name().as_bytes(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedTraceIdRatio.name(),"sampler_choice_f5cc6ea1/name/ParentBasedTraceIdRatio");
assert_eq!(SamplerChoice::AlwaysOn.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::AlwaysOn.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/AlwaysOn");
assert_eq!(SamplerChoice::AlwaysOff.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::AlwaysOff.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/AlwaysOff");
assert_eq!(SamplerChoice::TraceIdRatio.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::TraceIdRatio.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/TraceIdRatio");
assert_eq!(SamplerChoice::ParentBasedAlwaysOn.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedAlwaysOn.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/ParentBasedAlwaysOn");
assert_eq!(SamplerChoice::ParentBasedAlwaysOff.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedAlwaysOff.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/ParentBasedAlwaysOff");
assert_eq!(SamplerChoice::ParentBasedTraceIdRatio.uses_ratio(),artifactkeeper_kernel::finite_catalog::sampler_choice_f5cc6ea1::SamplerChoice::ParentBasedTraceIdRatio.uses_ratio(),"sampler_choice_f5cc6ea1/uses_ratio/ParentBasedTraceIdRatio");
}
