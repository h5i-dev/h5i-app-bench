//! Lossless DAV/device persistence snapshots. No parser, I/O or random generation.
use crate::session::Timestamp;
pub struct Email {
    pub email: Vec<u8>,
    pub r#type: Vec<u8>, // home, work, other
    pub is_primary: bool,
}
pub struct Phone {
    pub number: Vec<u8>,
    pub r#type: Vec<u8>, // mobile, home, work, fax, other
    pub is_primary: bool,
}
pub struct Address {
    pub street: Option<Vec<u8>>,
    pub city: Option<Vec<u8>>,
    pub state: Option<Vec<u8>>,
    pub postal_code: Option<Vec<u8>>,
    pub country: Option<Vec<u8>>,
    pub r#type: Vec<u8>, // home, work, other
    pub is_primary: bool,
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DeviceCodeStatus {
    /// Waiting for the user to authorize on the verification page.
    Pending,
    /// User approved — tokens are ready for the polling client.
    Authorized,
    /// User explicitly denied the request.
    Denied,
    /// The code expired before the user acted.
    Expired,
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum TrashedItemType {
    File,
    Folder,
}
pub struct AddressBook {
    pub id: u128,
    pub name: Vec<u8>,
    pub owner_id: Vec<u8>,
    pub description: Option<Vec<u8>>,
    pub color: Option<Vec<u8>>,
    pub is_public: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}
impl AddressBook {
    pub fn from_raw(
        id: u128,
        name: Vec<u8>,
        owner_id: Vec<u8>,
        description: Option<Vec<u8>>,
        color: Option<Vec<u8>>,
        is_public: bool,
        created_at: Timestamp,
        updated_at: Timestamp,
    ) -> Self {
        Self {
            id,
            name,
            owner_id,
            description,
            color,
            is_public,
            created_at,
            updated_at,
        }
    }
    pub fn id(&self) -> u128 { self.id }
    pub fn name(&self) -> &Vec<u8> { &self.name }
    pub fn owner_id(&self) -> &Vec<u8> { &self.owner_id }
    pub fn description(&self) -> &Option<Vec<u8>> { &self.description }
    pub fn color(&self) -> &Option<Vec<u8>> { &self.color }
    pub fn is_public(&self) -> bool { self.is_public }
    pub fn created_at(&self) -> Timestamp { self.created_at }
    pub fn updated_at(&self) -> Timestamp { self.updated_at }
}
pub struct Contact {
    pub id: u128,
    pub address_book_id: u128,
    pub uid: Vec<u8>,
    pub full_name: Option<Vec<u8>>,
    pub first_name: Option<Vec<u8>>,
    pub last_name: Option<Vec<u8>>,
    pub nickname: Option<Vec<u8>>,
    pub email: Vec<Email>,
    pub phone: Vec<Phone>,
    pub address: Vec<Address>,
    pub organization: Option<Vec<u8>>,
    pub title: Option<Vec<u8>>,
    pub notes: Option<Vec<u8>>,
    pub photo_url: Option<Vec<u8>>,
    pub birthday: Option<i32>,
    pub anniversary: Option<i32>,
    pub vcard: Vec<u8>,
    pub etag: Vec<u8>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}
impl Contact {
    pub fn from_raw(
        id: u128,
        address_book_id: u128,
        uid: Vec<u8>,
        full_name: Option<Vec<u8>>,
        first_name: Option<Vec<u8>>,
        last_name: Option<Vec<u8>>,
        nickname: Option<Vec<u8>>,
        email: Vec<Email>,
        phone: Vec<Phone>,
        address: Vec<Address>,
        organization: Option<Vec<u8>>,
        title: Option<Vec<u8>>,
        notes: Option<Vec<u8>>,
        photo_url: Option<Vec<u8>>,
        birthday: Option<i32>,
        anniversary: Option<i32>,
        vcard: Vec<u8>,
        etag: Vec<u8>,
        created_at: Timestamp,
        updated_at: Timestamp,
    ) -> Self {
        Self {
            id,
            address_book_id,
            uid,
            full_name,
            first_name,
            last_name,
            nickname,
            email,
            phone,
            address,
            organization,
            title,
            notes,
            photo_url,
            birthday,
            anniversary,
            vcard,
            etag,
            created_at,
            updated_at,
        }
    }
    pub fn id(&self) -> u128 { self.id }
    pub fn address_book_id(&self) -> u128 { self.address_book_id }
    pub fn uid(&self) -> &Vec<u8> { &self.uid }
    pub fn full_name(&self) -> &Option<Vec<u8>> { &self.full_name }
    pub fn first_name(&self) -> &Option<Vec<u8>> { &self.first_name }
    pub fn last_name(&self) -> &Option<Vec<u8>> { &self.last_name }
    pub fn nickname(&self) -> &Option<Vec<u8>> { &self.nickname }
    pub fn email(&self) -> &Vec<Email> { &self.email }
    pub fn phone(&self) -> &Vec<Phone> { &self.phone }
    pub fn address(&self) -> &Vec<Address> { &self.address }
    pub fn organization(&self) -> &Option<Vec<u8>> { &self.organization }
    pub fn title(&self) -> &Option<Vec<u8>> { &self.title }
    pub fn notes(&self) -> &Option<Vec<u8>> { &self.notes }
    pub fn photo_url(&self) -> &Option<Vec<u8>> { &self.photo_url }
    pub fn birthday(&self) -> &Option<i32> { &self.birthday }
    pub fn anniversary(&self) -> &Option<i32> { &self.anniversary }
    pub fn vcard(&self) -> &Vec<u8> { &self.vcard }
    pub fn etag(&self) -> &Vec<u8> { &self.etag }
    pub fn created_at(&self) -> Timestamp { self.created_at }
    pub fn updated_at(&self) -> Timestamp { self.updated_at }
    pub fn into_email(&self) -> &Vec<Email> { &self.email }
}
pub struct CalendarTodo {
    /// Unique identifier for the todo
    pub id: u128,

    /// ID of the calendar this todo belongs to
    pub calendar_id: u128,

    /// Short summary/title of the todo. OPTIONAL on a VTODO (RFC 5545
    /// §3.6.2 mandates only UID + DTSTAMP), unlike VEVENT where
    /// OxiCloud requires SUMMARY.
    pub summary: Option<Vec<u8>>,

    /// Detailed description of the todo (optional)
    pub description: Option<Vec<u8>>,

    /// Location of the todo (optional)
    pub location: Option<Vec<u8>>,

    /// RFC 5545 §3.8.1.11 STATUS — NEEDS-ACTION / IN-PROCESS /
    /// COMPLETED / CANCELLED (free-form so client extensions survive)
    pub status: Option<Vec<u8>>,

    /// RFC 5545 §3.8.1.8 PERCENT-COMPLETE — 0..100
    pub percent_complete: Option<i16>,

    /// RFC 5545 §3.8.1.9 PRIORITY — 0..9 (0 = undefined)
    pub priority: Option<i16>,

    /// DTSTART of the todo (optional) — UTC instant; the original
    /// (possibly TZID-anchored) wall-clock form lives in `ical_data`
    pub start_time: Option<Timestamp>,

    /// DUE of the todo (optional)
    pub due_time: Option<Timestamp>,

    /// COMPLETED of the todo (optional)
    pub completed_at: Option<Timestamp>,

    /// Whether DTSTART carried `VALUE=DATE` (date-only task)
    pub all_day: bool,

    /// Recurrence rule in iCalendar RRULE format (optional — VTODOs
    /// can recur, RFC 5545 §3.6.2)
    pub rrule: Option<Vec<u8>>,

    /// RECURRENCE-ID (RFC 5545 §3.8.4.4) — same master/exception
    /// model as `CalendarEvent`: NULL on the master, non-NULL on
    /// per-instance overrides of a recurring task.
    pub recurrence_id: Option<Timestamp>,

    /// Unique identifier in iCalendar format (used for CalDAV sync)
    pub ical_uid: Vec<u8>,

    /// Complete iCalendar data (VCALENDAR with one VTODO + embedded
    /// VTIMEZONEs) — authoritative, served verbatim
    pub ical_data: Vec<u8>,

    /// Time when the todo was created
    pub created_at: Timestamp,

    /// Time when the todo was last modified
    pub updated_at: Timestamp,
}
impl CalendarTodo {
    pub fn with_id(
        id: u128,
        calendar_id: u128,
        summary: Option<Vec<u8>>,
        description: Option<Vec<u8>>,
        location: Option<Vec<u8>>,
        status: Option<Vec<u8>>,
        percent_complete: Option<i16>,
        priority: Option<i16>,
        start_time: Option<Timestamp>,
        due_time: Option<Timestamp>,
        completed_at: Option<Timestamp>,
        all_day: bool,
        rrule: Option<Vec<u8>>,
        ical_uid: Vec<u8>,
        ical_data: Vec<u8>,
        created_at: Timestamp,
        updated_at: Timestamp,
    ) -> Self {
        Self {
            id,
            calendar_id,
            summary,
            description,
            location,
            status,
            percent_complete,
            priority,
            start_time,
            due_time,
            completed_at,
            all_day,
            rrule,
            recurrence_id: None,
            ical_uid,
            ical_data,
            created_at,
            updated_at,
        }
    }
    pub fn id(&self) -> u128 { self.id }
    pub fn calendar_id(&self) -> u128 { self.calendar_id }
    pub fn summary(&self) -> &Option<Vec<u8>> { &self.summary }
    pub fn description(&self) -> &Option<Vec<u8>> { &self.description }
    pub fn location(&self) -> &Option<Vec<u8>> { &self.location }
    pub fn status(&self) -> &Option<Vec<u8>> { &self.status }
    pub fn percent_complete(&self) -> &Option<i16> { &self.percent_complete }
    pub fn priority(&self) -> &Option<i16> { &self.priority }
    pub fn start_time(&self) -> &Option<Timestamp> { &self.start_time }
    pub fn due_time(&self) -> &Option<Timestamp> { &self.due_time }
    pub fn completed_at(&self) -> &Option<Timestamp> { &self.completed_at }
    pub fn all_day(&self) -> bool { self.all_day }
    pub fn rrule(&self) -> &Option<Vec<u8>> { &self.rrule }
    pub fn recurrence_id(&self) -> &Option<Timestamp> { &self.recurrence_id }
    pub fn ical_uid(&self) -> &Vec<u8> { &self.ical_uid }
    pub fn ical_data(&self) -> &Vec<u8> { &self.ical_data }
    pub fn created_at(&self) -> Timestamp { self.created_at }
    pub fn updated_at(&self) -> Timestamp { self.updated_at }
}
pub struct AudioFileMetadata {
    pub file_id: u128,
    pub title: Option<Vec<u8>>,
    pub artist: Option<Vec<u8>>,
    pub album: Option<Vec<u8>>,
    pub album_artist: Option<Vec<u8>>,
    pub genre: Option<Vec<u8>>,
    pub track_number: Option<i32>,
    pub disc_number: Option<i32>,
    pub year: Option<i32>,
    pub duration_secs: i32,
    pub bitrate: Option<i32>,
    pub sample_rate: Option<i32>,
    pub channels: Option<i16>,
    pub format: Option<Vec<u8>>,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}
impl AudioFileMetadata {
    pub fn with_all_fields(
        file_id: u128,
        title: Option<Vec<u8>>,
        artist: Option<Vec<u8>>,
        album: Option<Vec<u8>>,
        album_artist: Option<Vec<u8>>,
        genre: Option<Vec<u8>>,
        track_number: Option<i32>,
        disc_number: Option<i32>,
        year: Option<i32>,
        duration_secs: i32,
        bitrate: Option<i32>,
        sample_rate: Option<i32>,
        channels: Option<i16>,
        format: Option<Vec<u8>>,
        created_at: Timestamp,
        updated_at: Timestamp,
    ) -> Self {
        Self {
            file_id,
            title,
            artist,
            album,
            album_artist,
            genre,
            track_number,
            disc_number,
            year,
            duration_secs,
            bitrate,
            sample_rate,
            channels,
            format,
            created_at,
            updated_at,
        }
    }
    pub fn file_id(&self) -> u128 { self.file_id }
    pub fn title(&self) -> &Option<Vec<u8>> { &self.title }
    pub fn artist(&self) -> &Option<Vec<u8>> { &self.artist }
    pub fn album(&self) -> &Option<Vec<u8>> { &self.album }
    pub fn album_artist(&self) -> &Option<Vec<u8>> { &self.album_artist }
    pub fn genre(&self) -> &Option<Vec<u8>> { &self.genre }
    pub fn track_number(&self) -> &Option<i32> { &self.track_number }
    pub fn disc_number(&self) -> &Option<i32> { &self.disc_number }
    pub fn year(&self) -> &Option<i32> { &self.year }
    pub fn duration_secs(&self) -> i32 { self.duration_secs }
    pub fn bitrate(&self) -> &Option<i32> { &self.bitrate }
    pub fn sample_rate(&self) -> &Option<i32> { &self.sample_rate }
    pub fn channels(&self) -> &Option<i16> { &self.channels }
    pub fn format(&self) -> &Option<Vec<u8>> { &self.format }
    pub fn created_at(&self) -> Timestamp { self.created_at }
    pub fn updated_at(&self) -> Timestamp { self.updated_at }
}
pub struct DeviceCode {
    pub id: u128,
    pub device_code: Vec<u8>,
    pub user_code: Vec<u8>,
    pub client_name: Vec<u8>,
    pub scopes: Vec<u8>,
    pub status: DeviceCodeStatus,
    pub user_id: Option<u128>,
    pub access_token: Option<Vec<u8>>,
    pub refresh_token: Option<Vec<u8>>,
    pub verification_uri: Vec<u8>,
    pub verification_uri_complete: Option<Vec<u8>>,
    pub expires_at: Timestamp,
    pub poll_interval_secs: i32,
    pub last_poll_at: Option<Timestamp>,
    pub created_at: Timestamp,
    pub authorized_at: Option<Timestamp>,
}
impl DeviceCode {
    pub fn from_raw(
        id: u128,
        device_code: Vec<u8>,
        user_code: Vec<u8>,
        client_name: Vec<u8>,
        scopes: Vec<u8>,
        status: DeviceCodeStatus,
        user_id: Option<u128>,
        access_token: Option<Vec<u8>>,
        refresh_token: Option<Vec<u8>>,
        verification_uri: Vec<u8>,
        verification_uri_complete: Option<Vec<u8>>,
        expires_at: Timestamp,
        poll_interval_secs: i32,
        last_poll_at: Option<Timestamp>,
        created_at: Timestamp,
        authorized_at: Option<Timestamp>,
    ) -> Self {
        Self {
            id,
            device_code,
            user_code,
            client_name,
            scopes,
            status,
            user_id,
            access_token,
            refresh_token,
            verification_uri,
            verification_uri_complete,
            expires_at,
            poll_interval_secs,
            last_poll_at,
            created_at,
            authorized_at,
        }
    }
    pub fn id(&self) -> u128 { self.id }
    pub fn device_code(&self) -> &Vec<u8> { &self.device_code }
    pub fn user_code(&self) -> &Vec<u8> { &self.user_code }
    pub fn client_name(&self) -> &Vec<u8> { &self.client_name }
    pub fn scopes(&self) -> &Vec<u8> { &self.scopes }
    pub fn status(&self) -> DeviceCodeStatus { self.status }
    pub fn user_id(&self) -> &Option<u128> { &self.user_id }
    pub fn access_token(&self) -> &Option<Vec<u8>> { &self.access_token }
    pub fn refresh_token(&self) -> &Option<Vec<u8>> { &self.refresh_token }
    pub fn verification_uri(&self) -> &Vec<u8> { &self.verification_uri }
    pub fn verification_uri_complete(&self) -> &Option<Vec<u8>> { &self.verification_uri_complete }
    pub fn expires_at(&self) -> Timestamp { self.expires_at }
    pub fn poll_interval_secs(&self) -> i32 { self.poll_interval_secs }
    pub fn last_poll_at(&self) -> &Option<Timestamp> { &self.last_poll_at }
    pub fn created_at(&self) -> Timestamp { self.created_at }
    pub fn authorized_at(&self) -> &Option<Timestamp> { &self.authorized_at }
}
pub struct TrashedItem {
    pub id: u128,
    pub original_id: u128,
    pub user_id: u128,
    pub item_type: TrashedItemType,
    pub name: Vec<u8>,
    pub original_path: Vec<u8>,
    pub trashed_at: Timestamp,
    pub deletion_date: Timestamp,
}
impl TrashedItem {
    pub fn from_raw(
        id: u128,
        original_id: u128,
        user_id: u128,
        item_type: TrashedItemType,
        name: Vec<u8>,
        original_path: Vec<u8>,
        trashed_at: Timestamp,
        deletion_date: Timestamp,
    ) -> Self {
        Self {
            id,
            original_id,
            user_id,
            item_type,
            name,
            original_path,
            trashed_at,
            deletion_date,
        }
    }
    pub fn id(&self) -> u128 { self.id }
    pub fn original_id(&self) -> u128 { self.original_id }
    pub fn user_id(&self) -> u128 { self.user_id }
    pub fn item_type(&self) -> &TrashedItemType { &self.item_type }
    pub fn name(&self) -> &Vec<u8> { &self.name }
    pub fn original_path(&self) -> &Vec<u8> { &self.original_path }
    pub fn trashed_at(&self) -> Timestamp { self.trashed_at }
    pub fn deletion_date(&self) -> Timestamp { self.deletion_date }
}
