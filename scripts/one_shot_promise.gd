class_name OneShotPromise
extends RefCounted

signal completed(value)

var _value = null
var _emitted := false


func _run_wrapped(cb: Callable, args: Array) -> void:
	if cb.is_null() or not cb.is_valid():
		resolve(null)
		return
	resolve(cb.callv(args))


static func run(cb: Callable, ...args) -> Variant:
	var promise := OneShotPromise.new()
	promise._run_wrapped.call_deferred(cb, args)
	return await promise.completed


func resolve_callback(cb: Callable):
	resolve(cb.call())


func resolve(v) -> void:
	if _emitted:
		return
	_emitted = true
	_value = v
	completed.emit(v)
