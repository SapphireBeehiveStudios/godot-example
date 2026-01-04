extends Node
## Tests for MessageLog (Issue #36)

const MessageLog = preload("res://scripts/message_log.gd")

var tests_passed := 0
var tests_failed := 0

func run_all() -> Dictionary:
	print("\n=== MessageLog Tests ===")
	test_message_log_initialization()
	test_add_message()
	test_message_limit()
	test_recent_messages()
	test_to_bbcode()
	test_to_plain_text()
	test_serialization()
	test_turn_tracking()
	test_clear()
	return {"passed": tests_passed, "failed": tests_failed}

func assert_eq(actual, expected, test_name: String) -> void:
	if actual == expected:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: expected %s, got %s" % [test_name, expected, actual])

func assert_true(condition: bool, test_name: String) -> void:
	assert_eq(condition, true, test_name)

func assert_false(condition: bool, test_name: String) -> void:
	assert_eq(condition, false, test_name)

func assert_contains(haystack: String, needle: String, test_name: String) -> void:
	if needle in haystack:
		tests_passed += 1
		print("  ✓ %s" % test_name)
	else:
		tests_failed += 1
		print("  ✗ %s: '%s' not found in '%s'" % [test_name, needle, haystack])

# Test initialization
func test_message_log_initialization() -> void:
	var log = MessageLog.new()
	assert_eq(log.get_message_count(), 0, "New log starts empty")
	assert_eq(log.current_turn, 0, "New log starts at turn 0")

# Test adding messages
func test_add_message() -> void:
	var log = MessageLog.new()
	log.add_message("Test message", "info")
	assert_eq(log.get_message_count(), 1, "Message count increments")

	var messages = log.get_all_messages()
	assert_eq(messages[0].text, "Test message", "Message text stored")
	assert_eq(messages[0].type, "info", "Message type stored")
	assert_eq(messages[0].turn, 0, "Message turn defaults to current_turn")

# Test message limit
func test_message_limit() -> void:
	var log = MessageLog.new()

	# Add more than MAX_MESSAGES
	for i in range(150):
		log.add_message("Message %d" % i, "info")

	assert_eq(log.get_message_count(), 100, "Log limits to MAX_MESSAGES")

	# Check that oldest messages were removed
	var messages = log.get_all_messages()
	assert_eq(messages[0].text, "Message 50", "Oldest messages removed first")

# Test getting recent messages
func test_recent_messages() -> void:
	var log = MessageLog.new()

	for i in range(20):
		log.add_message("Message %d" % i, "info")

	var recent = log.get_recent_messages(5)
	assert_eq(recent.size(), 5, "Recent messages limited to count")
	assert_eq(recent[4].text, "Message 19", "Most recent message is last")
	assert_eq(recent[0].text, "Message 15", "Oldest recent message is first")

# Test BBCode formatting
func test_to_bbcode() -> void:
	var log = MessageLog.new()
	log.set_turn(1)
	log.add_message("Picked up keycard", "pickup")
	log.set_turn(2)
	log.add_message("Guard spotted you!", "guard")

	var bbcode = log.to_bbcode(10)
	assert_contains(bbcode, "[T1]", "BBCode contains turn number")
	assert_contains(bbcode, "Picked up keycard", "BBCode contains message text")
	assert_contains(bbcode, "[color=yellow]", "BBCode contains color for pickup")
	assert_contains(bbcode, "[color=red]", "BBCode contains color for guard")

# Test plain text formatting
func test_to_plain_text() -> void:
	var log = MessageLog.new()
	log.set_turn(1)
	log.add_message("Test message", "info")

	var plain = log.to_plain_text(10)
	assert_contains(plain, "[T1] Test message", "Plain text formatted correctly")

# Test serialization
func test_serialization() -> void:
	var log = MessageLog.new()
	log.set_turn(5)
	log.add_message("Message 1", "info")
	log.add_message("Message 2", "pickup")

	var dict = log.to_dict()
	assert_eq(dict.current_turn, 5, "Serialized turn number")
	assert_eq(dict.messages.size(), 2, "Serialized message count")

	var log2 = MessageLog.new()
	log2.from_dict(dict)
	assert_eq(log2.get_message_count(), 2, "Deserialized message count")
	assert_eq(log2.current_turn, 5, "Deserialized turn number")

	var messages = log2.get_all_messages()
	assert_eq(messages[0].text, "Message 1", "Deserialized message text")
	assert_eq(messages[1].type, "pickup", "Deserialized message type")

# Test turn tracking
func test_turn_tracking() -> void:
	var log = MessageLog.new()
	log.set_turn(10)
	log.add_message("Turn 10 message", "info")

	var messages = log.get_all_messages()
	assert_eq(messages[0].turn, 10, "Message stamped with current turn")

	log.set_turn(11)
	log.add_message("Turn 11 message", "info")
	messages = log.get_all_messages()
	assert_eq(messages[1].turn, 11, "Turn updates correctly")

# Test clear
func test_clear() -> void:
	var log = MessageLog.new()
	log.set_turn(5)
	log.add_message("Test", "info")

	log.clear()
	assert_eq(log.get_message_count(), 0, "Clear removes all messages")
	assert_eq(log.current_turn, 0, "Clear resets turn")
