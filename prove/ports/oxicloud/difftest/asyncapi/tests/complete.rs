#[path="../../../kernel/src/asyncapi.rs"]
mod kernel;
#[test]
fn complete_closed_schema_values() {
    let values: std::collections::BTreeMap<_, _> = asyncapi_reference::all_values().into_iter().collect();
    assert_eq!(kernel::channels().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["channels"]).unwrap(), "channels");
    assert_eq!(kernel::operations().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["operations"]).unwrap(), "operations");
    assert_eq!(kernel::components().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["components"]).unwrap(), "components");
    assert_eq!(kernel::topic_params_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["topic_params_schema"]).unwrap(), "topic_params_schema");
    assert_eq!(kernel::rpc_success_response_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_success_response_schema"]).unwrap(), "rpc_success_response_schema");
    assert_eq!(kernel::rpc_pong_response_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_pong_response_schema"]).unwrap(), "rpc_pong_response_schema");
    assert_eq!(kernel::rpc_pong_result_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_pong_result_schema"]).unwrap(), "rpc_pong_result_schema");
    assert_eq!(kernel::rpc_error_response_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_error_response_schema"]).unwrap(), "rpc_error_response_schema");
    assert_eq!(kernel::rpc_error_object_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_error_object_schema"]).unwrap(), "rpc_error_object_schema");
    assert_eq!(kernel::rpc_error_code_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_error_code_schema"]).unwrap(), "rpc_error_code_schema");
    assert_eq!(kernel::rpc_error_message_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["rpc_error_message_schema"]).unwrap(), "rpc_error_message_schema");
    assert_eq!(kernel::folder_event_notification_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["folder_event_notification_schema"]).unwrap(), "folder_event_notification_schema");
    assert_eq!(kernel::event_params_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["event_params_schema"]).unwrap(), "event_params_schema");
    assert_eq!(kernel::event_kind_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["event_kind_schema"]).unwrap(), "event_kind_schema");
    assert_eq!(kernel::event_data_union_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["event_data_union_schema"]).unwrap(), "event_data_union_schema");
    assert_eq!(kernel::file_created_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["file_created_schema"]).unwrap(), "file_created_schema");
    assert_eq!(kernel::file_renamed_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["file_renamed_schema"]).unwrap(), "file_renamed_schema");
    assert_eq!(kernel::file_moved_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["file_moved_schema"]).unwrap(), "file_moved_schema");
    assert_eq!(kernel::file_deleted_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["file_deleted_schema"]).unwrap(), "file_deleted_schema");
    assert_eq!(kernel::folder_created_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["folder_created_schema"]).unwrap(), "folder_created_schema");
    assert_eq!(kernel::folder_renamed_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["folder_renamed_schema"]).unwrap(), "folder_renamed_schema");
    assert_eq!(kernel::folder_moved_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["folder_moved_schema"]).unwrap(), "folder_moved_schema");
    assert_eq!(kernel::folder_deleted_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["folder_deleted_schema"]).unwrap(), "folder_deleted_schema");
    assert_eq!(kernel::notification_received_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["notification_received_schema"]).unwrap(), "notification_received_schema");
    assert_eq!(kernel::job_run_started_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["job_run_started_schema"]).unwrap(), "job_run_started_schema");
    assert_eq!(kernel::job_run_progress_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["job_run_progress_schema"]).unwrap(), "job_run_progress_schema");
    assert_eq!(kernel::job_run_ended_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["job_run_ended_schema"]).unwrap(), "job_run_ended_schema");
    assert_eq!(kernel::revoked_notification_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["revoked_notification_schema"]).unwrap(), "revoked_notification_schema");
    assert_eq!(kernel::revoked_params_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["revoked_params_schema"]).unwrap(), "revoked_params_schema");
    assert_eq!(kernel::revoked_reason_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["revoked_reason_schema"]).unwrap(), "revoked_reason_schema");
    assert_eq!(kernel::collab_flush_params_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["collab_flush_params_schema"]).unwrap(), "collab_flush_params_schema");
    assert_eq!(kernel::collab_flush_result_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["collab_flush_result_schema"]).unwrap(), "collab_flush_result_schema");
    assert_eq!(kernel::collab_binary_frame_schema().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["collab_binary_frame_schema"]).unwrap(), "collab_binary_frame_schema");
    assert_eq!(values.len(), 33);
}
