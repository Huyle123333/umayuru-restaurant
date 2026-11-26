extends Node
## Lớp cha cho mọi file kiểm thử. Mỗi hàm bắt đầu bằng "test_" là một ca.
## Viết theo cùng kiểu GUT (assert_eq, assert_true…) để sau này chuyển sang
## GUT chỉ cần đổi dòng `extends`.

var _failures: Array[String] = []
var _asserts := 0


## Gọi trước mỗi ca. Lớp con ghi đè khi cần dựng dữ liệu.
func before_each() -> void:
	pass


## Gọi sau mỗi ca. Lớp con ghi đè để trả trạng thái về như cũ.
func after_each() -> void:
	pass


func assert_eq(got: Variant, expected: Variant, note: String = "") -> void:
	_asserts += 1
	if typeof(got) != typeof(expected) or got != expected:
		_failures.append("expected %s, got %s %s" % [str(expected), str(got), note])


func assert_ne(got: Variant, not_expected: Variant, note: String = "") -> void:
	_asserts += 1
	if got == not_expected:
		_failures.append("must not equal %s %s" % [str(not_expected), note])


func assert_true(value: bool, note: String = "") -> void:
	_asserts += 1
	if not value:
		_failures.append("expected true %s" % note)


func assert_false(value: bool, note: String = "") -> void:
	_asserts += 1
	if value:
		_failures.append("expected false %s" % note)


func assert_almost_eq(got: float, expected: float, eps: float = 0.001, note: String = "") -> void:
	_asserts += 1
	if absf(got - expected) > eps:
		_failures.append("expected ≈%s, got %s %s" % [str(expected), str(got), note])


## Bộ chạy gọi hàm này: chạy một ca, trả về danh sách lỗi của ca đó.
func run_case(method: String) -> Array[String]:
	_failures.clear()
	before_each()
	call(method)
	after_each()
	return _failures.duplicate()
