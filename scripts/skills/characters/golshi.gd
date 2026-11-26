extends RefCounted


const ACTIVE := {
	"name": "Anchors Aweigh!",
	"condition": "menu_covered",
	"script": "res://scripts/skills/effects/anchors_aweigh.gd",
	"uses": 1,

	"reward_money": 9999999,
}


# ═══════════════════════════════════════════════════════════ BỊ ĐỘNG
const PASSIVE := {
	# ── Aura farming ──────────────────────────────────────────────────
	"force_perfect": true,

	# ── Everything but cooking ────────────────────────────────────────
	"cook_fail_chance": 0.2,
}


## ASIAN MODE (user chốt 27/10/2026, xem thiet_ke_endless_asian_v0.1.docx mục 3.7
const ASIAN := {
	"active": {"reward_money": 1000, "restore_lives": 3, "end_level": false},
	"passive": {
		"cook_fail_chance": 0.3,
		"start_lives": 1,
		"overflow_life_money": 250,
		"streak_counts_forced": true,
	},
}
