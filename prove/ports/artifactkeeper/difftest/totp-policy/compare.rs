#[path = UPSTREAM_PATH] mod upstream;
#[path = PORT_PATH] mod port;
fn main() {
    use upstream::{TotpPolicy as U, AuthProvider as A};
    use port::{TotpPolicy as P, AuthProvider as B};
    let policies = [(U::Disabled,P::Disabled),(U::RequiredForAdmins,P::RequiredForAdmins),
        (U::RequiredForAll,P::RequiredForAll)];
    let providers = [(A::Local,B::Local),(A::Ldap,B::Ldap),(A::Saml,B::Saml),(A::Oidc,B::Oidc),(A::Ci,B::Ci)];
    let mut cases = 0;
    for (u,p) in policies {
        assert_eq!(u.is_enforcing(), port::is_enforcing(p)); cases += 1;
        for (a,b) in providers {
            for is_admin in [false,true] {
                for is_service_account in [false,true] {
                    for totp_enabled in [false,true] {
                        let us = upstream::TotpSubject { auth_provider:a,is_admin,is_service_account,totp_enabled };
                        let ps = port::TotpSubject { auth_provider:b,is_admin,is_service_account,totp_enabled };
                        assert_eq!(format!("{:?}",upstream::totp_login_requirement(u,us)),
                            format!("{:?}",port::totp_login_requirement(p,ps)));
                        assert_eq!(upstream::policy_requires_totp(u,us),port::policy_requires_totp(p,ps));
                        cases += 2;
                    }
                }
            }
        }
        for (v,q) in policies {
            for pinned in [false,true] {
                for enrolled in [false,true] {
                    assert_eq!(format!("{:?}",upstream::check_policy_activation(u,v,pinned,enrolled)),
                        format!("{:?}",port::check_policy_activation(p,q,pinned,enrolled)));
                    cases += 1;
                }
            }
        }
    }
    println!("PASS: {cases} comparisons, exhaustive finite login and activation domains");
}
