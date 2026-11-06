//! Device address assignment: `crates/defguard_common/src/db/models/device.rs`
//! `Device::assign_next_network_ip` (the address loop; the relation insert is
//! the shell's) with `ipnetwork`'s `network()`, `broadcast()`, `ip()`,
//! `contains()` and iteration.

/// `std::net::IpAddr`: the family and the address bits.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Ip {
    pub v4: bool,
    pub bits: u128,
}

/// `ipnetwork::IpNetwork`: the configured address (`ip()`, the gateway's)
/// and the prefix (at most 32 for IPv4, 128 for IPv6, as `IpNetwork` ensures).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Net {
    pub v4: bool,
    pub ip: u128,
    pub prefix: u8,
}

/// Host bits: `32 - prefix` or `128 - prefix`.
pub fn host_bits(n: &Net) -> u32 {
    let p = n.prefix as u32;
    if n.v4 {
        if p >= 32 { 0 } else { 32 - p }
    } else if p >= 128 {
        0
    } else {
        128 - p
    }
}

/// `network()`: the address with the host bits cleared.
pub fn network(n: &Net) -> u128 {
    let h = host_bits(n);
    if h >= 128 {
        0
    } else {
        let block: u128 = 1u128 << h;
        n.ip - n.ip % block
    }
}

/// `broadcast()`: the address with the host bits set.
pub fn broadcast(n: &Net) -> u128 {
    let h = host_bits(n);
    if h >= 128 {
        0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff
    } else {
        let block: u128 = 1u128 << h;
        network(n) + (block - 1)
    }
}

/// `IpNetwork::contains`.
pub fn contains(n: &Net, ip: &Ip) -> bool {
    n.v4 == ip.v4 && network(n) <= ip.bits && ip.bits <= broadcast(n)
}

fn ip_in(v: &Vec<Ip>, ip: &Ip) -> bool {
    let mut i = 0;
    while i < v.len() {
        if v[i].v4 == ip.v4 && v[i].bits == ip.bits {
            return true;
        }
        i += 1;
    }
    false
}

/// Whether `for ip in address` takes `x`: not the network, broadcast or
/// gateway address, and neither used nor reserved.
pub fn assignable(n: &Net, x: u128, used: &Vec<Ip>, reserved: &Vec<Ip>) -> bool {
    let ip = Ip { v4: n.v4, bits: x };
    !(x == network(n) || x == broadcast(n) || x == n.ip) && !ip_in(used, &ip) && !ip_in(reserved, &ip)
}

/// The scan `for ip in address { ... }` from `network()` up to `broadcast()`.
pub fn first_free(n: &Net, used: &Vec<Ip>, reserved: &Vec<Ip>) -> Option<Ip> {
    let last = broadcast(n);
    let mut x = network(n);
    while x <= last {
        if assignable(n, x, used, reserved) {
            return Some(Ip { v4: n.v4, bits: x });
        }
        if x == last {
            return None;
        }
        x += 1;
    }
    None
}

/// `current_ips.and_then(|ips| ips.iter().find(|ip| address.contains(**ip)))`.
pub fn find_current(current: &Vec<Ip>, n: &Net) -> Option<Ip> {
    let mut i = 0;
    while i < current.len() {
        if contains(n, &current[i]) {
            return Some(current[i]);
        }
        i += 1;
    }
    None
}

/// The address for one subnet: a current one inside it, kept as it is, or
/// the first free one.
pub fn pick(n: &Net, used: &Vec<Ip>, reserved: &Vec<Ip>, current: &Option<Vec<Ip>>) -> Option<Ip> {
    match current {
        Some(c) => match find_current(c, n) {
            Some(ip) => Some(ip),
            None => first_free(n, used, reserved),
        },
        None => first_free(n, used, reserved),
    }
}

/// `assign_next_network_ip`: one address per subnet of the location, or the
/// index of the first subnet that is full (`DeviceError::NetworkFull`).
pub fn assign_next_network_ip(nets: &Vec<Net>, used: &Vec<Ip>, reserved: &Vec<Ip>, current: &Option<Vec<Ip>>) -> Result<Vec<Ip>, usize> {
    let mut ips = Vec::new();
    let mut k = 0;
    while k < nets.len() {
        match pick(&nets[k], used, reserved, current) {
            None => return Err(k),
            Some(ip) => ips.push(ip),
        }
        k += 1;
    }
    Ok(ips)
}
