import Spec
open Aeneas Aeneas.Std Result oxicloud_kernel
namespace oxicloud_kernel.Verified.OxicloudDavState

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem addressbook_restoration (snapshot : davstate.AddressBook) :
    (davstate.AddressBook.from_raw snapshot.id snapshot.name snapshot.owner_id snapshot.description snapshot.color snapshot.is_public snapshot.created_at snapshot.updated_at = ok (snapshot)) ∧
    davstate.AddressBook.impl.id (snapshot) = ok snapshot.id ∧
    davstate.AddressBook.impl.name (snapshot) = ok snapshot.name ∧
    davstate.AddressBook.impl.owner_id (snapshot) = ok snapshot.owner_id ∧
    davstate.AddressBook.impl.description (snapshot) = ok snapshot.description ∧
    davstate.AddressBook.impl.color (snapshot) = ok snapshot.color ∧
    davstate.AddressBook.impl.is_public (snapshot) = ok snapshot.is_public ∧
    davstate.AddressBook.impl.created_at (snapshot) = ok snapshot.created_at ∧
    davstate.AddressBook.impl.updated_at (snapshot) = ok snapshot.updated_at := by
  simp [davstate.AddressBook.from_raw, davstate.AddressBook.impl.id, davstate.AddressBook.impl.name, davstate.AddressBook.impl.owner_id, davstate.AddressBook.impl.description, davstate.AddressBook.impl.color, davstate.AddressBook.impl.is_public, davstate.AddressBook.impl.created_at, davstate.AddressBook.impl.updated_at]

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem contact_restoration (snapshot : davstate.Contact) :
    (davstate.Contact.from_raw snapshot.id snapshot.address_book_id snapshot.uid snapshot.full_name snapshot.first_name snapshot.last_name snapshot.nickname snapshot.email snapshot.phone snapshot.address snapshot.organization snapshot.title snapshot.notes snapshot.photo_url snapshot.birthday snapshot.anniversary snapshot.vcard snapshot.etag snapshot.created_at snapshot.updated_at = ok (snapshot)) ∧
    davstate.Contact.impl.id (snapshot) = ok snapshot.id ∧
    davstate.Contact.impl.address_book_id (snapshot) = ok snapshot.address_book_id ∧
    davstate.Contact.impl.uid (snapshot) = ok snapshot.uid ∧
    davstate.Contact.impl.full_name (snapshot) = ok snapshot.full_name ∧
    davstate.Contact.impl.first_name (snapshot) = ok snapshot.first_name ∧
    davstate.Contact.impl.last_name (snapshot) = ok snapshot.last_name ∧
    davstate.Contact.impl.nickname (snapshot) = ok snapshot.nickname ∧
    davstate.Contact.impl.email (snapshot) = ok snapshot.email ∧
    davstate.Contact.impl.phone (snapshot) = ok snapshot.phone ∧
    davstate.Contact.impl.address (snapshot) = ok snapshot.address ∧
    davstate.Contact.impl.organization (snapshot) = ok snapshot.organization ∧
    davstate.Contact.impl.title (snapshot) = ok snapshot.title ∧
    davstate.Contact.impl.notes (snapshot) = ok snapshot.notes ∧
    davstate.Contact.impl.photo_url (snapshot) = ok snapshot.photo_url ∧
    davstate.Contact.impl.birthday (snapshot) = ok snapshot.birthday ∧
    davstate.Contact.impl.anniversary (snapshot) = ok snapshot.anniversary ∧
    davstate.Contact.impl.vcard (snapshot) = ok snapshot.vcard ∧
    davstate.Contact.impl.etag (snapshot) = ok snapshot.etag ∧
    davstate.Contact.impl.created_at (snapshot) = ok snapshot.created_at ∧
    davstate.Contact.impl.updated_at (snapshot) = ok snapshot.updated_at ∧
    davstate.Contact.into_email (snapshot) = ok snapshot.email := by
  simp [davstate.Contact.from_raw, davstate.Contact.impl.id, davstate.Contact.impl.address_book_id, davstate.Contact.impl.uid, davstate.Contact.impl.full_name, davstate.Contact.impl.first_name, davstate.Contact.impl.last_name, davstate.Contact.impl.nickname, davstate.Contact.impl.email, davstate.Contact.impl.phone, davstate.Contact.impl.address, davstate.Contact.impl.organization, davstate.Contact.impl.title, davstate.Contact.impl.notes, davstate.Contact.impl.photo_url, davstate.Contact.impl.birthday, davstate.Contact.impl.anniversary, davstate.Contact.impl.vcard, davstate.Contact.impl.etag, davstate.Contact.impl.created_at, davstate.Contact.impl.updated_at, davstate.Contact.into_email]

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem calendartodo_restoration (snapshot : davstate.CalendarTodo) :
    (davstate.CalendarTodo.with_id snapshot.id snapshot.calendar_id snapshot.summary snapshot.description snapshot.location snapshot.status snapshot.percent_complete snapshot.priority snapshot.start_time snapshot.due_time snapshot.completed_at snapshot.all_day snapshot.rrule snapshot.ical_uid snapshot.ical_data snapshot.created_at snapshot.updated_at = ok ({snapshot with recurrence_id := none})) ∧
    davstate.CalendarTodo.impl.id ({snapshot with recurrence_id := none}) = ok snapshot.id ∧
    davstate.CalendarTodo.impl.calendar_id ({snapshot with recurrence_id := none}) = ok snapshot.calendar_id ∧
    davstate.CalendarTodo.impl.summary ({snapshot with recurrence_id := none}) = ok snapshot.summary ∧
    davstate.CalendarTodo.impl.description ({snapshot with recurrence_id := none}) = ok snapshot.description ∧
    davstate.CalendarTodo.impl.location ({snapshot with recurrence_id := none}) = ok snapshot.location ∧
    davstate.CalendarTodo.impl.status ({snapshot with recurrence_id := none}) = ok snapshot.status ∧
    davstate.CalendarTodo.impl.percent_complete ({snapshot with recurrence_id := none}) = ok snapshot.percent_complete ∧
    davstate.CalendarTodo.impl.priority ({snapshot with recurrence_id := none}) = ok snapshot.priority ∧
    davstate.CalendarTodo.impl.start_time ({snapshot with recurrence_id := none}) = ok snapshot.start_time ∧
    davstate.CalendarTodo.impl.due_time ({snapshot with recurrence_id := none}) = ok snapshot.due_time ∧
    davstate.CalendarTodo.impl.completed_at ({snapshot with recurrence_id := none}) = ok snapshot.completed_at ∧
    davstate.CalendarTodo.impl.all_day ({snapshot with recurrence_id := none}) = ok snapshot.all_day ∧
    davstate.CalendarTodo.impl.rrule ({snapshot with recurrence_id := none}) = ok snapshot.rrule ∧
    davstate.CalendarTodo.impl.recurrence_id ({snapshot with recurrence_id := none}) = ok none ∧
    davstate.CalendarTodo.impl.ical_uid ({snapshot with recurrence_id := none}) = ok snapshot.ical_uid ∧
    davstate.CalendarTodo.impl.ical_data ({snapshot with recurrence_id := none}) = ok snapshot.ical_data ∧
    davstate.CalendarTodo.impl.created_at ({snapshot with recurrence_id := none}) = ok snapshot.created_at ∧
    davstate.CalendarTodo.impl.updated_at ({snapshot with recurrence_id := none}) = ok snapshot.updated_at := by
  simp [davstate.CalendarTodo.with_id, davstate.CalendarTodo.impl.id, davstate.CalendarTodo.impl.calendar_id, davstate.CalendarTodo.impl.summary, davstate.CalendarTodo.impl.description, davstate.CalendarTodo.impl.location, davstate.CalendarTodo.impl.status, davstate.CalendarTodo.impl.percent_complete, davstate.CalendarTodo.impl.priority, davstate.CalendarTodo.impl.start_time, davstate.CalendarTodo.impl.due_time, davstate.CalendarTodo.impl.completed_at, davstate.CalendarTodo.impl.all_day, davstate.CalendarTodo.impl.rrule, davstate.CalendarTodo.impl.recurrence_id, davstate.CalendarTodo.impl.ical_uid, davstate.CalendarTodo.impl.ical_data, davstate.CalendarTodo.impl.created_at, davstate.CalendarTodo.impl.updated_at]

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem audiofilemetadata_restoration (snapshot : davstate.AudioFileMetadata) :
    (davstate.AudioFileMetadata.with_all_fields snapshot.file_id snapshot.title snapshot.artist snapshot.album snapshot.album_artist snapshot.genre snapshot.track_number snapshot.disc_number snapshot.year snapshot.duration_secs snapshot.bitrate snapshot.sample_rate snapshot.channels snapshot.format snapshot.created_at snapshot.updated_at = ok (snapshot)) ∧
    davstate.AudioFileMetadata.impl.file_id (snapshot) = ok snapshot.file_id ∧
    davstate.AudioFileMetadata.impl.title (snapshot) = ok snapshot.title ∧
    davstate.AudioFileMetadata.impl.artist (snapshot) = ok snapshot.artist ∧
    davstate.AudioFileMetadata.impl.album (snapshot) = ok snapshot.album ∧
    davstate.AudioFileMetadata.impl.album_artist (snapshot) = ok snapshot.album_artist ∧
    davstate.AudioFileMetadata.impl.genre (snapshot) = ok snapshot.genre ∧
    davstate.AudioFileMetadata.impl.track_number (snapshot) = ok snapshot.track_number ∧
    davstate.AudioFileMetadata.impl.disc_number (snapshot) = ok snapshot.disc_number ∧
    davstate.AudioFileMetadata.impl.year (snapshot) = ok snapshot.year ∧
    davstate.AudioFileMetadata.impl.duration_secs (snapshot) = ok snapshot.duration_secs ∧
    davstate.AudioFileMetadata.impl.bitrate (snapshot) = ok snapshot.bitrate ∧
    davstate.AudioFileMetadata.impl.sample_rate (snapshot) = ok snapshot.sample_rate ∧
    davstate.AudioFileMetadata.impl.channels (snapshot) = ok snapshot.channels ∧
    davstate.AudioFileMetadata.impl.format (snapshot) = ok snapshot.format ∧
    davstate.AudioFileMetadata.impl.created_at (snapshot) = ok snapshot.created_at ∧
    davstate.AudioFileMetadata.impl.updated_at (snapshot) = ok snapshot.updated_at := by
  simp [davstate.AudioFileMetadata.with_all_fields, davstate.AudioFileMetadata.impl.file_id, davstate.AudioFileMetadata.impl.title, davstate.AudioFileMetadata.impl.artist, davstate.AudioFileMetadata.impl.album, davstate.AudioFileMetadata.impl.album_artist, davstate.AudioFileMetadata.impl.genre, davstate.AudioFileMetadata.impl.track_number, davstate.AudioFileMetadata.impl.disc_number, davstate.AudioFileMetadata.impl.year, davstate.AudioFileMetadata.impl.duration_secs, davstate.AudioFileMetadata.impl.bitrate, davstate.AudioFileMetadata.impl.sample_rate, davstate.AudioFileMetadata.impl.channels, davstate.AudioFileMetadata.impl.format, davstate.AudioFileMetadata.impl.created_at, davstate.AudioFileMetadata.impl.updated_at]

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem devicecode_restoration (snapshot : davstate.DeviceCode) :
    (davstate.DeviceCode.from_raw snapshot.id snapshot.device_code snapshot.user_code snapshot.client_name snapshot.scopes snapshot.status snapshot.user_id snapshot.access_token snapshot.refresh_token snapshot.verification_uri snapshot.verification_uri_complete snapshot.expires_at snapshot.poll_interval_secs snapshot.last_poll_at snapshot.created_at snapshot.authorized_at = ok (snapshot)) ∧
    davstate.DeviceCode.impl.id (snapshot) = ok snapshot.id ∧
    davstate.DeviceCode.impl.device_code (snapshot) = ok snapshot.device_code ∧
    davstate.DeviceCode.impl.user_code (snapshot) = ok snapshot.user_code ∧
    davstate.DeviceCode.impl.client_name (snapshot) = ok snapshot.client_name ∧
    davstate.DeviceCode.impl.scopes (snapshot) = ok snapshot.scopes ∧
    davstate.DeviceCode.impl.status (snapshot) = ok snapshot.status ∧
    davstate.DeviceCode.impl.user_id (snapshot) = ok snapshot.user_id ∧
    davstate.DeviceCode.impl.access_token (snapshot) = ok snapshot.access_token ∧
    davstate.DeviceCode.impl.refresh_token (snapshot) = ok snapshot.refresh_token ∧
    davstate.DeviceCode.impl.verification_uri (snapshot) = ok snapshot.verification_uri ∧
    davstate.DeviceCode.impl.verification_uri_complete (snapshot) = ok snapshot.verification_uri_complete ∧
    davstate.DeviceCode.impl.expires_at (snapshot) = ok snapshot.expires_at ∧
    davstate.DeviceCode.impl.poll_interval_secs (snapshot) = ok snapshot.poll_interval_secs ∧
    davstate.DeviceCode.impl.last_poll_at (snapshot) = ok snapshot.last_poll_at ∧
    davstate.DeviceCode.impl.created_at (snapshot) = ok snapshot.created_at ∧
    davstate.DeviceCode.impl.authorized_at (snapshot) = ok snapshot.authorized_at := by
  simp [davstate.DeviceCode.from_raw, davstate.DeviceCode.impl.id, davstate.DeviceCode.impl.device_code, davstate.DeviceCode.impl.user_code, davstate.DeviceCode.impl.client_name, davstate.DeviceCode.impl.scopes, davstate.DeviceCode.impl.status, davstate.DeviceCode.impl.user_id, davstate.DeviceCode.impl.access_token, davstate.DeviceCode.impl.refresh_token, davstate.DeviceCode.impl.verification_uri, davstate.DeviceCode.impl.verification_uri_complete, davstate.DeviceCode.impl.expires_at, davstate.DeviceCode.impl.poll_interval_secs, davstate.DeviceCode.impl.last_poll_at, davstate.DeviceCode.impl.created_at, davstate.DeviceCode.impl.authorized_at]

