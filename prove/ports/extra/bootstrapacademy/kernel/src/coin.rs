//! `academy_core/coin/impl`: `CoinFeatureServiceImpl` (lib.rs) and
//! `CoinServiceImpl` (coin.rs), over `PostgresCoinRepository::add_coins`.
use crate::access::{authenticate, ensure_admin, ensure_self_or_admin, unwrap_or};
use crate::{
    commit, repo, db_write, generate, Authentication, Balance, Ctx, Env, Error, Reply, Transaction, UserIdOrSelf,
    Write,
};

/// `decode_balance`: both columns are `>= 0`.
fn balance(coins: i64, withheld_coins: i64) -> Balance {
    Balance { coins: coins as u64, withheld_coins: withheld_coins as u64 }
}

/// `CoinRepository::get_balance`: no row is a zero balance.
pub fn get_balance_row(ctx: &Ctx, user_id: u64) -> Balance {
    match repo::get_coins(&ctx.db, user_id) {
        Some(r) => balance(r.coins, r.withheld_coins),
        None => Balance { coins: 0, withheld_coins: 0 },
    }
}

/// `PostgresCoinRepository::add_coins`: the `merge` of `coin.sql`. A bigint
/// overflow is an `Other` error, a negative column `NotEnoughCoins`
/// (`coins_coins_check`, `coins_withheld_coins_check`).
pub fn repo_add_coins(ctx: &mut Ctx, user_id: u64, coins: i64, withhold: bool) -> Result<Balance, Error> {
    let (coins, withheld_coins) = if withhold { (0, coins) } else { (coins, 0) };
    let (new_coins, new_withheld) = match repo::get_coins(&ctx.db, user_id) {
        Some(r) => {
            let a = match r.coins.checked_add(coins) {
                Some(a) => a,
                None => return Err(Error::Internal),
            };
            let b = match r.withheld_coins.checked_add(withheld_coins) {
                Some(b) => b,
                None => return Err(Error::Internal),
            };
            (a, b)
        }
        None => (coins, withheld_coins),
    };
    if new_coins < 0 || new_withheld < 0 {
        return Err(Error::NotEnoughCoins);
    }
    db_write(ctx, Write::AddCoins { user_id, coins, withheld_coins });
    Ok(balance(new_coins, new_withheld))
}

/// `CoinServiceImpl::add_coins`.
pub fn service_add_coins(
    ctx: &mut Ctx,
    env: &Env,
    user_id: u64,
    coins: i64,
    withhold: bool,
    description: Option<Vec<u8>>,
    include_in_credit_note: bool,
) -> Result<Balance, Error> {
    let new_balance = repo_add_coins(ctx, user_id, coins, withhold)?;
    let transaction = Transaction {
        id: generate(ctx),
        user_id,
        coins,
        description,
        created_at: env.now,
        include_in_credit_note,
    };
    db_write(ctx, Write::CreateTransaction(transaction));
    Ok(new_balance)
}

/// `CoinFeatureServiceImpl::get_balance`.
pub fn get_balance(ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, user_id: UserIdOrSelf) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::UserNotFound);
    }
    Ok(Reply::Balance(get_balance_row(ctx, user_id)))
}

/// `CoinFeatureServiceImpl::add_coins`: administrators may only debit.
pub fn add_coins(
    ctx: &mut Ctx,
    env: &Env,
    token: &Option<Authentication>,
    user_id: UserIdOrSelf,
    coins: i64,
    description: &Option<Vec<u8>>,
    include_in_credit_note: bool,
) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_admin(&auth)?;
    if coins > 0 {
        return Err(Error::CreditNotAuthorized);
    }
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::UserNotFound);
    }
    let new_balance = service_add_coins(ctx, env, user_id, coins, false, crate::clone_bytes_opt(description), include_in_credit_note)?;
    commit(ctx);
    Ok(Reply::Balance(new_balance))
}
