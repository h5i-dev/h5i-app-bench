//! Optional GPU policy subset; the existing conduit-kernel is the CPU oracle.
pub mod predicate;
use conduit_kernel::{Command, Delta, Error, Reply, View};
pub fn pack(v: &View, cmd: &Command) -> Option<[u64; 8]> {
    let op = match cmd {
        Command::CurrentUser => 0,
        Command::Feed => 1,
        Command::DeleteArticle => 2,
        Command::DeleteComment => 3,
        Command::Follow => 4,
        Command::Unfollow => 5,
        Command::Favorite => 6,
        Command::Unfavorite => 7,
        _ => return None,
    };
    Some([
        op,
        v.actor,
        v.article_exists as u64,
        v.article_author,
        v.comment_exists as u64,
        v.comment_author,
        v.profile_exists as u64,
        v.already as u64,
    ])
}
pub fn decode(code: u32) -> Option<Result<Reply, Error>> {
    Some(match code {
        0 => Ok(Reply::Allow),
        1 => Err(Error::Unauthenticated),
        2 => Err(Error::ArticleNotFound),
        3 => Err(Error::ForbiddenArticle),
        4 => Err(Error::CommentNotFound),
        5 => Err(Error::ForbiddenComment),
        6 => Err(Error::ProfileNotFound),
        10..=13 => Ok(Reply::Follow {
            following: code >= 12,
            changed: code % 2 != 0,
        }),
        20..=23 => Ok(Reply::Favorite {
            favorited: code <= 21,
            delta: match code {
                20 => Delta::Up,
                22 => Delta::Down,
                _ => Delta::Same,
            },
        }),
        _ => return None,
    })
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn packed_policy_matches_existing_transition() {
        let cmds = [
            Command::CurrentUser,
            Command::Feed,
            Command::DeleteArticle,
            Command::DeleteComment,
            Command::Follow,
            Command::Unfollow,
            Command::Favorite,
            Command::Unfavorite,
        ];
        for actor in [0, 1, 2, u64::MAX] {
            for author in [0, 1, 2, u64::MAX] {
                for comment_author in [0, 1, 2, u64::MAX] {
                    for bits in 0..16 {
                        let v = View {
                            actor,
                            article_author: author,
                            comment_author,
                            article_exists: bits & 1 != 0,
                            comment_exists: bits & 2 != 0,
                            profile_exists: bits & 4 != 0,
                            already: bits & 8 != 0,
                        };
                        for c in &cmds {
                            assert_eq!(
                                decode(predicate::evaluate(&pack(&v, c).unwrap())).unwrap(),
                                conduit_kernel::transition(&v, c),
                                "{v:?} {c:?}"
                            );
                        }
                    }
                }
            }
        }
    }
    #[test]
    fn invalid_abi_and_unsupported_commands_are_not_decisions() {
        assert_eq!(predicate::evaluate(&[]), u32::MAX);
        assert_eq!(predicate::evaluate(&[8; 8]), u32::MAX);
        assert!(decode(u32::MAX).is_none());
        let v = View {
            actor: 1,
            article_author: 1,
            comment_author: 1,
            article_exists: true,
            comment_exists: true,
            profile_exists: true,
            already: false,
        };
        assert!(
            pack(
                &v,
                &Command::Page {
                    limit: conduit_kernel::RawNum::Absent,
                    offset: conduit_kernel::RawNum::Absent
                }
            )
            .is_none()
        );
    }
}
