// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Determines whether a remote server name is forbidden.
///
/// The local server name is always permitted. Otherwise a deny-list match or an
/// active allow-list miss forbids the destination.
use ruma::ServerName;
use serde::Deserialize;
use crate::implement;
use crate::utils::BoolExt;

#[implement(super::Config)]
#[must_use]
pub fn is_forbidden_remote_server_name(&self, server_name: &ServerName) -> bool {
	if server_name == self.server_name {
		return false;
	}

	let deny_list_active = self
		.forbidden_remote_server_names
		.is_empty()
		.is_false();

	let allow_list_active = self
		.allowed_remote_server_names_experimental
		.is_empty()
		.is_false();

	if deny_list_active
		&& self
			.forbidden_remote_server_names
			.is_match(server_name.host())
	{
		return true;
	}

	if allow_list_active
		&& !self
			.allowed_remote_server_names_experimental
			.is_match(server_name.host())
	{
		return true;
	}

	false
}

