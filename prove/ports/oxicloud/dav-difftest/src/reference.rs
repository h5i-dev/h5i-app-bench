use chrono::{DateTime,Utc,NaiveDate}; use uuid::Uuid; type Result<T> = std::result::Result<T,()>;
#[derive(Clone,Debug)]
pub struct Email {
    pub email: String,
    pub r#type: String, // home, work, other
    pub is_primary: bool,
}
#[derive(Clone,Debug)]
pub struct Phone {
    pub number: String,
    pub r#type: String, // mobile, home, work, fax, other
    pub is_primary: bool,
}
#[derive(Clone,Debug)]
pub struct Address {
    pub street: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub postal_code: Option<String>,
    pub country: Option<String>,
    pub r#type: String, // home, work, other
    pub is_primary: bool,
}
#[derive(Clone,Copy,Debug)]
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
#[derive(Clone,Copy,Debug)]
pub enum TrashedItemType {
    File,
    Folder,
}
#[derive(Clone,Debug)]
pub struct AddressBook {
    id: Uuid,
    name: String,
    owner_id: String,
    description: Option<String>,
    color: Option<String>,
    is_public: bool,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
impl AddressBook {
    pub fn from_raw(
        id: Uuid,
        name: String,
        owner_id: String,
        description: Option<String>,
        color: Option<String>,
        is_public: bool,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
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
    pub fn id(&self) -> &Uuid {
        &self.id
    }
    pub fn name(&self) -> &str {
        &self.name
    }
    pub fn owner_id(&self) -> &str {
        &self.owner_id
    }
    pub fn description(&self) -> Option<&str> {
        self.description.as_deref()
    }
    pub fn color(&self) -> Option<&str> {
        self.color.as_deref()
    }
    pub fn is_public(&self) -> bool {
        self.is_public
    }
    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }
    pub fn updated_at(&self) -> &DateTime<Utc> {
        &self.updated_at
    }
}
#[derive(Clone,Debug)]
pub struct Contact {
    id: Uuid,
    address_book_id: Uuid,
    uid: String,
    full_name: Option<String>,
    first_name: Option<String>,
    last_name: Option<String>,
    nickname: Option<String>,
    email: Vec<Email>,
    phone: Vec<Phone>,
    address: Vec<Address>,
    organization: Option<String>,
    title: Option<String>,
    notes: Option<String>,
    photo_url: Option<String>,
    birthday: Option<NaiveDate>,
    anniversary: Option<NaiveDate>,
    vcard: String,
    etag: String,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
impl Contact {
    pub fn from_raw(
        id: Uuid,
        address_book_id: Uuid,
        uid: String,
        full_name: Option<String>,
        first_name: Option<String>,
        last_name: Option<String>,
        nickname: Option<String>,
        email: Vec<Email>,
        phone: Vec<Phone>,
        address: Vec<Address>,
        organization: Option<String>,
        title: Option<String>,
        notes: Option<String>,
        photo_url: Option<String>,
        birthday: Option<NaiveDate>,
        anniversary: Option<NaiveDate>,
        vcard: String,
        etag: String,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
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
    pub fn id(&self) -> &Uuid {
        &self.id
    }
    pub fn address_book_id(&self) -> &Uuid {
        &self.address_book_id
    }
    pub fn uid(&self) -> &str {
        &self.uid
    }
    pub fn full_name(&self) -> Option<&str> {
        self.full_name.as_deref()
    }
    pub fn first_name(&self) -> Option<&str> {
        self.first_name.as_deref()
    }
    pub fn last_name(&self) -> Option<&str> {
        self.last_name.as_deref()
    }
    pub fn nickname(&self) -> Option<&str> {
        self.nickname.as_deref()
    }
    pub fn email(&self) -> &[Email] {
        &self.email
    }
    pub fn phone(&self) -> &[Phone] {
        &self.phone
    }
    pub fn address(&self) -> &[Address] {
        &self.address
    }
    pub fn organization(&self) -> Option<&str> {
        self.organization.as_deref()
    }
    pub fn title(&self) -> Option<&str> {
        self.title.as_deref()
    }
    pub fn notes(&self) -> Option<&str> {
        self.notes.as_deref()
    }
    pub fn photo_url(&self) -> Option<&str> {
        self.photo_url.as_deref()
    }
    pub fn birthday(&self) -> Option<&NaiveDate> {
        self.birthday.as_ref()
    }
    pub fn anniversary(&self) -> Option<&NaiveDate> {
        self.anniversary.as_ref()
    }
    pub fn vcard(&self) -> &str {
        &self.vcard
    }
    pub fn etag(&self) -> &str {
        &self.etag
    }
    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }
    pub fn updated_at(&self) -> &DateTime<Utc> {
        &self.updated_at
    }
    pub fn into_email(self) -> Vec<Email> {
        self.email
    }
}
#[derive(Clone,Debug)]
pub struct CalendarTodo {
    /// Unique identifier for the todo
    id: Uuid,

