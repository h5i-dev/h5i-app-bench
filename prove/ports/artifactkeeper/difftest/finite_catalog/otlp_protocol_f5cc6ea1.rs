#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OtlpProtocol {Grpc,HttpProtobuf}
impl OtlpProtocol {
    /// Return the canonical protocol name for logging.
    fn name(self) -> &'static str {
        match self {
            Self::Grpc => "grpc",
            Self::HttpProtobuf => "http/protobuf",
        }
    }
}
fn main(){
println!("name/Grpc\t{:?}",OtlpProtocol::Grpc.name().as_bytes());
println!("name/HttpProtobuf\t{:?}",OtlpProtocol::HttpProtobuf.name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OtlpProtocol::Grpc.name().as_bytes(),artifactkeeper_kernel::finite_catalog::otlp_protocol_f5cc6ea1::OtlpProtocol::Grpc.name(),"otlp_protocol_f5cc6ea1/name/Grpc");
assert_eq!(OtlpProtocol::HttpProtobuf.name().as_bytes(),artifactkeeper_kernel::finite_catalog::otlp_protocol_f5cc6ea1::OtlpProtocol::HttpProtobuf.name(),"otlp_protocol_f5cc6ea1/name/HttpProtobuf");
}
