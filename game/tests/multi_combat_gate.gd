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
 await preload("res://tests/test_multi_combat.gd").new().run(self)
 await preload("res://tests/test_multi_scene.gd").new().run(self)
 await preload("res://tests/test_multi_rules.gd").new().run(self)
 print("RESULT: %d multi-combat checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