    /// ID of the calendar this todo belongs to
    calendar_id: Uuid,

    /// Short summary/title of the todo. OPTIONAL on a VTODO (RFC 5545
    /// §3.6.2 mandates only UID + DTSTAMP), unlike VEVENT where
    /// OxiCloud requires SUMMARY.
    summary: Option<String>,

    /// Detailed description of the todo (optional)
    description: Option<String>,

    /// Location of the todo (optional)
    location: Option<String>,

    /// RFC 5545 §3.8.1.11 STATUS — NEEDS-ACTION / IN-PROCESS /
    /// COMPLETED / CANCELLED (free-form so client extensions survive)
    status: Option<String>,

    /// RFC 5545 §3.8.1.8 PERCENT-COMPLETE — 0..100
    percent_complete: Option<i16>,

    /// RFC 5545 §3.8.1.9 PRIORITY — 0..9 (0 = undefined)
    priority: Option<i16>,

    /// DTSTART of the todo (optional) — UTC instant; the original
    /// (possibly TZID-anchored) wall-clock form lives in `ical_data`
    start_time: Option<DateTime<Utc>>,

    /// DUE of the todo (optional)
    due_time: Option<DateTime<Utc>>,

    /// COMPLETED of the todo (optional)
    completed_at: Option<DateTime<Utc>>,

    /// Whether DTSTART carried `VALUE=DATE` (date-only task)
    all_day: bool,

    /// Recurrence rule in iCalendar RRULE format (optional — VTODOs
    /// can recur, RFC 5545 §3.6.2)
    rrule: Option<String>,

    /// RECURRENCE-ID (RFC 5545 §3.8.4.4) — same master/exception
    /// model as `CalendarEvent`: NULL on the master, non-NULL on
    /// per-instance overrides of a recurring task.
    recurrence_id: Option<DateTime<Utc>>,

    /// Unique identifier in iCalendar format (used for CalDAV sync)
    ical_uid: String,

    /// Complete iCalendar data (VCALENDAR with one VTODO + embedded
    /// VTIMEZONEs) — authoritative, served verbatim
    ical_data: String,

    /// Time when the todo was created
    created_at: DateTime<Utc>,

