//! Built-in policies from `policy/policy.rs::default`, constructed as pure values.
use crate::acts::{Action, Family};
use crate::rsrc::Resource;
use crate::stmts::{Effect, Statement};

/// Policy metadata, added without changing the existing evaluation types.
pub struct Policy {
    pub id: Vec<u8>,
    pub version: Vec<u8>,
    pub statements: Vec<Statement>,
}

/// `DEFAULT_VERSION`.
pub fn default_version() -> Vec<u8> {
    b"2012-10-17".to_vec()
}
/// `KMS_KEY_ADMINISTRATOR`.
pub fn kms_key_administrator() -> Vec<u8> {
    b"KMSKeyAdministrator".to_vec()
}
/// `KMS_KEY_USER`.
pub fn kms_key_user() -> Vec<u8> {
    b"KMSKeyUser".to_vec()
}
/// `KMS_AUDITOR`.
pub fn kms_auditor() -> Vec<u8> {
    b"KMSAuditor".to_vec()
}
/// `ALL_KMS_KEYS`.
pub fn all_kms_keys() -> Vec<u8> {
    b"*".to_vec()
}

fn allow(actions: Vec<Action>, resources: Vec<Resource>) -> Statement {
    Statement {
        effect: Effect::Allow,
        actions,
        not_actions: Vec::new(),
        resources,
        not_resources: Vec::new(),
        conditions: crate::condfuncs::Functions {
            for_any_value: Vec::new(),
            for_all_values: Vec::new(),
            for_normal: Vec::new(),
        },
    }
}

/// `kms_allow`.
pub fn kms_allow(actions: Vec<Action>) -> Statement {
    allow(actions, {
        let mut __v = Vec::new();
        __v.push(Resource::Kms(all_kms_keys()));
        __v
    })
}

/// `assume_role_allow`.
pub fn assume_role_allow() -> Statement {
    allow(
        {
            let mut __v = Vec::new();
            __v.push(Action {
                family: Family::Sts,
                name: b"sts:AssumeRole".to_vec(),
            });
            __v
        },
        Vec::new(),
    )
}

/// `DEFAULT_POLICIES`: preserve the upstream order, statements and action lists.
pub fn default_policies() -> Vec<(Vec<u8>, Policy)> {
    {
        let mut __v = Vec::new();
        __v.push((
            b"readwrite".to_vec(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:*".to_vec(),
                            });
                            __v
                        },
                        {
                            let mut __v = Vec::new();
                            __v.push(Resource::S3(b"*".to_vec()));
                            __v
                        },
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Sts,
                                name: b"sts:AssumeRole".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v
                },
            },
        ));
        __v.push((
            b"readonly".to_vec(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:GetBucketLocation".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:GetObject".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:GetBucketQuota".to_vec(),
                            });
                            __v
                        },
                        {
                            let mut __v = Vec::new();
                            __v.push(Resource::S3(b"*".to_vec()));
                            __v
                        },
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Sts,
                                name: b"sts:AssumeRole".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v
                },
            },
        ));
        __v.push((
            b"writeonly".to_vec(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:PutObject".to_vec(),
                            });
                            __v
                        },
                        {
                            let mut __v = Vec::new();
                            __v.push(Resource::S3(b"*".to_vec()));
                            __v
                        },
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Sts,
                                name: b"sts:AssumeRole".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v
                },
            },
        ));
        __v.push((
            b"diagnostics".to_vec(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:Profiling".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:ServerTrace".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:ConsoleLog".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:ServerInfo".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:TopLocksInfo".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:OBDInfo".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:Prometheus".to_vec(),
                            });
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:BandwidthMonitor".to_vec(),
                            });
                            __v
                        },
                        {
                            let mut __v = Vec::new();
                            __v.push(Resource::S3(b"*".to_vec()));
                            __v
                        },
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Sts,
                                name: b"sts:AssumeRole".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v
                },
            },
        ));
        __v.push((
            b"consoleAdmin".to_vec(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Admin,
                                name: b"admin:*".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Kms,
                                name: b"kms:*".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::S3,
                                name: b"s3:*".to_vec(),
                            });
                            __v
                        },
                        {
                            let mut __v = Vec::new();
                            __v.push(Resource::S3(b"*".to_vec()));
                            __v
                        },
                    ));
                    __v.push(allow(
                        {
                            let mut __v = Vec::new();
                            __v.push(Action {
                                family: Family::Sts,
                                name: b"sts:AssumeRole".to_vec(),
                            });
                            __v
                        },
                        Vec::new(),
                    ));
                    __v
                },
            },
        ));
        __v.push((
            kms_key_administrator(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(kms_allow({
                        let mut __v = Vec::new();
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:DescribeKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:ListKeys".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:EnableKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:DisableKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:RotateKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:DeleteKey".to_vec(),
                        });
                        __v
                    }));
                    __v.push(assume_role_allow());
                    __v
                },
            },
        ));
        __v.push((
            kms_key_user(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(kms_allow({
                        let mut __v = Vec::new();
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:GenerateDataKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:Decrypt".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:DescribeKey".to_vec(),
                        });
                        __v
                    }));
                    __v.push(assume_role_allow());
                    __v
                },
            },
        ));
        __v.push((
            kms_auditor(),
            Policy {
                id: Vec::new(),
                version: default_version(),
                statements: {
                    let mut __v = Vec::new();
                    __v.push(kms_allow({
                        let mut __v = Vec::new();
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:DescribeKey".to_vec(),
                        });
                        __v.push(Action {
                            family: Family::Kms,
                            name: b"kms:ListKeys".to_vec(),
                        });
                        __v
                    }));
                    __v.push(assume_role_allow());
                    __v
                },
            },
        ));
        __v
    }
}
