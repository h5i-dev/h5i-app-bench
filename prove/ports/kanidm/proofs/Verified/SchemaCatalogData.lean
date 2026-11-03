import Spec
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Verified.SchemaCatalog
structure AttributeModel where
  «name» : U16
  «uuid» : U128
  «description» : List U8
  «multivalue» : Bool
  «unique» : Bool
  «phantom» : Bool
  «sync_allowed» : Bool
  «replicated» : Bool
  «indexed» : Bool
  «syntax» : U16
  deriving DecidableEq
def viewAttribute (r : schema_catalog.AttributeRecord) : AttributeModel :=
  ⟨r.«name», r.«uuid», r.«description».val, r.«multivalue», r.«unique», r.«phantom», r.«sync_allowed», r.«replicated», r.«indexed», r.«syntax»⟩
structure ClassModel where
  «name» : List U8
  «uuid» : U128
  «description» : List U8
  «sync_allowed» : Bool
  «systemmay» : List U16
  «may» : List U16
  «systemmust» : List U16
  «must» : List U16
  «systemsupplements» : List U8
  «supplements» : List U8
  «systemexcludes» : List U8
  «excludes» : List U8
  deriving DecidableEq
def viewClass (r : schema_catalog.ClassRecord) : ClassModel :=
  ⟨r.«name».val, r.«uuid», r.«description».val, r.«sync_allowed», r.«systemmay».val, r.«may».val, r.«systemmust».val, r.«must».val, r.«systemsupplements».val, r.«supplements».val, r.«systemexcludes».val, r.«excludes».val⟩
end kanidm_kernel.Verified.SchemaCatalog
