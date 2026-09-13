extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAIL: " + label)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 await preload("res://tests/test_swords.gd").new().run(self)
 print("RESULT: %d sword checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
