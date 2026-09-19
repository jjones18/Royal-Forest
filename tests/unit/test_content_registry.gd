extends RefCounted

const Assertions = preload("res://tests/support/assertions.gd")
const SPELL: SpellDefinition = preload("res://game/data/spells/spectral_bolt.tres")

func test_content_id_requires_stable_lowercase_namespace_slug(assertions: Assertions, _fixture: RefCounted) -> bool:
	assertions.is_true(ContentId.is_valid(&"spell.spectral-bolt"))
	assertions.is_false(ContentId.is_valid(&"spell.SpectralBolt"))
	assertions.is_false(ContentId.is_valid(&"spell"))
	assertions.is_false(ContentId.is_valid(&"spell.bad.extra"))
	return true

func test_registry_rejects_duplicate_and_supports_typed_spell_lookup(assertions: Assertions, _fixture: RefCounted) -> bool:
	var registry := ContentRegistry.new()
	assertions.is_true(registry.register_spell(SPELL))
	assertions.is_false(registry.register_spell(SPELL))
	assertions.is_true(registry.last_error.begins_with("duplicate content id"))
	assertions.equal(registry.spell(&"spell.spectral-bolt"), SPELL)
	assertions.equal(registry.spell_count(), 1)
	assertions.equal(registry.spell(&"spell.missing"), null)
	return true

func test_registry_rejects_malformed_spell(assertions: Assertions, _fixture: RefCounted) -> bool:
	var registry := ContentRegistry.new()
	var malformed := SpellDefinition.new()
	malformed.id = &"item.not-a-spell"
	malformed.display_name = "Wrong"
	assertions.is_false(registry.register_spell(malformed))
	assertions.equal(registry.spell_count(), 0)
	return true
