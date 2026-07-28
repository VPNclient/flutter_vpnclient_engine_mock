library vpnclient_engine;

// Cores / drivers / platform.
export 'src/cores/core_type.dart';
export 'src/drivers/driver_type.dart';
export 'src/capabilities/platform_target.dart';
export 'src/capabilities/engine_capabilities.dart';

// Connection engine.
export 'src/engine/connection_state.dart';
export 'src/engine/connection_stats.dart';
export 'src/engine/speed_test_result.dart';
export 'src/engine/split_tunneling_config.dart';
export 'src/engine/vpn_engine.dart';

// Protocol / server configuration.
export 'src/config/protocol_config.dart';
export 'src/config/transport_config.dart';
export 'src/config/tls_config.dart';

// Subscriptions & servers.
export 'src/subscriptions/server.dart';
export 'src/subscriptions/server_definition.dart';
export 'src/subscriptions/subscription.dart';
export 'src/subscriptions/subscription_manager.dart';
export 'src/subscriptions/subscription_parser.dart';
export 'src/subscriptions/subscription_parse_exception.dart';
export 'src/subscriptions/parsers/share_link_list_parser.dart';
export 'src/subscriptions/parsers/json_array_parser.dart';
export 'src/subscriptions/parsers/sing_box_config_parser.dart';
export 'src/subscriptions/storage/subscription_store.dart';
export 'src/subscriptions/storage/in_memory_subscription_store.dart';
export 'src/subscriptions/storage/shared_prefs_subscription_store.dart';

// Mock / QA-only surface.
export 'src/mock/mock_behavior_config.dart';
export 'src/mock/mock_engine_controller.dart';