/-- Exact persisted product reconstruction and every selected public observation. -/
theorem trasheditem_restoration (snapshot : davstate.TrashedItem) :
    (davstate.TrashedItem.from_raw snapshot.id snapshot.original_id snapshot.user_id snapshot.item_type snapshot.name snapshot.original_path snapshot.trashed_at snapshot.deletion_date = ok (snapshot)) ∧
    davstate.TrashedItem.impl.id (snapshot) = ok snapshot.id ∧
    davstate.TrashedItem.impl.original_id (snapshot) = ok snapshot.original_id ∧
    davstate.TrashedItem.impl.user_id (snapshot) = ok snapshot.user_id ∧
    davstate.TrashedItem.impl.item_type (snapshot) = ok snapshot.item_type ∧
    davstate.TrashedItem.impl.name (snapshot) = ok snapshot.name ∧
    davstate.TrashedItem.impl.original_path (snapshot) = ok snapshot.original_path ∧
    davstate.TrashedItem.impl.trashed_at (snapshot) = ok snapshot.trashed_at ∧
    davstate.TrashedItem.impl.deletion_date (snapshot) = ok snapshot.deletion_date := by
  simp [davstate.TrashedItem.from_raw, davstate.TrashedItem.impl.id, davstate.TrashedItem.impl.original_id, davstate.TrashedItem.impl.user_id, davstate.TrashedItem.impl.item_type, davstate.TrashedItem.impl.name, davstate.TrashedItem.impl.original_path, davstate.TrashedItem.impl.trashed_at, davstate.TrashedItem.impl.deletion_date]

end oxicloud_kernel.Verified.OxicloudDavState