    /// Time when the todo was last modified
    updated_at: DateTime<Utc>,
}
impl CalendarTodo {
    pub fn with_id(
        id: Uuid,
        calendar_id: Uuid,
        summary: Option<String>,
        description: Option<String>,
        location: Option<String>,
        status: Option<String>,
        percent_complete: Option<i16>,
        priority: Option<i16>,
        start_time: Option<DateTime<Utc>>,
        due_time: Option<DateTime<Utc>>,
        completed_at: Option<DateTime<Utc>>,
        all_day: bool,
        rrule: Option<String>,
        ical_uid: String,
        ical_data: String,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
    ) -> Result<Self> {
        Ok(Self {
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
        })
    }
    pub fn id(&self) -> &Uuid {
        &self.id
    }
    pub fn calendar_id(&self) -> &Uuid {
        &self.calendar_id
    }
    pub fn summary(&self) -> Option<&str> {
        self.summary.as_deref()
    }
    pub fn description(&self) -> Option<&str> {
        self.description.as_deref()
    }
    pub fn location(&self) -> Option<&str> {
        self.location.as_deref()
    }
    pub fn status(&self) -> Option<&str> {
        self.status.as_deref()
    }
    pub fn percent_complete(&self) -> Option<i16> {
        self.percent_complete
    }
    pub fn priority(&self) -> Option<i16> {
        self.priority
    }
    pub fn start_time(&self) -> Option<&DateTime<Utc>> {
        self.start_time.as_ref()
    }
    pub fn due_time(&self) -> Option<&DateTime<Utc>> {
        self.due_time.as_ref()
    }
    pub fn completed_at(&self) -> Option<&DateTime<Utc>> {
        self.completed_at.as_ref()
    }
    pub fn all_day(&self) -> bool {
        self.all_day
    }
    pub fn rrule(&self) -> Option<&str> {
        self.rrule.as_deref()
    }
    pub fn recurrence_id(&self) -> Option<&DateTime<Utc>> {
        self.recurrence_id.as_ref()
    }
    pub fn ical_uid(&self) -> &str {
        &self.ical_uid
    }
    pub fn ical_data(&self) -> &str {
        &self.ical_data
    }
    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }
    pub fn updated_at(&self) -> &DateTime<Utc> {
        &self.updated_at
    }
}
#[derive(Clone,Debug)]
pub struct AudioFileMetadata {
    file_id: Uuid,
    title: Option<String>,
    artist: Option<String>,
    album: Option<String>,
    album_artist: Option<String>,
    genre: Option<String>,
    track_number: Option<i32>,
    disc_number: Option<i32>,
    year: Option<i32>,
    duration_secs: i32,
    bitrate: Option<i32>,
    sample_rate: Option<i32>,
    channels: Option<i16>,
    format: Option<String>,
    created_at: DateTime<Utc>,
    updated_at: DateTime<Utc>,
}
impl AudioFileMetadata {
    pub fn with_all_fields(
        file_id: Uuid,
        title: Option<String>,
        artist: Option<String>,
        album: Option<String>,
        album_artist: Option<String>,
        genre: Option<String>,
        track_number: Option<i32>,
        disc_number: Option<i32>,
        year: Option<i32>,
        duration_secs: i32,
        bitrate: Option<i32>,
        sample_rate: Option<i32>,
        channels: Option<i16>,
        format: Option<String>,
        created_at: DateTime<Utc>,
        updated_at: DateTime<Utc>,
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
    pub fn file_id(&self) -> &Uuid {
        &self.file_id
    }
    pub fn title(&self) -> Option<&str> {
        self.title.as_deref()
    }
    pub fn artist(&self) -> Option<&str> {
        self.artist.as_deref()
    }
    pub fn album(&self) -> Option<&str> {
        self.album.as_deref()
    }
    pub fn album_artist(&self) -> Option<&str> {
        self.album_artist.as_deref()
    }
    pub fn genre(&self) -> Option<&str> {
        self.genre.as_deref()
    }
    pub fn track_number(&self) -> Option<i32> {
        self.track_number
    }
    pub fn disc_number(&self) -> Option<i32> {
        self.disc_number
    }
    pub fn year(&self) -> Option<i32> {
        self.year
    }
    pub fn duration_secs(&self) -> i32 {
        self.duration_secs
    }
    pub fn bitrate(&self) -> Option<i32> {
        self.bitrate
    }
    pub fn sample_rate(&self) -> Option<i32> {
        self.sample_rate
    }
    pub fn channels(&self) -> Option<i16> {
        self.channels
    }
    pub fn format(&self) -> Option<&str> {
        self.format.as_deref()
    }
    pub fn created_at(&self) -> &DateTime<Utc> {
        &self.created_at
    }
    pub fn updated_at(&self) -> &DateTime<Utc> {
        &self.updated_at
    }
}
#[derive(Clone,Debug)]
pub struct DeviceCode {
    id: Uuid,
    device_code: String,
    user_code: String,
    client_name: String,
    scopes: String,
    status: DeviceCodeStatus,
    user_id: Option<Uuid>,
    access_token: Option<String>,
    refresh_token: Option<String>,
    verification_uri: String,
    verification_uri_complete: Option<String>,
    expires_at: DateTime<Utc>,
    poll_interval_secs: i32,
    last_poll_at: Option<DateTime<Utc>>,
    created_at: DateTime<Utc>,
    authorized_at: Option<DateTime<Utc>>,
}
impl DeviceCode {
    pub fn from_raw(
        id: Uuid,
        device_code: String,
        user_code: String,
        client_name: String,
        scopes: String,
        status: DeviceCodeStatus,
        user_id: Option<Uuid>,
        access_token: Option<String>,
        refresh_token: Option<String>,
        verification_uri: String,
        verification_uri_complete: Option<String>,
        expires_at: DateTime<Utc>,
        poll_interval_secs: i32,
        last_poll_at: Option<DateTime<Utc>>,
        created_at: DateTime<Utc>,
        authorized_at: Option<DateTime<Utc>>,
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
    pub fn id(&self) -> Uuid {
        self.id
    }
    pub fn device_code(&self) -> &str {
        &self.device_code
    }
    pub fn user_code(&self) -> &str {
        &self.user_code
    }
    pub fn client_name(&self) -> &str {
        &self.client_name
    }
    pub fn scopes(&self) -> &str {
        &self.scopes
    }
    pub fn status(&self) -> DeviceCodeStatus {
        self.status
    }
    pub fn user_id(&self) -> Option<Uuid> {
        self.user_id
    }
    pub fn access_token(&self) -> Option<&str> {
        self.access_token.as_deref()
    }
    pub fn refresh_token(&self) -> Option<&str> {
        self.refresh_token.as_deref()
    }
    pub fn verification_uri(&self) -> &str {
        &self.verification_uri
    }
    pub fn verification_uri_complete(&self) -> Option<&str> {
        self.verification_uri_complete.as_deref()
    }
    pub fn expires_at(&self) -> DateTime<Utc> {
        self.expires_at
    }
    pub fn poll_interval_secs(&self) -> i32 {
        self.poll_interval_secs
    }
    pub fn last_poll_at(&self) -> Option<DateTime<Utc>> {
        self.last_poll_at
    }
    pub fn created_at(&self) -> DateTime<Utc> {
        self.created_at
    }
    pub fn authorized_at(&self) -> Option<DateTime<Utc>> {
        self.authorized_at
    }
}
#[derive(Clone,Debug)]
pub struct TrashedItem {
    id: Uuid,
    original_id: Uuid,
    user_id: Uuid,
    item_type: TrashedItemType,
    name: String,
    original_path: String,
    trashed_at: DateTime<Utc>,
    deletion_date: DateTime<Utc>,
}
impl TrashedItem {
    pub fn from_raw(
        id: Uuid,
        original_id: Uuid,
        user_id: Uuid,
        item_type: TrashedItemType,
        name: String,
        original_path: String,
        trashed_at: DateTime<Utc>,
        deletion_date: DateTime<Utc>,
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
    pub fn id(&self) -> Uuid {
        self.id
    }
    pub fn original_id(&self) -> Uuid {
        self.original_id
    }
    pub fn user_id(&self) -> Uuid {
        self.user_id
    }
    pub fn item_type(&self) -> &TrashedItemType {
        &self.item_type
    }
    pub fn name(&self) -> &str {
        &self.name
    }
    pub fn original_path(&self) -> &str {
        &self.original_path
    }
    pub fn trashed_at(&self) -> DateTime<Utc> {
        self.trashed_at
    }
    pub fn deletion_date(&self) -> DateTime<Utc> {
        self.deletion_date
    }
}
